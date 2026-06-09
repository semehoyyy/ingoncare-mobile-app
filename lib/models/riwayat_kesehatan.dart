class RiwayatKesehatan {
  final int id;
  final int userId;
  final int? petId;
  final String tanggalPemeriksaan;
  final String diagnosis;
  final String tindakan;
  final String dokter;
  final String? catatan;
  final String? jadwalBerikutnya;
  final Pet? pet;

  RiwayatKesehatan({
    required this.id,
    required this.userId,
    this.petId,
    required this.tanggalPemeriksaan,
    required this.diagnosis,
    required this.tindakan,
    required this.dokter,
    this.catatan,
    this.jadwalBerikutnya,
    this.pet,
  });

  factory RiwayatKesehatan.fromJson(Map<String, dynamic> json) {
    return RiwayatKesehatan(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      petId: json['pet_id'],
      tanggalPemeriksaan: json['tanggal_pemeriksaan'] ?? '',
      diagnosis: json['diagnosis'] ?? '',
      tindakan: json['tindakan'] ?? '',
      dokter: json['dokter'] ?? '',
      catatan: json['catatan'],
      jadwalBerikutnya: json['jadwal_berikutnya'],
      pet: json['pet'] != null ? Pet.fromJson(json['pet']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pet_id': petId,
      'tanggal_pemeriksaan': tanggalPemeriksaan,
      'diagnosis': diagnosis,
      'tindakan': tindakan,
      'dokter': dokter,
      'catatan': catatan,
      'jadwal_berikutnya': jadwalBerikutnya,
    };
  }
}

class Pet {
  final int id;
  final String name;
  final String species;
  final String? breed;
  final String? gender;
  final String? age;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    this.gender,
    this.age,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'],
      name: json['name'] ?? '',
      species: json['species'] ?? '',
      breed: json['breed'],
      gender: json['gender'],
      age: json['age'],
    );
  }
}
