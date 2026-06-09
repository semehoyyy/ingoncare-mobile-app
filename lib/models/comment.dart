class Comment {
  final int id;
  final int userId;
  final String? title;
  final String content;
  final String? image;
  final int likesCount;
  final int repliesCount;
  final bool isLiked;
  final User? user;
  final DateTime? createdAt;

  Comment({
    required this.id,
    required this.userId,
    this.title,
    required this.content,
    this.image,
    this.likesCount = 0,
    this.repliesCount = 0,
    this.isLiked = false,
    this.user,
    this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      title: json['title'],
      content: json['content'] ?? '',
      image: json['image'],
      likesCount: json['likes_count'] ?? (json['likes'] is List ? (json['likes'] as List).length : 0),
      repliesCount: json['replies_count'] ?? (json['replies'] is List ? (json['replies'] as List).length : 0),
      isLiked: json['is_liked'] ?? false,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
}

class User {
  final int id;
  final String name;
  final String? profilePhoto;

  User({required this.id, required this.name, this.profilePhoto});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      profilePhoto: json['profile_photo'],
    );
  }
}
