import 'package:flutter/material.dart';
import 'package:nepika/core/utils/shared_prefs_helper.dart';

import '../components/settings_options_list.dart';
import '../models/settings_option_data.dart';
import '../widgets/settings_header.dart';

class SetupNotificationsScreen extends StatefulWidget {
  const SetupNotificationsScreen({super.key});

  @override
  State<SetupNotificationsScreen> createState() => 
      _SetupNotificationsScreenState();
}

class _SetupNotificationsScreenState extends State<SetupNotificationsScreen> {
  
  List<SettingsOptionData> _buildOptions() {
    return [
      SettingsOptionData.toggle(
        'Pop up notification',
        toggleValue: false,
        onToggle: (value) async {
          await SharedPrefsHelper().setBool('Pop up notification', value);
        },
      ),
      SettingsOptionData.toggle(
        'Turn on all channel notification',
        toggleValue: false,
        onToggle: (value) async {
          await SharedPrefsHelper().setBool(
            'Turn on all channel notification',
            value,
          );
        },
      ),
      SettingsOptionData.toggle(
        'Turn on product recommendations',
        toggleValue: false,
        onToggle: (value) async {
          await SharedPrefsHelper().setBool(
            'Turn on product recommendations',
            value,
          );
        },
      ),
      // Note: The original had a duplicate option, preserving for compatibility
      SettingsOptionData.toggle(
        'Turn on all channel notification',
        toggleValue: false,
        onToggle: (value) async {
          await SharedPrefsHelper().setBool(
            'Turn on all channel notification',
            value,
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = _buildOptions();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SettingsHeader(
              title: 'Notifications & Settings',
              showBackButton: true,
            ),
            SliverToBoxAdapter(
              child: SettingsOptionsList(options: options),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}