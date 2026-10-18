import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../models/pet.dart';
import '../../database/database_helper.dart';
import '../../theme/app_colors.dart';
import '../../widgets/nothing_button.dart';
import '../../widgets/nothing_badge.dart';
import '../../widgets/pet_avatar.dart';
import '../../widgets/app_snackbar.dart';

class PetFormScreen extends StatefulWidget {
  final Pet? petToEdit;

  const PetFormScreen({super.key, this.petToEdit});

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _dobController;
  late TextEditingController _weightController;
  late TextEditingController _notesController;

  late String _selectedSpecies;
  String? _imagePath;
  final List<String> _speciesOptions = [
    'Dog',
    'Cat',
    'Bird',
    'Rabbit',
    'Hamster',
    'Fish',
    'Reptile',
    'Other',
  ];

  bool _isSaving = false;

  bool get _isEditing => widget.petToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.petToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _breedController = TextEditingController(text: p?.breed ?? '');
    _dobController = TextEditingController(text: p?.dateOfBirth ?? '');
    _weightController = TextEditingController(
      text: p?.weight != null ? p!.weight.toString() : '',
    );
    _notesController = TextEditingController(text: p?.notes ?? '');
    _imagePath = p?.imagePath;

    if (p != null && _speciesOptions.contains(p.species)) {
      _selectedSpecies = p.species;
    } else if (p != null) {
      _selectedSpecies = 'Other';
    } else {
      _selectedSpecies = 'Dog';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _dobController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (picked != null) {
        final appDir = await getApplicationSupportDirectory();
        final photosDir = Directory(p.join(appDir.path, 'pet_photos'));
        if (!await photosDir.exists()) {
          await photosDir.create(recursive: true);
        }

        final ext = p.extension(picked.path);
        final fileName = 'pet_${DateTime.now().millisecondsSinceEpoch}${ext.isEmpty ? '.jpg' : ext}';
        final savedFile = await File(picked.path).copy(p.join(photosDir.path, fileName));

        setState(() {
          _imagePath = savedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          'Could not load image: $e',
          isError: true,
        );
      }
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surf(context),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.brd(context), width: 1),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.brd(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PET PHOTO // AVATAR',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.face_outlined),
                  title: const Text('Select Stylized Avatar'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAvatarPicker();
                  },
                ),
                if (_imagePath != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                    title: const Text('Remove Photo', style: TextStyle(color: AppColors.danger)),
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _imagePath = null);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAvatarPicker() {
    final avatars = [
      {'key': 'avatar:dog', 'label': 'DOG'},
      {'key': 'avatar:cat', 'label': 'CAT'},
      {'key': 'avatar:rabbit', 'label': 'BUNNY'},
      {'key': 'avatar:bird', 'label': 'BIRD'},
      {'key': 'avatar:fish', 'label': 'FISH'},
      {'key': 'avatar:turtle', 'label': 'TURTLE'},
      {'key': 'avatar:star', 'label': 'STAR'},
      {'key': 'avatar:favorite', 'label': 'HEART'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.brd(context)),
        ),
        title: const Text(
          'CHOOSE AVATAR',
          style: TextStyle(fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.w700),
        ),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: avatars.map((av) {
            return GestureDetector(
              onTap: () {
                setState(() => _imagePath = av['key']);
                Navigator.of(context).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PetAvatar(
                    species: _selectedSpecies,
                    imagePath: av['key'],
                    size: 56,
                    borderRadius: 16,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    av['label']!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.txtSec(context),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    DateTime initial = DateTime.now();
    if (_dobController.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_dobController.text);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
        _dobController.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final double? parsedWeight = _weightController.text.trim().isNotEmpty
          ? double.tryParse(_weightController.text.trim())
          : null;

      final pet = Pet(
        id: widget.petToEdit?.id,
        name: _nameController.text.trim(),
        species: _selectedSpecies,
        breed: _breedController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        weight: parsedWeight,
        notes: _notesController.text.trim(),
        imagePath: _imagePath,
        createdAt: widget.petToEdit?.createdAt,
      );

      if (_isEditing) {
        await DatabaseHelper.instance.updatePet(pet);
      } else {
        await DatabaseHelper.instance.insertPet(pet);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          'Error saving pet: $e',
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
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'EDIT PET PROFILE' : 'NEW PET PROFILE',
          style: const TextStyle(
            fontFamily: 'monospace',
            letterSpacing: 1.0,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Photo / Avatar Selector Header
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showImageOptions,
                      child: PetAvatar(
                        species: _selectedSpecies,
                        imagePath: _imagePath,
                        size: 96,
                        borderRadius: 24,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageOptions,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.txt(context),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.bg(context), width: 2),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: AppColors.bg(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _showImageOptions,
                  child: Text(
                    _imagePath == null ? 'ADD PHOTO / AVATAR' : 'CHANGE PHOTO',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.txt(context),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Section: Header tag
              Row(
                children: [
                  Text(
                    '// DETAILS',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.txtMut(context),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  NothingBadge(
                    label: _isEditing ? 'UPDATE' : 'CREATE',
                    isAccented: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pet Name (Required)
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Pet Name *',
                  hintText: 'e.g. Luna',
                  prefixIcon: Icon(Icons.pets, size: 20, color: AppColors.txtSec(context)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your pet\'s name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Species Selection
              Text(
                'SPECIES *',
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
                children: _speciesOptions.map((species) {
                  final isSelected = _selectedSpecies == species;
                  return ChoiceChip(
                    label: Text(
                      species.toUpperCase(),
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
                        setState(() => _selectedSpecies = species);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Breed (Optional)
              TextFormField(
                controller: _breedController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Breed (Optional)',
                  hintText: 'e.g. Golden Retriever, Siamese',
                  prefixIcon: Icon(Icons.category_outlined, size: 20, color: AppColors.txtSec(context)),
                ),
              ),
              const SizedBox(height: 16),

              // Date of Birth (Optional)
              TextFormField(
                controller: _dobController,
                readOnly: true,
                onTap: _selectDateOfBirth,
                decoration: InputDecoration(
                  labelText: 'Date of Birth (Optional)',
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.txtSec(context)),
                  suffixIcon: _dobController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, size: 18, color: AppColors.txtMut(context)),
                          onPressed: () => setState(() => _dobController.clear()),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Weight (Optional)
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Weight (kg, Optional)',
                  hintText: 'e.g. 12.5',
                  prefixIcon: Icon(Icons.monitor_weight_outlined, size: 20, color: AppColors.txtSec(context)),
                ),
                validator: (val) {
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

              // Notes (Optional)
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Notes / Dietary / Medical Notes (Optional)',
                  hintText: 'e.g. Loves chew toys, allergic to beef kibble',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.notes_outlined, size: 20, color: AppColors.txtSec(context)),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              NothingButton(
                label: _isSaving
                    ? 'SAVING...'
                    : (_isEditing ? 'UPDATE PET' : 'REGISTER PET'),
                icon: Icons.check,
                isExpanded: true,
                height: 52,
                onPressed: _isSaving ? null : _savePet,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
