class Settings {
  final String id;
  final String name;
  final bool isEnabled;
  final String? description;
  final SettingsType type;

  Settings({
    required this.id,
    required this.name,
    required this.isEnabled,
    this.description,
    required this.type,
  });
}

enum SettingsType {
  notification,
  privacy,
  account,
  general,
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.createdAt,
  });
}
