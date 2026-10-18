class HealthEntry {
  final int? id;
  final int petId;
  final String entryType; // 'weight', 'observation', 'vaccination', 'vet_visit'
  final String entryDate; // YYYY-MM-DD
  final String title;
  final String? notes;
  final double? weightValue; // In kg
  final String? veterinarian;
  final String? imagePath; // Prescription or report photo
  final String createdAt;

  // Joined display attributes
  final String? petName;
  final String? petSpecies;

  HealthEntry({
    this.id,
    required this.petId,
    required this.entryType,
    required this.entryDate,
    required this.title,
    this.notes,
    this.weightValue,
    this.veterinarian,
    this.imagePath,
    String? createdAt,
    this.petName,
    this.petSpecies,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'pet_id': petId,
      'entry_type': entryType.toLowerCase(),
      'entry_date': entryDate,
      'title': title.trim(),
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      'weight_value': weightValue,
      'veterinarian': veterinarian?.trim().isEmpty == true ? null : veterinarian?.trim(),
      'image_path': imagePath?.trim().isEmpty == true ? null : imagePath?.trim(),
      'created_at': createdAt,
    };
  }

  factory HealthEntry.fromMap(Map<String, dynamic> map) {
    return HealthEntry(
      id: map['id'] as int?,
      petId: map['pet_id'] as int,
      entryType: (map['entry_type'] as String?)?.toLowerCase() ?? 'observation',
      entryDate: map['entry_date'] as String,
      title: map['title'] as String,
      notes: map['notes'] as String?,
      weightValue: map['weight_value'] != null ? (map['weight_value'] as num).toDouble() : null,
      veterinarian: map['veterinarian'] as String?,
      imagePath: map['image_path'] as String?,
      createdAt: map['created_at'] as String,
      petName: map['pet_name'] as String?,
      petSpecies: map['pet_species'] as String?,
    );
  }

  HealthEntry copyWith({
    int? id,
    int? petId,
    String? entryType,
    String? entryDate,
    String? title,
    String? notes,
    double? weightValue,
    String? veterinarian,
    String? imagePath,
    String? createdAt,
    String? petName,
    String? petSpecies,
  }) {
    return HealthEntry(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      entryType: entryType ?? this.entryType,
      entryDate: entryDate ?? this.entryDate,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      weightValue: weightValue ?? this.weightValue,
      veterinarian: veterinarian ?? this.veterinarian,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      petName: petName ?? this.petName,
      petSpecies: petSpecies ?? this.petSpecies,
    );
  }
}
