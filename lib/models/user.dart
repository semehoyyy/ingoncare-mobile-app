class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? profilePhoto;
  final String? dob;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.profilePhoto,
    this.dob,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      profilePhoto: json['profile_photo'],
      dob: json['dob'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'profile_photo': profilePhoto,
      'dob': dob,
    };
  }
}
