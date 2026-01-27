class NotificationSettings {
  final bool remindersEnabled;
  final bool communityEnabled;
  final bool marketingEnabled;

  const NotificationSettings({
    required this.remindersEnabled,
    required this.communityEnabled,
    required this.marketingEnabled,
  });

  factory NotificationSettings.defaults() {
    return const NotificationSettings(
      remindersEnabled: true,
      communityEnabled: true,
      marketingEnabled: true,
    );
  }
}
