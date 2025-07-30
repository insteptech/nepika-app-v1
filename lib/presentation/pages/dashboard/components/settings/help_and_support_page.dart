import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/setting_header.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/settings_option_tile.dart';

class HelpAndSupport extends StatefulWidget {
  const HelpAndSupport({super.key});

  @override
  State<HelpAndSupport> createState() =>
      _HelpAndSupportState();
}

class _HelpAndSupportState extends State<HelpAndSupport> {
  final options = [
    _SettingsOptionData('Help and Support', onTap: () {}),
    _SettingsOptionData('FAQ', onTap: () {}),
    _SettingsOptionData('Live Chat or Contact Support', onTap: () {}),
    _SettingsOptionData('Feedback / Rate Us Page', onTap: () {}),
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
              title: 'Help and Support',
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
