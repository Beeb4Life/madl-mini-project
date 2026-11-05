import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  bool _emergencyOnly = false;
  bool _isMapView = false;
  final TextEditingController _searchController = TextEditingController();

  final MapController _mapController = MapController();
  LatLng? _userLocation;
  VetClinic? _selectedClinicOnMap;
  static const LatLng _defaultCityCenter = LatLng(19.0760, 72.8777);

  @override
  void initState() {
    super.initState();
    _loadClinics();
    _fetchUserLocation(silent: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClinics() async {
    setState(() => _isLoading = true);
    final query = _searchController.text.trim();
    final list = await DatabaseHelper.instance.getAllVets(
      query: query.isNotEmpty ? query : null,
      emergencyOnly: _emergencyOnly,
    );

    // If we have user location, calculate dynamic distance
    if (_userLocation != null) {
      for (int i = 0; i < list.length; i++) {
        final c = list[i];
        if (c.latitude != null && c.longitude != null) {
          final meters = Geolocator.distanceBetween(
            _userLocation!.latitude,
            _userLocation!.longitude,
            c.latitude!,
            c.longitude!,
          );
          list[i] = c.copyWith(distanceKm: double.parse((meters / 1000).toStringAsFixed(1)));
        }
      }
      list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }

    setState(() {
      _clinics = list;
      _isLoading = false;
    });
  }

  Future<void> _fetchUserLocation({bool silent = false}) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!silent && mounted) {
          AppSnackBar.show(context, 'Please enable device location services.');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!silent && mounted) {
            AppSnackBar.show(context, 'Location permission was denied.');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!silent && mounted) {
          AppSnackBar.show(context, 'Location permission is permanently denied.');
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      final newLoc = LatLng(position.latitude, position.longitude);
      setState(() {
        _userLocation = newLoc;
      });

      if (_isMapView) {
        _mapController.move(newLoc, 13.5);
      }

      await _loadClinics();

      if (!silent && mounted) {
        AppSnackBar.show(context, 'Live GPS location calibrated!');
      }
    } catch (e) {
      if (!silent && mounted) {
        AppSnackBar.show(context, 'Could not get GPS location: $e', isError: true);
      }
    }
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
          'CALL VETERINARY CLINIC',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dial this number directly from your phone:',
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

  Future<void> _openDirections(VetClinic clinic) async {
    final destination = (clinic.latitude != null && clinic.longitude != null)
        ? '${clinic.latitude},${clinic.longitude}'
        : Uri.encodeComponent('${clinic.name}, ${clinic.address}, ${clinic.city}');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$destination');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          AppSnackBar.show(context, 'Address: ${clinic.address}, ${clinic.city}');
        }
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(context, 'Address: ${clinic.address}, ${clinic.city}');
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
    final cityCtrl = TextEditingController(text: 'Metro City');
    final servicesCtrl = TextEditingController(text: 'General Care, Vaccinations');
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
                          '// ADD VET CLINIC',
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
                        labelText: 'CLINIC / VET NAME *',
                        hintText: 'e.g. City Paws Animal Hospital',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'PHONE NUMBER *',
                        hintText: 'e.g. +1 (555) 019-2834',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'STREET ADDRESS *',
                        hintText: 'e.g. 102 Parkview Avenue',
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
                        'Open all night with critical care emergency staff',
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

                        // Approximate offset coordinates from user or default
                        final baseLat = _userLocation?.latitude ?? _defaultCityCenter.latitude;
                        final baseLng = _userLocation?.longitude ?? _defaultCityCenter.longitude;

                        final clinic = VetClinic(
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          address: addressCtrl.text.trim(),
                          city: cityCtrl.text.trim(),
                          distanceKm: 2.5,
                          rating: 5.0,
                          isEmergency: isEmergency,
                          services: servicesCtrl.text.trim(),
                          isPrimary: false,
                          latitude: baseLat + 0.005,
                          longitude: baseLng + 0.005,
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
        AppSnackBar.show(context, 'New vet clinic added to directory.');
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
              'VETS NEAR ME',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isMapView ? Icons.view_list_outlined : Icons.map_outlined,
              color: Colors.white,
            ),
            tooltip: _isMapView ? 'Switch to List' : 'Switch to Interactive Map',
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
                _selectedClinicOnMap = null;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location, size: 20),
            tooltip: 'Update My GPS Location',
            onPressed: () => _fetchUserLocation(silent: false),
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
                      hintText: 'Search clinics, services, or specialty...',
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
                  Row(
                    children: [
                      FilterChip(
                        label: const Text(
                          'ALL CLINICS',
                          style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        selected: !_emergencyOnly,
                        selectedColor: AppColors.surfElevated(context),
                        backgroundColor: AppColors.surf(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: !_emergencyOnly ? Colors.white : AppColors.brd(context),
                          ),
                        ),
                        onSelected: (_) {
                          setState(() => _emergencyOnly = false);
                          _loadClinics();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        avatar: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.accentRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        label: const Text(
                          '24/7 EMERGENCY',
                          style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        selected: _emergencyOnly,
                        selectedColor: AppColors.accentRedDim,
                        backgroundColor: AppColors.surf(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: _emergencyOnly ? AppColors.danger : AppColors.brd(context),
                          ),
                        ),
                        onSelected: (_) {
                          setState(() => _emergencyOnly = true);
                          _loadClinics();
                        },
                      ),
                      const Spacer(),
                      // Map / List indicator badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfElevated(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.brd(context)),
                        ),
                        child: Text(
                          _isMapView ? '🗺️ OPENSTREETMAP' : '📋 LIST VIEW',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Emergency Notice Banner
            if (_emergencyOnly)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentRedDim,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.danger),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Showing 24-hour critical emergency hospitals with live trauma & triage units.',
                        style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            // Main Content: Interactive OpenStreetMap OR List View
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _isMapView
                      ? _buildInteractiveMap()
                      : _clinics.isEmpty
                          ? EmptyState(
                              icon: Icons.local_hospital_outlined,
                              title: 'NO CLINICS MATCHED',
                              message: 'Try clearing your search or add a custom veterinary clinic.',
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

  // ==========================================
  // INTERACTIVE OPENSTREETMAP (CartoDB Dark)
  // ==========================================
  Widget _buildInteractiveMap() {
    final center = _userLocation ??
        (_clinics.isNotEmpty && _clinics.first.latitude != null
            ? LatLng(_clinics.first.latitude!, _clinics.first.longitude!)
            : _defaultCityCenter);

    // Build markers
    final markers = <Marker>[];

    // User location pin (Pulsing blue/cyan)
    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 36,
          height: 36,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.cyanAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Clinic markers
    for (final clinic in _clinics) {
      if (clinic.latitude != null && clinic.longitude != null) {
        final isSelected = _selectedClinicOnMap?.id == clinic.id;
        final isEmergency = clinic.isEmergency;

        markers.add(
          Marker(
            point: LatLng(clinic.latitude!, clinic.longitude!),
            width: isSelected ? 48 : 38,
            height: isSelected ? 48 : 38,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedClinicOnMap = clinic;
                });
                _mapController.move(LatLng(clinic.latitude!, clinic.longitude!), 14.5);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isEmergency ? AppColors.accentRed : AppColors.surf(context),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : (isEmergency ? AppColors.danger : AppColors.brd(context)),
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isEmergency ? AppColors.accentRed.withValues(alpha: 0.5) : Colors.black45,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isEmergency ? Icons.local_hospital : Icons.pets,
                    size: isSelected ? 22 : 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Stack(
      children: [
        // Map Widget
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13.0,
            onTap: (_, _) {
              if (_selectedClinicOnMap != null) {
                setState(() => _selectedClinicOnMap = null);
              }
            },
          ),
          children: [
            // Dark Matter tile layer (Nothing OS styled monochrome tiles)
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.example.petsync',
            ),
            MarkerLayer(markers: markers),
          ],
        ),

        // Map Controls Floating Bar
        Positioned(
          top: 12,
          right: 12,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'map_recenter_user',
                backgroundColor: AppColors.surf(context),
                foregroundColor: Colors.white,
                tooltip: 'My Location',
                onPressed: () => _fetchUserLocation(silent: false),
                child: const Icon(Icons.my_location, size: 18),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'map_zoom_in',
                backgroundColor: AppColors.surf(context),
                foregroundColor: Colors.white,
                tooltip: 'Zoom In',
                onPressed: () {
                  final zoom = _mapController.camera.zoom + 1;
                  _mapController.move(_mapController.camera.center, zoom);
                },
                child: const Icon(Icons.add, size: 18),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'map_zoom_out',
                backgroundColor: AppColors.surf(context),
                foregroundColor: Colors.white,
                tooltip: 'Zoom Out',
                onPressed: () {
                  final zoom = _mapController.camera.zoom - 1;
                  _mapController.move(_mapController.camera.center, zoom);
                },
                child: const Icon(Icons.remove, size: 18),
              ),
            ],
          ),
        ),

        // Selected Clinic Bottom Sheet Card
        if (_selectedClinicOnMap != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildClinicCard(_selectedClinicOnMap!),
          ),
      ],
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
          mainAxisSize: MainAxisSize.min,
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

            // Address
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
                ),
              ),
            ],

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Actions Row
            Row(
              children: [
                Expanded(
                  child: NothingButton(
                    label: 'CALL NOW',
                    icon: Icons.phone_outlined,
                    height: 38,
                    onPressed: () => _makeCall(clinic.phone),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NothingButton.secondary(
                    label: 'NAVIGATE',
                    icon: Icons.directions_outlined,
                    height: 38,
                    onPressed: () => _openDirections(clinic),
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
