import 'package:flutter/material.dart';
import '../../models/pet.dart';
import '../../models/care_task.dart';
import '../../models/health_entry.dart';
import '../../database/database_helper.dart';
import '../../theme/app_colors.dart';
import '../../widgets/nothing_card.dart';
import '../../widgets/nothing_badge.dart';
import '../../widgets/nothing_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/pet_avatar.dart';
import '../../widgets/app_snackbar.dart';
import 'pet_form_screen.dart';
import '../care/care_task_form_dialog.dart';
import '../health/health_entry_form_dialog.dart';

class PetDetailScreen extends StatefulWidget {
  final int petId;

  const PetDetailScreen({super.key, required this.petId});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  Pet? _pet;
  List<CareTask> _tasks = [];
  List<HealthEntry> _healthEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final pet = await DatabaseHelper.instance.getPetById(widget.petId);
    if (pet != null) {
      final tasks = await DatabaseHelper.instance.getTasksForPet(widget.petId);
      final entries = await DatabaseHelper.instance.getHealthEntriesForPet(widget.petId);
      setState(() {
        _pet = pet;
        _tasks = tasks;
        _healthEntries = entries;
        _isLoading = false;
      });
    } else {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  String _formatAge(String? dobString) {
    if (dobString == null || dobString.isEmpty) return 'Age: Unknown';
    try {
      final dob = DateTime.parse(dobString);
      final now = DateTime.now();
      int years = now.year - dob.year;
      int months = now.month - dob.month;
      if (now.day < dob.day) months--;
      if (months < 0) {
        years--;
        months += 12;
      }
      if (years > 0) {
        return '$years yr${years > 1 ? 's' : ''}${months > 0 ? ' $months mo' : ''}';
      } else if (months > 0) {
        return '$months month${months > 1 ? 's' : ''} old';
      } else {
        final days = now.difference(dob).inDays;
        return '$days day${days > 1 ? 's' : ''} old';
      }
    } catch (_) {
      return dobString;
    }
  }

  Future<void> _deletePet() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'DELETE PROFILE',
      message: 'Are you sure you want to delete ${_pet!.name}\'s profile? All linked daily care tasks and health journal records will also be permanently deleted.',
      confirmLabel: 'CONFIRM DELETE',
      isDestructive: true,
    );

    if (confirmed) {
      await DatabaseHelper.instance.deletePet(widget.petId);
      if (mounted) {
        AppSnackBar.show(
          context,
          '${_pet!.name}\'s profile and records deleted.',
        );
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _editPet() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PetFormScreen(petToEdit: _pet),
      ),
    );
    if (updated == true) {
      _loadData();
    }
  }

  Future<void> _addTask() async {
    final created = await CareTaskFormDialog.show(
      context,
      preselectedPetId: widget.petId,
    );
    if (created == true) {
      _loadData();
    }
  }

  Future<void> _addHealthEntry() async {
    final created = await HealthEntryFormDialog.show(
      context,
      preselectedPetId: widget.petId,
    );
    if (created == true) {
      _loadData();
    }
  }

  Future<void> _toggleTask(CareTask task) async {
    await DatabaseHelper.instance.toggleCareTask(task.id!, !task.isCompleted);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.textPrimary),
        ),
      );
    }

    if (_pet == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'PET NOT FOUND',
            style: TextStyle(fontFamily: 'monospace', color: AppColors.textMuted),
          ),
        ),
      );
    }

    final pet = _pet!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          pet.name.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'monospace',
            letterSpacing: 1.2,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Edit Profile',
            onPressed: _editPet,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
            tooltip: 'Delete Profile',
            onPressed: _deletePet,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.textPrimary,
          backgroundColor: AppColors.surface,
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Hero Profile Card
              NothingCard(
                hasRedDot: true,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PetAvatar(
                          species: pet.species,
                          imagePath: pet.imagePath,
                          size: 64,
                          borderRadius: 18,
                          allowPreview: true,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pet.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  NothingBadge(label: pet.species),
                                  if (pet.breed != null && pet.breed!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        pet.breed!,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Metrics row
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricItem(
                            label: 'AGE',
                            value: _formatAge(pet.dateOfBirth),
                            icon: Icons.cake_outlined,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: AppColors.borderSubtle,
                        ),
                        Expanded(
                          child: _buildMetricItem(
                            label: 'WEIGHT',
                            value: pet.weight != null ? '${pet.weight} kg' : 'Not set',
                            icon: Icons.monitor_weight_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Notes Card if any
              if (pet.notes != null && pet.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                NothingCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notes, size: 14, color: AppColors.textMuted),
                          SizedBox(width: 6),
                          Text(
                            'SPECIAL NOTES',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pet.notes!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Care Tasks Section
              SectionHeader(
                codePrefix: '// 01',
                title: 'CARE ROUTINES',
                actionText: '+ NEW TASK',
                onActionTap: _addTask,
              ),
              const SizedBox(height: 8),
              if (_tasks.isEmpty)
                NothingCard(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Center(
                    child: Column(
                      children: [
                        const Text(
                          'NO TASKS LINKED',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: AppColors.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        NothingButton.secondary(
                          label: 'CREATE TASK',
                          icon: Icons.add,
                          height: 36,
                          onPressed: _addTask,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._tasks.map((task) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NothingCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Checkbox(
                              value: task.isCompleted,
                              activeColor: AppColors.textPrimary,
                              checkColor: AppColors.background,
                              side: const BorderSide(color: AppColors.borderBright, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (_) => _toggleTask(task),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: task.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      NothingBadge(label: task.category),
                                      if (task.scheduledTime != null) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          task.scheduledTime!,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),

              const SizedBox(height: 24),

              // Health History Section
              SectionHeader(
                codePrefix: '// 02',
                title: 'HEALTH JOURNAL',
                actionText: '+ NEW ENTRY',
                onActionTap: _addHealthEntry,
              ),
              const SizedBox(height: 8),
              if (_healthEntries.isEmpty)
                NothingCard(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Center(
                    child: Column(
                      children: [
                        const Text(
                          'NO HEALTH RECORDS YET',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: AppColors.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        NothingButton.secondary(
                          label: 'LOG HEALTH ENTRY',
                          icon: Icons.add,
                          height: 36,
                          onPressed: _addHealthEntry,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._healthEntries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NothingCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                NothingBadge(
                                  label: entry.entryType,
                                  isAccented: entry.entryType == 'vet_visit',
                                ),
                                Text(
                                  entry.entryDate,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              entry.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (entry.weightValue != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Recorded Weight: ${entry.weightValue} kg',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            if (entry.veterinarian != null && entry.veterinarian!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Vet: ${entry.veterinarian}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                entry.notes!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.txt(context),
            ),
          ),
        ],
      ),
    );
  }
}
