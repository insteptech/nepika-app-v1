import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/feature_suggestion_dialog.dart';
import 'package:nepika/presentation/settings/widgets/setting_header.dart';
import 'package:nepika/presentation/settings/widgets/settings_option_tile.dart';

class CommunityAndEngagement extends StatefulWidget {
  const CommunityAndEngagement({super.key});

  @override
  State<CommunityAndEngagement> createState() =>
      _CommunityAndEngagementState();
}

class _CommunityAndEngagementState extends State<CommunityAndEngagement> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final options = [
      _SettingsOptionData('Community Data Results', onTap: () {}),
      _SettingsOptionData('Forum Home', onTap: () {}),
      _SettingsOptionData('Forum Thread View', onTap: () {}),
      _SettingsOptionData(
        'Suggest a Feature Form',
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => const FeatureSuggestionDialog(),
          );
        },
      ),
    ];


    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            SettingHeader(
              title: 'Community & Engagement',
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
