class CareTask {
  final int? id;
  final int petId;
  final String title;
  final String category; // 'feeding', 'walking', 'grooming', 'other'
  final String? scheduledTime; // e.g., '08:30'
  final bool isCompleted;
  final String taskDate; // YYYY-MM-DD
  final String? notes;
  final String createdAt;

  // Joined display attributes
  final String? petName;
  final String? petSpecies;

  CareTask({
    this.id,
    required this.petId,
    required this.title,
    required this.category,
    this.scheduledTime,
    this.isCompleted = false,
    String? taskDate,
    this.notes,
    String? createdAt,
    this.petName,
    this.petSpecies,
  })  : taskDate = taskDate ?? DateTime.now().toIso8601String().substring(0, 10),
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'pet_id': petId,
      'title': title.trim(),
      'category': category.toLowerCase(),
      'scheduled_time': scheduledTime?.trim().isEmpty == true ? null : scheduledTime?.trim(),
      'is_completed': isCompleted ? 1 : 0,
      'task_date': taskDate,
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      'created_at': createdAt,
    };
  }

  factory CareTask.fromMap(Map<String, dynamic> map) {
    return CareTask(
      id: map['id'] as int?,
      petId: map['pet_id'] as int,
      title: map['title'] as String,
      category: (map['category'] as String?)?.toLowerCase() ?? 'other',
      scheduledTime: map['scheduled_time'] as String?,
      isCompleted: (map['is_completed'] as int) == 1,
      taskDate: map['task_date'] as String,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      petName: map['pet_name'] as String?,
      petSpecies: map['pet_species'] as String?,
    );
  }

  CareTask copyWith({
    int? id,
    int? petId,
    String? title,
    String? category,
    String? scheduledTime,
    bool? isCompleted,
    String? taskDate,
    String? notes,
    String? createdAt,
    String? petName,
    String? petSpecies,
  }) {
    return CareTask(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      title: title ?? this.title,
      category: category ?? this.category,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isCompleted: isCompleted ?? this.isCompleted,
      taskDate: taskDate ?? this.taskDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      petName: petName ?? this.petName,
      petSpecies: petSpecies ?? this.petSpecies,
    );
  }
}
