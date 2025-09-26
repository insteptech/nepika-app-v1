import 'package:flutter/material.dart';

import '../components/settings_options_list.dart';
import '../models/settings_option_data.dart';
import '../widgets/settings_header.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  List<SettingsOptionData> _buildOptions(BuildContext context) {
    return [
      SettingsOptionData.option(
        'Help and Support',
        onTap: () {
          // TODO: Implement help and support functionality
        },
      ),
      SettingsOptionData.option(
        'FAQ',
        onTap: () {
          // TODO: Implement FAQ functionality
        },
      ),
      SettingsOptionData.option(
        'Live Chat or Contact Support',
        onTap: () {
          // TODO: Implement live chat functionality
        },
      ),
      SettingsOptionData.option(
        'Feedback / Rate Us Page',
        onTap: () {
          // TODO: Implement feedback functionality
        },
      ),
    ];
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
              title: 'Help and Support',
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