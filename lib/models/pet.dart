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
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      species: json['species'] ?? '',
      breed: json['breed'],
      gender: json['gender'],
      birthDate: json['birth_date'],
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) : null,
      photo: json['photo'],
      specialMarks: json['special_marks'],
      isSteril: json['is_steril'] == 1 || json['is_steril'] == true,
      allergies: json['allergies'],
      healthNotes: json['health_notes'],
      age: json['age'],
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
}
