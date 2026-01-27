import '../../../domain/auth/entities/notification_settings.dart';

class NotificationSettingsModel extends NotificationSettings {
  const NotificationSettingsModel({
    required super.remindersEnabled,
    required super.communityEnabled,
    required super.marketingEnabled,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      remindersEnabled: json['reminders_enabled'] ?? true,
      communityEnabled: json['community_enabled'] ?? true,
      marketingEnabled: json['marketing_enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reminders_enabled': remindersEnabled,
      'community_enabled': communityEnabled,
      'marketing_enabled': marketingEnabled,
    };
  }
}
