class VetClinic {
  final int? id;
  final String name;
  final String phone;
  final String address;
  final String city;
  final double distanceKm;
  final double rating;
  final bool isEmergency;
  final String services;
  final bool isPrimary;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final String createdAt;

  const VetClinic({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.distanceKm,
    required this.rating,
    this.isEmergency = false,
    required this.services,
    this.isPrimary = false,
    this.notes,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'city': city,
      'distance_km': distanceKm,
      'rating': rating,
      'is_emergency': isEmergency ? 1 : 0,
      'services': services,
      'is_primary': isPrimary ? 1 : 0,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt,
    };
  }

  factory VetClinic.fromMap(Map<String, dynamic> map) {
    return VetClinic(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      address: map['address'] as String,
      city: map['city'] as String,
      distanceKm: (map['distance_km'] as num).toDouble(),
      rating: (map['rating'] as num).toDouble(),
      isEmergency: (map['is_emergency'] as int) == 1,
      services: map['services'] as String,
      isPrimary: (map['is_primary'] as int) == 1,
      notes: map['notes'] as String?,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      createdAt: map['created_at'] as String,
    );
  }

  VetClinic copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? city,
    double? distanceKm,
    double? rating,
    bool? isEmergency,
    String? services,
    bool? isPrimary,
    String? notes,
    double? latitude,
    double? longitude,
    String? createdAt,
  }) {
    return VetClinic(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      distanceKm: distanceKm ?? this.distanceKm,
      rating: rating ?? this.rating,
      isEmergency: isEmergency ?? this.isEmergency,
      services: services ?? this.services,
      isPrimary: isPrimary ?? this.isPrimary,
      notes: notes ?? this.notes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
