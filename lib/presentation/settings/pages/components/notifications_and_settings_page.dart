import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nepika/core/constants/routes.dart';
import 'package:nepika/core/constants/theme_notifier.dart';
import 'package:nepika/core/utils/shared_prefs_helper.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/delete_account_dialog.dart';
import 'package:nepika/presentation/settings/widgets/setting_header.dart';
import 'package:nepika/presentation/settings/widgets/settings_option_tile.dart';
import 'package:provider/provider.dart';

class NotificationsAndSettings extends StatefulWidget {
  const NotificationsAndSettings({super.key});

  @override
  State<NotificationsAndSettings> createState() =>
      _NotificationsAndSettingsState();
}

class _NotificationsAndSettingsState extends State<NotificationsAndSettings> {
  @override
  Widget build(BuildContext context) {
        final themeNotifier = Provider.of<ThemeNotifier>(context);

    final options = [
      _SettingsOptionData(
        'Notification Settings',
        onTap: () {
          Navigator.of(context).pushNamed(AppRoutes.setupNotifications);
        },
      ),
      _SettingsOptionData('Notification History', onTap: () {}),
      _SettingsOptionData('Settings', onTap: () {}),
      _SettingsOptionData(
        'Dark Mode',
        onTap: () {
          print('Dark Mode Toggled');
        },
        showToggle: true,
        toggleValue: false,
        onToggle: (value) async {
          print('Dark Mode Toggled 2: $value');
          themeNotifier.toggleTheme(value);
          await SharedPrefsHelper().setBool('Dark Mode', value);
          setState(() {}); // important
        },
      ),
      _SettingsOptionData('Version Info / About App', onTap: () {}),
      _SettingsOptionData('App Walkthrough / Tips', onTap: () {}),
      _SettingsOptionData('Delete Account',onTap: () {
    showDialog(
            context: context,
            builder: (_) => DeleteAccountDialog(
              reasons: const [
                'Results don’t match expectations',
                'Didn’t see any improvement in my skin',
                'Advice or products didn’t suit my skin',
                'Too many notifications or reminders',
                'Privacy concerns / not comfortable sharing data',
                'App is too complicated or hard to use',
                'Using another skincare app or solution',
                'App lacks features I need',
                'No longer interested in skincare tracking',
                'Found a better skincare routine elsewhere',
                'Too time-consuming to maintain logs',
                'Health or life situation has changed',
                'Prefer offline / in-person skin consultations',
                'App recommendations are repetitive',
                'Concerns with the accuracy of AI insights',
                'Just exploring, not a serious user',
                'Bugs or performance issues',
                'Language or region not fully supported',
                'Product or brand recommendations feel biased',
                'Other (please specify)',
              ],
            ),
          );
        },
      ),
    ];

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
                  if (option.showToggle) {
                    return FutureBuilder<bool?>(
                      future: SharedPrefsHelper().getBool(option.text),
                      builder: (context, snapshot) {
                        final toggleVal = snapshot.data ?? option.toggleValue;
                        print('Toggle Value: $toggleVal');
                        return SettingsOptionTile(
                          text: option.text,
                          onTap: option.onTap,
                          showToggle: option.showToggle,
                          toggleValue: toggleVal,
                          onToggleChanged: option.onToggle,
                          toggleStorageKey: option.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          textColor: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.color,
                          showDivider: false,
                        );
                      },
                    );
                  }

                  return SettingsOptionTile(
                    text: option.text,
                    onTap: option.onTap,
                    showToggle: false,
                    toggleValue: option.toggleValue,
                    onToggleChanged: option.onToggle,
                    toggleStorageKey: option.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    textColor: Theme.of(context).textTheme.bodyLarge?.color,
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
  final bool toggleValue;
  final ValueChanged<bool>? onToggle;
  _SettingsOptionData(
    this.text, {
    this.onTap,
    this.showToggle = false,
    this.toggleValue = false,
    this.onToggle,
  });
}
