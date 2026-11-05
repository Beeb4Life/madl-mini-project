import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/vet_clinic.dart';
import '../../database/database_helper.dart';
import '../../theme/app_colors.dart';
import '../../widgets/nothing_card.dart';
import '../../widgets/nothing_button.dart';
import '../../widgets/nothing_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirmation_dialog.dart';

class VetsScreen extends StatefulWidget {
  const VetsScreen({super.key});

  @override
  State<VetsScreen> createState() => _VetsScreenState();
}

class _VetsScreenState extends State<VetsScreen> {
  List<VetClinic> _clinics = [];
  bool _isLoading = true;
  String _selectedFilter = 'ALL'; // 'ALL', 'EMERGENCY', 'CENTRAL', 'WESTERN'
  final TextEditingController _searchController = TextEditingController();
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _loadClinics();
    _fetchLocationSilently();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocationSilently() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (mounted) {
        setState(() {
          _userPosition = pos;
        });
        _loadClinics();
      }
    } catch (_) {}
  }

  Future<void> _loadClinics() async {
    setState(() => _isLoading = true);
    final query = _searchController.text.trim();
    final isEmergencyOnly = _selectedFilter == 'EMERGENCY';

    final list = await DatabaseHelper.instance.getAllVets(
      query: query.isNotEmpty ? query : null,
      emergencyOnly: isEmergencyOnly,
    );

    // Apply area filter if selected
    List<VetClinic> filtered = list;
    if (_selectedFilter == 'CENTRAL') {
      filtered = list.where((c) => c.city.contains('Parel') || c.city.contains('Worli')).toList();
    } else if (_selectedFilter == 'WESTERN') {
      filtered = list.where((c) => c.city.contains('Bandra') || c.city.contains('Khar')).toList();
    }

    // Dynamic distance calculation if GPS is available
    if (_userPosition != null) {
      for (int i = 0; i < filtered.length; i++) {
        final c = filtered[i];
        if (c.latitude != null && c.longitude != null) {
          final meters = Geolocator.distanceBetween(
            _userPosition!.latitude,
            _userPosition!.longitude,
            c.latitude!,
            c.longitude!,
          );
          filtered[i] = c.copyWith(
            distanceKm: double.parse((meters / 1000).toStringAsFixed(1)),
          );
        }
      }
      filtered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }

    setState(() {
      _clinics = filtered;
      _isLoading = false;
    });
  }

  Future<void> _togglePrimary(VetClinic clinic) async {
    final newStatus = !clinic.isPrimary;
    await DatabaseHelper.instance.setPrimaryVet(clinic.id!, newStatus);
    _loadClinics();
    if (mounted) {
      AppSnackBar.show(
        context,
        newStatus
            ? '${clinic.name} set as primary clinic.'
            : 'Removed primary clinic designation.',
      );
    }
  }

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showCallDialog(phone);
      }
    } catch (_) {
      _showCallDialog(phone);
    }
  }

  void _showCallDialog(String phone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.brd(context)),
        ),
        title: const Text(
          'CALL VETERINARY HOSPITAL',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hospital contact number:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfElevated(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.brd(context)),
              ),
              child: SelectableText(
                phone,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          NothingButton.secondary(
            label: 'CLOSE',
            height: 38,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoogleMaps(VetClinic clinic) async {
    // Universal Google Maps search & navigation intent with real Mumbai place query
    final query = (clinic.latitude != null && clinic.longitude != null)
        ? '${clinic.latitude},${clinic.longitude}'
        : Uri.encodeComponent('${clinic.name}, ${clinic.address}, Mumbai');
    final mapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    try {
      if (await canLaunchUrl(mapsUrl)) {
        await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          AppSnackBar.show(context, 'Location: ${clinic.address}, ${clinic.city}');
        }
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(context, 'Location: ${clinic.address}, ${clinic.city}');
      }
    }
  }

  Future<void> _deleteClinic(VetClinic clinic) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'REMOVE CLINIC',
      message: 'Remove "${clinic.name}" from your local directory?',
      confirmLabel: 'REMOVE',
      isDestructive: true,
    );

    if (confirmed) {
      await DatabaseHelper.instance.deleteVet(clinic.id!);
      _loadClinics();
      if (mounted) {
        AppSnackBar.show(context, 'Clinic removed.');
      }
    }
  }

  Future<void> _openAddClinicDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController(text: 'Mumbai');
    final servicesCtrl = TextEditingController(text: 'General Practice, Vaccinations');
    bool isEmergency = false;

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '// ADD LOCAL VET CLINIC',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'CLINIC / HOSPITAL NAME *',
                        hintText: 'e.g. Bandra Pet Care Hospital',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'PHONE NUMBER *',
                        hintText: 'e.g. +91 22 2600 0000',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'STREET ADDRESS *',
                        hintText: 'e.g. Hill Road, Bandra West',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'CITY / DISTRICT',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: servicesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'SERVICES / SPECIALTIES',
                        hintText: 'e.g. Emergency, Dental, Surgery',
                      ),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        '24/7 EMERGENCY HOSPITAL',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: const Text(
                        'Open all night with critical trauma surgical staff',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      value: isEmergency,
                      activeTrackColor: AppColors.accentRed,
                      activeThumbColor: Colors.white,
                      onChanged: (val) {
                        setModalState(() => isEmergency = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    NothingButton(
                      label: 'SAVE TO DIRECTORY',
                      isExpanded: true,
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            phoneCtrl.text.trim().isEmpty ||
                            addressCtrl.text.trim().isEmpty) {
                          AppSnackBar.show(
                            context,
                            'Please fill in clinic name, phone, and address.',
                            isError: true,
                          );
                          return;
                        }

                        final clinic = VetClinic(
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          address: addressCtrl.text.trim(),
                          city: cityCtrl.text.trim(),
                          distanceKm: 3.5,
                          rating: 5.0,
                          isEmergency: isEmergency,
                          services: servicesCtrl.text.trim(),
                          isPrimary: false,
                          latitude: 19.0760,
                          longitude: 72.8777,
                          createdAt: DateTime.now().toIso8601String(),
                        );

                        await DatabaseHelper.instance.insertVet(clinic);
                        if (context.mounted) {
                          Navigator.pop(context, true);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (created == true) {
      _loadClinics();
      if (mounted) {
        AppSnackBar.show(context, 'New clinic added to directory.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_hospital_outlined, size: 20, color: AppColors.accentRed),
            SizedBox(width: 8),
            Text(
              'VETS & EMERGENCY HOSPITALS',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, size: 20),
            tooltip: 'Calibrate Live GPS Proximity',
            onPressed: () async {
              await _fetchLocationSilently();
              if (!context.mounted) return;
              AppSnackBar.show(context, 'GPS distances updated for Mumbai region.');
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Add Custom Vet',
            onPressed: _openAddClinicDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _loadClinics(),
                    decoration: InputDecoration(
                      hintText: 'Search Mumbai clinics, areas (Parel, Bandra, Worli)...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _loadClinics();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('ALL', 'ALL CLINICS'),
                        const SizedBox(width: 8),
                        _buildFilterChip('EMERGENCY', '24/7 EMERGENCY', isRed: true),
                        const SizedBox(width: 8),
                        _buildFilterChip('CENTRAL', 'PAREL / WORLI'),
                        const SizedBox(width: 8),
                        _buildFilterChip('WESTERN', 'BANDRA / KHAR'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Live Google Maps Navigation Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfElevated(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.brd(context)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.directions, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap "NAVIGATE" on any clinic to launch live turn-by-turn driving directions in Google Maps.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // Clinic List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _clinics.isEmpty
                      ? EmptyState(
                          icon: Icons.local_hospital_outlined,
                          title: 'NO CLINICS MATCHED',
                          message: 'Try clearing search filters or add a custom veterinary clinic.',
                          actionLabel: 'ADD CLINIC',
                          onAction: _openAddClinicDialog,
                        )
                      : RefreshIndicator(
                          color: Colors.white,
                          backgroundColor: AppColors.surf(context),
                          onRefresh: _loadClinics,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _clinics.length,
                            itemBuilder: (context, index) {
                              final clinic = _clinics[index];
                              return _buildClinicCard(clinic);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, {bool isRed = false}) {
    final isSelected = _selectedFilter == key;
    return FilterChip(
      avatar: isRed
          ? Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.accentRed,
                shape: BoxShape.circle,
              ),
            )
          : null,
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
      selected: isSelected,
      selectedColor: isRed ? AppColors.accentRedDim : AppColors.surfElevated(context),
      backgroundColor: AppColors.surf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? (isRed ? AppColors.danger : Colors.white) : AppColors.brd(context),
        ),
      ),
      onSelected: (_) {
        setState(() => _selectedFilter = key);
        _loadClinics();
      },
    );
  }

  Widget _buildClinicCard(VetClinic clinic) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NothingCard(
        hasRedDot: clinic.isEmergency,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top badges & distance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (clinic.isEmergency)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '24/7 EMERGENCY',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    if (clinic.isPrimary)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PRIMARY VET',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text(
                      '${clinic.rating}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '// ${clinic.distanceKm} KM',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Clinic Name
            Text(
              clinic.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 4),

            // Real Mumbai Address
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${clinic.address}, ${clinic.city}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Services chips
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: clinic.services
                  .split(',')
                  .map((s) => NothingBadge(
                        label: s.trim(),
                        fontSize: 10,
                      ))
                  .toList(),
            ),

            if (clinic.notes != null && clinic.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                clinic.notes!,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMuted,
                  height: 1.3,
                ),
              ),
            ],

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Actions Row with Google Maps Navigation & Calling
            Row(
              children: [
                Expanded(
                  child: NothingButton(
                    label: 'NAVIGATE (MAPS)',
                    icon: Icons.directions,
                    height: 38,
                    onPressed: () => _openGoogleMaps(clinic),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NothingButton.secondary(
                    label: 'CALL',
                    icon: Icons.phone_outlined,
                    height: 38,
                    onPressed: () => _makeCall(clinic.phone),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    clinic.isPrimary ? Icons.bookmark : Icons.bookmark_border,
                    color: clinic.isPrimary ? Colors.white : AppColors.textMuted,
                    size: 20,
                  ),
                  tooltip: clinic.isPrimary ? 'Unmark Primary' : 'Set as Primary Vet',
                  onPressed: () => _togglePrimary(clinic),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
                  tooltip: 'Delete Clinic',
                  onPressed: () => _deleteClinic(clinic),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
