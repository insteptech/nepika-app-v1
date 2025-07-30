import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/setting_header.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/settings_option_tile.dart';

class NotificationsAndSettings extends StatefulWidget {
  const NotificationsAndSettings({super.key});

  @override
  State<NotificationsAndSettings> createState() =>
      _NotificationsAndSettingsState();
}

class _NotificationsAndSettingsState extends State<NotificationsAndSettings> {
  final options = [
    _SettingsOptionData('Notification Settings', onTap: () {}),
    _SettingsOptionData('Notification History', onTap: () {}),
    _SettingsOptionData('Settings', onTap: () {}),
    _SettingsOptionData('Dark Mode', onTap: () {}, showToggle: true),
    _SettingsOptionData('Version Info / About App', onTap: () {}),
    _SettingsOptionData('App Walkthrough / Tips', onTap: () {}),
    _SettingsOptionData('Delete Account', onTap: () {}),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            SettingHeader(
              title: 'Notifications & Settings',
              showBackButton: true,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  return SettingsOptionTile(
                    text: option.text,
                    onTap: option.onTap,
                    showToggle: option.showToggle,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    textColor: theme.textTheme.bodyLarge?.color,
                    showDivider: false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsOptionData {
  final String text;
  final VoidCallback? onTap;
  final bool showToggle;
  _SettingsOptionData(this.text, {this.onTap, this.showToggle = false});
}
