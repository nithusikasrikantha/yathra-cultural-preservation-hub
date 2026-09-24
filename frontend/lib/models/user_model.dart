class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final ProfileInfo profileInfo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.profileInfo,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'youth',
      profileInfo: ProfileInfo.fromJson(json['profileInfo'] ?? {}),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'profileInfo': profileInfo.toJson(),
    };
  }
}

class ProfileInfo {
  final String? bio;
  final String? avatar;
  final List<String> interests;
  final String? location;

  ProfileInfo({
    this.bio,
    this.avatar,
    this.interests = const [],
    this.location,
  });

  factory ProfileInfo.fromJson(Map<String, dynamic> json) {
    return ProfileInfo(
      bio: json['bio'],
      avatar: json['avatar'],
      interests: List<String>.from(json['interests'] ?? []),
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bio': bio,
      'avatar': avatar,
      'interests': interests,
      'location': location,
    };
  }
}
