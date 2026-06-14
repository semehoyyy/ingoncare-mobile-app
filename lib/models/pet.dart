class Pet {
  final int id;
  final int userId;
  final String name;
  final String species;
  final String? breed;
  final String? gender;
  final String? birthDate;
  final double? weight;
  final String? photo;
  final String? specialMarks;
  final bool isSteril;
  final String? allergies;
  final String? healthNotes;
  final String? age;

  // Tambahan untuk offline
  final bool isSynced;

  Pet({
    required this.id,
    required this.userId,
    required this.name,
    required this.species,
    this.breed,
    this.gender,
    this.birthDate,
    this.weight,
    this.photo,
    this.specialMarks,
    this.isSteril = false,
    this.allergies,
    this.healthNotes,
    this.age,
    this.isSynced = true,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      species: json['species'] ?? '',
      breed: json['breed'],
      gender: json['gender'],
      birthDate: json['birth_date'],
      weight: json['weight'] != null
          ? double.tryParse(json['weight'].toString())
          : null,
      photo: json['photo'],
      specialMarks: json['special_marks'],
      isSteril: json['is_steril'] == 1 || json['is_steril'] == true,
      allergies: json['allergies'],
      healthNotes: json['health_notes'],
      age: json['age'],
      isSynced: json['is_synced'] == null
          ? true
          : json['is_synced'] == 1 || json['is_synced'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'species': species,
      'breed': breed,
      'gender': gender,
      'birth_date': birthDate,
      'weight': weight,
      'special_marks': specialMarks,
      'is_steril': isSteril ? 1 : 0,
      'allergies': allergies,
      'health_notes': healthNotes,
    };
  }

  // Untuk simpan ke local storage
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'species': species,
      'breed': breed,
      'gender': gender,
      'birth_date': birthDate,
      'weight': weight,
      'photo': photo,
      'special_marks': specialMarks,
      'is_steril': isSteril ? 1 : 0,
      'allergies': allergies,
      'health_notes': healthNotes,
      'age': age,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  Pet copyWith({
    int? id,
    int? userId,
    String? name,
    String? species,
    String? breed,
    String? gender,
    String? birthDate,
    double? weight,
    String? photo,
    String? specialMarks,
    bool? isSteril,
    String? allergies,
    String? healthNotes,
    String? age,
    bool? isSynced,
  }) {
    return Pet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      weight: weight ?? this.weight,
      photo: photo ?? this.photo,
      specialMarks: specialMarks ?? this.specialMarks,
      isSteril: isSteril ?? this.isSteril,
      allergies: allergies ?? this.allergies,
      healthNotes: healthNotes ?? this.healthNotes,
      age: age ?? this.age,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}