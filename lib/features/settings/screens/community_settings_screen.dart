import 'package:flutter/material.dart';
import 'package:nepika/features/dashboard/widgets/feature_suggestion_dialog.dart';

import '../components/settings_options_list.dart';
import '../models/settings_option_data.dart';
import '../widgets/settings_header.dart';

class CommunitySettingsScreen extends StatelessWidget {
  const CommunitySettingsScreen({super.key});

  List<SettingsOptionData> _buildOptions(BuildContext context) {
    return [
      SettingsOptionData.option(
        'Community Data Results',
        onTap: () {
          // TODO: Implement community data results functionality
        },
      ),
      SettingsOptionData.option(
        'Forum Home',
        onTap: () {
          // TODO: Implement forum home functionality
        },
      ),
      SettingsOptionData.option(
        'Forum Thread View',
        onTap: () {
          // TODO: Implement forum thread view functionality
        },
      ),
      SettingsOptionData.option(
        'Suggest a Feature Form',
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => const FeatureSuggestionDialog(),
          );
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
              title: 'Community & Engagement',
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