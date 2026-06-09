class Pengingat {
  final int id;
  final int userId;
  final int? petId;
  final String namaHewan;
  final String kategori;
  final String tanggal;
  final String waktu;
  final String? deskripsi;
  final String status;

  Pengingat({
    required this.id,
    required this.userId,
    this.petId,
    required this.namaHewan,
    required this.kategori,
    required this.tanggal,
    required this.waktu,
    this.deskripsi,
    this.status = 'aktif',
  });

  bool get isSelesai => status == 'selesai';

  factory Pengingat.fromJson(Map<String, dynamic> json) {
    return Pengingat(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      petId: json['pet_id'],
      namaHewan: json['nama_hewan'] ?? '',
      kategori: json['kategori'] ?? '',
      tanggal: json['tanggal'] ?? '',
      waktu: json['waktu'] ?? '',
      deskripsi: json['deskripsi'],
      status: json['status'] ?? 'aktif',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pet_id': petId,
      'kategori': kategori,
      'tanggal': tanggal,
      'waktu': waktu,
      'deskripsi': deskripsi,
    };
  }
}
