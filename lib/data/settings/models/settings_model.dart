class SettingsModel {
  final String id;
  final String name;
  final bool isEnabled;
  final String? description;
  final String type;

  SettingsModel({
    required this.id,
    required this.name,
    required this.isEnabled,
    this.description,
    required this.type,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      isEnabled: json['isEnabled'] ?? false,
      description: json['description'],
      type: json['type'] ?? 'general',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isEnabled': isEnabled,
      'description': description,
      'type': type,
    };
  }
}

class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final String createdAt;

  UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt,
    };
  }
}
