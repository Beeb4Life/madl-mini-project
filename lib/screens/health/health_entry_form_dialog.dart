import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../models/pet.dart';
import '../../models/health_entry.dart';
import '../../database/database_helper.dart';
import '../../theme/app_colors.dart';
import '../../widgets/nothing_button.dart';
import '../../widgets/app_snackbar.dart';

class HealthEntryFormDialog extends StatefulWidget {
  final int? preselectedPetId;
  final HealthEntry? entryToEdit;

  const HealthEntryFormDialog({
    super.key,
    this.preselectedPetId,
    this.entryToEdit,
  });

  static Future<bool> show(
    BuildContext context, {
    int? preselectedPetId,
    HealthEntry? entryToEdit,
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
        child: HealthEntryFormDialog(
          preselectedPetId: preselectedPetId,
          entryToEdit: entryToEdit,
        ),
      ),
    );
    return result ?? false;
  }

  @override
  State<HealthEntryFormDialog> createState() => _HealthEntryFormDialogState();
}

class _HealthEntryFormDialogState extends State<HealthEntryFormDialog> {
  final _formKey = GlobalKey<FormState>();

  List<Pet> _pets = [];
  int? _selectedPetId;
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late TextEditingController _dateController;
  late TextEditingController _weightController;
  late TextEditingController _vetController;
  String? _imagePath;

  String _entryType = 'observation';
  final List<Map<String, String>> _types = [
    {'key': 'observation', 'label': 'Observation'},
    {'key': 'vaccination', 'label': 'Vaccine'},
    {'key': 'vet_visit', 'label': 'Vet Visit'},
    {'key': 'weight', 'label': 'Weight'},
  ];

  bool _isLoadingPets = true;
  bool _isSaving = false;

