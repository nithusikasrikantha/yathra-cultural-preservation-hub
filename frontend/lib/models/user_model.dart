class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final ProfileInfo profileInfo;
  final bool profileComplete;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.profileInfo,
    this.profileComplete = false,
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
      profileComplete: json['profileComplete'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'profileInfo': profileInfo.toJson(),
      'profileComplete': profileComplete,
    };
  }
}

class ProfileInfo {
  final String? bio;
  final String? avatar;
  final List<String> interests;
  final String? location;
  final String? ageGroup;
  final String? preferredLanguage;

  ProfileInfo({
    this.bio,
    this.avatar,
    this.interests = const [],
    this.location,
    this.ageGroup,
    this.preferredLanguage,
  });

  factory ProfileInfo.fromJson(Map<String, dynamic> json) {
    return ProfileInfo(
      bio: json['bio'],
      avatar: json['avatar'],
      interests: List<String>.from(json['interests'] ?? []),
      location: json['location'],
      ageGroup: json['ageGroup'],
      preferredLanguage: json['preferredLanguage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bio': bio,
      'avatar': avatar,
      'interests': interests,
      'location': location,
      'ageGroup': ageGroup,
      'preferredLanguage': preferredLanguage,
    };
  }
}
