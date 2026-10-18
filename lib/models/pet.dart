class Pet {
  final int? id;
  final String name;
  final String species;
  final String? breed;
  final String? dateOfBirth; // Format: YYYY-MM-DD
  final double? weight; // In kilograms
  final String? notes;
  final String? imagePath; // Local file path or avatar key
  final String createdAt;

  Pet({
    this.id,
    required this.name,
    required this.species,
    this.breed,
    this.dateOfBirth,
    this.weight,
    this.notes,
    this.imagePath,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'species': species,
      'breed': breed?.trim().isEmpty == true ? null : breed?.trim(),
      'date_of_birth': dateOfBirth?.trim().isEmpty == true ? null : dateOfBirth?.trim(),
      'weight': weight,
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      'image_path': imagePath?.trim().isEmpty == true ? null : imagePath?.trim(),
      'created_at': createdAt,
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] as int?,
      name: map['name'] as String,
      species: map['species'] as String,
      breed: map['breed'] as String?,
      dateOfBirth: map['date_of_birth'] as String?,
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      notes: map['notes'] as String?,
      imagePath: map['image_path'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Pet copyWith({
    int? id,
    String? name,
    String? species,
    String? breed,
    String? dateOfBirth,
    double? weight,
    String? notes,
    String? imagePath,
    String? createdAt,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
