import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/pet.dart';
import '../../models/health_entry.dart';
import '../../database/database_helper.dart';
import '../../theme/app_colors.dart';
import '../../widgets/nothing_card.dart';
import '../../widgets/nothing_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/app_snackbar.dart';
import 'health_entry_form_dialog.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  List<Pet> _pets = [];
  List<HealthEntry> _entries = [];
  int? _selectedPetFilter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final pets = await DatabaseHelper.instance.getAllPets();
    final entries = await DatabaseHelper.instance.getAllHealthEntries(
      petId: _selectedPetFilter,
    );

    setState(() {
      _pets = pets;
      _entries = entries;
      _isLoading = false;
    });
  }

  Future<void> _openAddEntry() async {
    if (_pets.isEmpty) {
      AppSnackBar.show(context, 'Please add a pet first to record health events.');
      return;
    }

    final created = await HealthEntryFormDialog.show(
      context,
      preselectedPetId: _selectedPetFilter,
    );
    if (created == true) {
      _loadData();
    }
  }

  Future<void> _deleteEntry(HealthEntry entry) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'DELETE RECORD',
      message: 'Delete health record "${entry.title}" dated ${entry.entryDate}?',
      confirmLabel: 'DELETE',
      isDestructive: true,
    );

    if (confirmed) {
      await DatabaseHelper.instance.deleteHealthEntry(entry.id!);
      _loadData();
      if (mounted) {
        AppSnackBar.show(context, 'Record deleted.');
      }
    }
  }

  void _showImagePreview(String imagePath) {
    final file = File(imagePath);
    if (!file.existsSync()) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                file,
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'vaccination':
        return Icons.medical_services_outlined;
      case 'vet_visit':
        return Icons.local_hospital_outlined;
      case 'weight':
        return Icons.monitor_weight_outlined;
      default:
        return Icons.remove_red_eye_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'HEALTH JOURNAL',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfElevated(context),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.brd(context), width: 1),
              ),
              child: Text(
                '${_entries.length}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.txtSec(context),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'health_fab',
        backgroundColor: AppColors.txt(context),
        foregroundColor: AppColors.bg(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'NEW RECORD',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
        onPressed: _openAddEntry,
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppColors.txt(context)),
              )
            : RefreshIndicator(
                color: AppColors.txt(context),
                backgroundColor: AppColors.surf(context),
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 8,
                    bottom: 90,
                  ),
                  children: [
                    // Disclaimer Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfElevated(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.brd(context), width: 0.8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: AppColors.txtMut(context)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Personal health logs for record-keeping; not for medical diagnosis.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.txtMut(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Pet Filter Chips
                    if (_pets.isNotEmpty) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: const Text('ALL PETS'),
                                labelStyle: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedPetFilter == null
                                      ? AppColors.bg(context)
                                      : AppColors.txtSec(context),
                                ),
                                selected: _selectedPetFilter == null,
                                selectedColor: AppColors.txt(context),
                                backgroundColor: AppColors.surfElevated(context),
                                side: BorderSide(
                                  color: _selectedPetFilter == null
                                      ? AppColors.txt(context)
                                      : AppColors.brd(context),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() => _selectedPetFilter = null);
                                    _loadData();
                                  }
                                },
                              ),
                            ),
                            ..._pets.map((p) {
                              final isSelected = _selectedPetFilter == p.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(p.name.toUpperCase()),
                                  labelStyle: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppColors.bg(context)
                                        : AppColors.txtSec(context),
                                  ),
                                  selected: isSelected,
                                  selectedColor: AppColors.txt(context),
                                  backgroundColor: AppColors.surfElevated(context),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.txt(context)
                                        : AppColors.brd(context),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  onSelected: (sel) {
                                    setState(() {
                                      _selectedPetFilter = sel ? p.id : null;
                                    });
                                    _loadData();
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Empty State
                    if (_entries.isEmpty)
                      EmptyState(
                        icon: Icons.health_and_safety_outlined,
                        title: 'NO HEALTH RECORDS',
                        message: _pets.isEmpty
                            ? 'Register a pet first to document vaccinations, weight history, and veterinary appointments.'
                            : 'Log your pet\'s veterinary checkups, vaccination booster shots, weight measurements, or health observations.',
                        actionLabel: _pets.isNotEmpty ? 'LOG ENTRY' : null,
                        onAction: _pets.isNotEmpty ? _openAddEntry : null,
                      )
                    else
                      ..._entries.map((entry) => _buildEntryCard(entry)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEntryCard(HealthEntry entry) {
    final isVetVisit = entry.entryType.toLowerCase() == 'vet_visit';
    final hasImage = entry.imagePath != null &&
        File(entry.imagePath!).existsSync();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NothingCard(
        hasRedDot: isVetVisit,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Badges and Date
            Row(
              children: [
                NothingBadge(
                  label: entry.entryType.replaceAll('_', ' '),
                  icon: _getTypeIcon(entry.entryType),
                  isAccented: isVetVisit,
                ),
                const SizedBox(width: 8),
                if (entry.petName != null)
                  Text(
                    entry.petName!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.txtSec(context),
                    ),
                  ),
                const Spacer(),
                Text(
                  entry.entryDate,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.txtMut(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title and Delete
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    entry.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.txt(context),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.delete_outline, size: 18, color: AppColors.txtMut(context)),
                  tooltip: 'Delete Record',
                  onPressed: () => _deleteEntry(entry),
                ),
              ],
            ),

            // Weight or Vet info
            if (entry.weightValue != null || (entry.veterinarian != null && entry.veterinarian!.isNotEmpty)) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (entry.weightValue != null) ...[
                    Icon(Icons.monitor_weight_outlined, size: 13, color: AppColors.txtSec(context)),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.weightValue} kg',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.txt(context),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  if (entry.veterinarian != null && entry.veterinarian!.isNotEmpty) ...[
                    Icon(Icons.local_hospital_outlined, size: 13, color: AppColors.txtSec(context)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        entry.veterinarian!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.txtSec(context),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // Photo attachment preview thumbnail if present
            if (hasImage) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showImagePreview(entry.imagePath!),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.brd(context)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(entry.imagePath!),
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fullscreen, size: 12, color: Colors.white),
                                SizedBox(width: 2),
                                Text(
                                  'VIEW',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Notes
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                entry.notes!,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.txtSec(context),
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