  bool get _isEditing => widget.entryToEdit != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entryToEdit;
    _titleController = TextEditingController(text: e?.title ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');
    _dateController = TextEditingController(
      text: e?.entryDate ?? DateTime.now().toIso8601String().substring(0, 10),
    );
    _weightController = TextEditingController(
      text: e?.weightValue != null ? e!.weightValue.toString() : '',
    );
    _vetController = TextEditingController(text: e?.veterinarian ?? '');
    _imagePath = e?.imagePath;

    if (e != null) {
      _entryType = e.entryType;
      _selectedPetId = e.petId;
    } else {
      _selectedPetId = widget.preselectedPetId;
    }

    _loadPets();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    _weightController.dispose();
    _vetController.dispose();
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (picked != null) {
        final appDir = await getApplicationSupportDirectory();
        final photosDir = Directory(p.join(appDir.path, 'health_records'));
        if (!await photosDir.exists()) {
          await photosDir.create(recursive: true);
        }

        final ext = p.extension(picked.path);
        final fileName = 'rec_${DateTime.now().millisecondsSinceEpoch}${ext.isEmpty ? '.jpg' : ext}';
        final savedFile = await File(picked.path).copy(p.join(photosDir.path, fileName));

        setState(() {
          _imagePath = savedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          'Could not attach image: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_dateController.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.txt(context),
              onPrimary: AppColors.bg(context),
              surface: AppColors.surf(context),
              onSurface: AppColors.txt(context),
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

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPetId == null) {
      AppSnackBar.show(
        context,
        'Please select a pet first.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final double? parsedWeight = _weightController.text.trim().isNotEmpty
          ? double.tryParse(_weightController.text.trim())
          : null;

      final entry = HealthEntry(
        id: widget.entryToEdit?.id,
        petId: _selectedPetId!,
        entryType: _entryType,
        entryDate: _dateController.text.trim(),
        title: _titleController.text.trim(),
        notes: _notesController.text.trim(),
        weightValue: parsedWeight,
        veterinarian: _vetController.text.trim(),
        imagePath: _imagePath,
        createdAt: widget.entryToEdit?.createdAt,
      );

      if (_isEditing) {
        await DatabaseHelper.instance.updateHealthEntry(entry);
      } else {
        await DatabaseHelper.instance.insertHealthEntry(entry);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          'Error saving health record: $e',
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
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.brd(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'EDIT HEALTH RECORD' : 'LOG HEALTH ENTRY',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppColors.txt(context),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: AppColors.txtMut(context)),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pet Dropdown
              if (_isLoadingPets)
                LinearProgressIndicator(color: AppColors.txt(context))
              else if (_pets.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfElevated(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger),
                  ),
                  child: const Text(
                    'No pets registered yet. Add a pet first.',
                    style: TextStyle(color: AppColors.danger, fontSize: 13),
                  ),
                )
              else
                DropdownButtonFormField<int>(
                  initialValue: _selectedPetId,
                  decoration: InputDecoration(
                    labelText: 'Select Pet *',
                    prefixIcon: Icon(Icons.pets, size: 20, color: AppColors.txtSec(context)),
                  ),
                  dropdownColor: AppColors.surfElevated(context),
                  items: _pets.map((pet) {
                    return DropdownMenuItem<int>(
                      value: pet.id,
                      child: Text(
                        '${pet.name} (${pet.species})',
                        style: TextStyle(color: AppColors.txt(context)),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedPetId = val),
                  validator: (val) => val == null ? 'Please select a pet' : null,
                ),
              const SizedBox(height: 16),

              // Entry Type Chips
              Text(
                'RECORD TYPE *',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.txtSec(context),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types.map((type) {
                  final isSelected = _entryType == type['key'];
                  return ChoiceChip(
                    label: Text(
                      type['label']!.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppColors.bg(context) : AppColors.txtSec(context),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.txt(context),
                    backgroundColor: AppColors.surfElevated(context),
                    side: BorderSide(
                      color: isSelected ? AppColors.txt(context) : AppColors.brd(context),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _entryType = type['key']!);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Title / Subject *',
                  hintText: _entryType == 'vaccination'
                      ? 'e.g. Annual Rabies Booster'
                      : _entryType == 'weight'
                          ? 'e.g. Routine Weight Tracking'
                          : _entryType == 'vet_visit'
                              ? 'e.g. Checkup for cough'
                              : 'e.g. Energy level observation',
                  prefixIcon: Icon(Icons.title, size: 20, color: AppColors.txtSec(context)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date Field
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _pickDate,
                decoration: InputDecoration(
                  labelText: 'Date *',
                  prefixIcon: Icon(Icons.calendar_today, size: 20, color: AppColors.txtSec(context)),
                ),
              ),
              const SizedBox(height: 16),

              // Conditional: Weight field
              if (_entryType == 'weight' || _entryType == 'vet_visit') ...[
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'e.g. 15.2',
                    prefixIcon: Icon(Icons.monitor_weight_outlined, size: 20, color: AppColors.txtSec(context)),
                  ),
                  validator: (val) {
                    if (_entryType == 'weight' && (val == null || val.trim().isEmpty)) {
                      return 'Please enter the weight value';
                    }
                    if (val != null && val.trim().isNotEmpty) {
                      final n = double.tryParse(val.trim());
                      if (n == null || n <= 0) {
                        return 'Enter a valid positive number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Conditional: Veterinarian / Clinic field
              if (_entryType == 'vet_visit' || _entryType == 'vaccination') ...[
                TextFormField(
                  controller: _vetController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Veterinarian / Clinic Name',
                    hintText: 'e.g. Dr. Emily Carter / South Vet Clinic',
                    prefixIcon: Icon(Icons.local_hospital_outlined, size: 20, color: AppColors.txtSec(context)),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Photo Attachment Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ATTACHMENT // RECEIPT (OPTIONAL)',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.txtSec(context),
                      letterSpacing: 0.8,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.camera_alt_outlined, size: 20),
                        tooltip: 'Camera',
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo_library_outlined, size: 20),
                        tooltip: 'Gallery',
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                    ],
                  ),
                ],
              ),
              if (_imagePath != null && File(_imagePath!).existsSync()) ...[
                const SizedBox(height: 6),
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_imagePath!),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black87,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, size: 16, color: Colors.white),
                          onPressed: () => setState(() => _imagePath = null),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Notes / Clinical Remarks
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Clinical Notes / Details (Optional)',
                  hintText: 'e.g. Prescribed antibiotics twice a day for 7 days',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.notes, size: 20, color: AppColors.txtSec(context)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              NothingButton(
                label: _isSaving ? 'SAVING...' : (_isEditing ? 'UPDATE RECORD' : 'SAVE RECORD'),
                icon: Icons.check,
                isExpanded: true,
                height: 50,
                onPressed: _isSaving || _pets.isEmpty ? null : _saveEntry,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
