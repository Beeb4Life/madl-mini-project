import 'package:flutter/material.dart';
import '../../models/pet.dart';
import '../../models/care_task.dart';
import '../../database/database_helper.dart';
import '../../theme/app_colors.dart';
import '../../widgets/nothing_button.dart';
import '../../widgets/app_snackbar.dart';

class CareTaskFormDialog extends StatefulWidget {
  final int? preselectedPetId;
  final CareTask? taskToEdit;

  const CareTaskFormDialog({
    super.key,
    this.preselectedPetId,
    this.taskToEdit,
  });

  static Future<bool> show(
    BuildContext context, {
    int? preselectedPetId,
    CareTask? taskToEdit,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surf(context),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppColors.brd(context), width: 1),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CareTaskFormDialog(
          preselectedPetId: preselectedPetId,
          taskToEdit: taskToEdit,
        ),
      ),
    );
    return result ?? false;
  }

  @override
  State<CareTaskFormDialog> createState() => _CareTaskFormDialogState();
}

class _CareTaskFormDialogState extends State<CareTaskFormDialog> {
  final _formKey = GlobalKey<FormState>();

  List<Pet> _pets = [];
  int? _selectedPetId;
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late TextEditingController _timeController;
  late TextEditingController _dateController;

  String _category = 'feeding';
  final List<String> _categories = ['feeding', 'walking', 'grooming', 'other'];

  bool _isLoadingPets = true;
  bool _isSaving = false;

  bool get _isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    final t = widget.taskToEdit;
    _titleController = TextEditingController(text: t?.title ?? '');
    _notesController = TextEditingController(text: t?.notes ?? '');
    _timeController = TextEditingController(text: t?.scheduledTime ?? '');
    _dateController = TextEditingController(
      text: t?.taskDate ?? DateTime.now().toIso8601String().substring(0, 10),
    );

    if (t != null) {
      _category = t.category;
      _selectedPetId = t.petId;
    } else {
      _selectedPetId = widget.preselectedPetId;
    }

    _loadPets();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _timeController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    final pets = await DatabaseHelper.instance.getAllPets();
    setState(() {
      _pets = pets;
      if (_selectedPetId == null && pets.isNotEmpty) {
        _selectedPetId = pets.first.id;
      }
      _isLoadingPets = false;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.textPrimary,
              onPrimary: AppColors.background,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      setState(() {
        _timeController.text = '$hour:$minute';
      });
    }
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_dateController.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.textPrimary,
              onPrimary: AppColors.background,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPetId == null) {
      AppSnackBar.show(
        context,
        'Please select or add a pet first.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final task = CareTask(
        id: widget.taskToEdit?.id,
        petId: _selectedPetId!,
        title: _titleController.text.trim(),
        category: _category,
        scheduledTime: _timeController.text.trim(),
        taskDate: _dateController.text.trim(),
        notes: _notesController.text.trim(),
        isCompleted: widget.taskToEdit?.isCompleted ?? false,
        createdAt: widget.taskToEdit?.createdAt,
      );

      if (_isEditing) {
        await DatabaseHelper.instance.updateCareTask(task);
      } else {
        await DatabaseHelper.instance.insertCareTask(task);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          'Error saving task: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header line
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderBright,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'EDIT CARE TASK' : 'NEW CARE TASK',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pet Selector
              if (_isLoadingPets)
                const LinearProgressIndicator(color: AppColors.textPrimary)
              else if (_pets.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger),
                  ),
                  child: const Text(
                    'No pets found. Please create a pet profile first.',
                    style: TextStyle(color: AppColors.danger, fontSize: 13),
                  ),
                )
              else
                DropdownButtonFormField<int>(
                  initialValue: _selectedPetId,
                  decoration: const InputDecoration(
                    labelText: 'Select Pet *',
                    prefixIcon: Icon(Icons.pets, size: 20, color: AppColors.textSecondary),
                  ),
                  dropdownColor: AppColors.surfaceElevated,
                  items: _pets.map((pet) {
                    return DropdownMenuItem<int>(
                      value: pet.id,
                      child: Text(
                        '${pet.name} (${pet.species})',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedPetId = val),
                  validator: (val) => val == null ? 'Please choose a pet' : null,
                ),
              const SizedBox(height: 16),

              // Task Title
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'e.g. Evening meal, 30 min walk',
                  prefixIcon: Icon(Icons.check_circle_outline, size: 20, color: AppColors.textSecondary),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Selector
              const Text(
                'CATEGORY *',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _category == cat;
                  return ChoiceChip(
                    label: Text(
                      cat.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppColors.background : AppColors.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.textPrimary,
                    backgroundColor: AppColors.surfaceElevated,
                    side: BorderSide(
                      color: isSelected ? AppColors.textPrimary : AppColors.border,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _category = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Scheduled Time & Date Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      readOnly: true,
                      onTap: _pickTime,
                      decoration: InputDecoration(
                        labelText: 'Time (Optional)',
                        hintText: 'HH:MM',
                        prefixIcon: const Icon(Icons.access_time, size: 20, color: AppColors.textSecondary),
                        suffixIcon: _timeController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                                onPressed: () => setState(() => _timeController.clear()),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: const InputDecoration(
                        labelText: 'Date *',
                        prefixIcon: Icon(Icons.calendar_today, size: 20, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'e.g. 1 scoop dry food with supplement',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Icon(Icons.notes, size: 20, color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              NothingButton(
                label: _isSaving ? 'SAVING...' : (_isEditing ? 'UPDATE TASK' : 'CREATE TASK'),
                icon: Icons.check,
                isExpanded: true,
                height: 50,
                onPressed: _isSaving || _pets.isEmpty ? null : _saveTask,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
