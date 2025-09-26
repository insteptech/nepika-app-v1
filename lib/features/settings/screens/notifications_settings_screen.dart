import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme_notifier.dart';
import 'package:nepika/core/utils/shared_prefs_helper.dart';
import 'package:nepika/features/dashboard/widgets/delete_account_dialog.dart';
import 'package:provider/provider.dart';

import '../components/settings_options_list.dart';
import '../models/settings_option_data.dart';
import '../widgets/settings_header.dart';
import 'setup_notifications_screen.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => 
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState 
    extends State<NotificationsSettingsScreen> {
  
  List<SettingsOptionData> _buildOptions(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return [
      SettingsOptionData.option(
        'Notification Settings',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SetupNotificationsScreen(),
            ),
          );
        },
      ),
      SettingsOptionData.option(
        'Notification History',
        onTap: () {
          // TODO: Implement notification history functionality
        },
      ),
      SettingsOptionData.option(
        'Settings',
        onTap: () {
          // TODO: Implement general settings functionality
        },
      ),
      SettingsOptionData.toggle(
        'Dark Mode',
        toggleValue: false,
        onToggle: (value) async {
          debugPrint('Dark Mode Toggled: $value');
          themeNotifier.toggleTheme(value);
          await SharedPrefsHelper().setBool('Dark Mode', value);
          setState(() {});
        },
      ),
      SettingsOptionData.option(
        'Version Info / About App',
        onTap: () {
          // TODO: Implement version info functionality
        },
      ),
      SettingsOptionData.option(
        'App Walkthrough / Tips',
        onTap: () {
          // TODO: Implement app walkthrough functionality
        },
      ),
      SettingsOptionData.option(
        'Delete Account',
        onTap: () {
          _showDeleteAccountDialog(context);
        },
      ),
    ];
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => DeleteAccountDialog(
        reasons: const [
          'Results don\'t match expectations',
          'Didn\'t see any improvement in my skin',
          'Advice or products didn\'t suit my skin',
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = _buildOptions(context);

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