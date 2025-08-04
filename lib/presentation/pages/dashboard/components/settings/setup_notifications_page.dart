import 'package:flutter/material.dart';
import 'package:nepika/core/utils/shared_prefs_helper.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/setting_header.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/settings_option_tile.dart';

class SetupNotificationsPage extends StatefulWidget {
  const SetupNotificationsPage({super.key});

  @override
  State<SetupNotificationsPage> createState() => _SetupNotificationsPageState();
}

class _SetupNotificationsPageState extends State<SetupNotificationsPage> {
  final options = [
    _SettingsOptionData(
      'Pop up notification',
      onTap: () {},
      showToggle: true,
      toggleValue: false,
      onToggle: (value) async {
        await SharedPrefsHelper().setBool('Pop up notification', value);
      },
    ),
    _SettingsOptionData(
      'Turn on all channel notification',
      onTap: () {},
      showToggle: true,
      toggleValue: false,
      onToggle: (value) async {
        await SharedPrefsHelper().setBool(
          'Turn on all channel notification',
          value,
        );
      },
    ),
    _SettingsOptionData(
      'Turn on product recommendations',
      onTap: () {},
      showToggle: true,
      toggleValue: false,
      onToggle: (value) async {
        await SharedPrefsHelper().setBool(
          'Turn on product recommendations',
          value,
        );
      },
    ),
    _SettingsOptionData(
      'Turn on all channel notification',
      onTap: () {},
      showToggle: true,
      toggleValue: false,
      onToggle: (value) async {
        await SharedPrefsHelper().setBool(
          'Turn on all channel notification',
          value,
        );
      },
    ),
    // _SettingsOptionData('Turn on all channel notification', onTap: () {}, showToggle: true),
    // _SettingsOptionData('Turn on all channel notification', onTap: () {}, showToggle: true),
    // _SettingsOptionData('Turn on all channel notification', onTap: () {}, showToggle: true),
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
                  if (option.showToggle) {
                    return FutureBuilder<bool?>(
                      future: SharedPrefsHelper().getBool(option.text),
                      builder: (context, snapshot) {
                        final toggleVal = snapshot.data ?? option.toggleValue;
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
