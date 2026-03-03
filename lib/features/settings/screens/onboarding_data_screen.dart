import 'package:flutter/material.dart';
import 'package:nepika/features/onboarding/screens/onboarding_screen.dart';

import 'package:nepika/features/onboarding/screens/skincare_professional_screen.dart';

import '../components/settings_options_list.dart';
import '../models/settings_option_data.dart';
import '../widgets/settings_header.dart';

class OnboardingDataScreen extends StatelessWidget {
  final bool isSkincareProfessional;

  const OnboardingDataScreen({super.key, this.isSkincareProfessional = false});

  // Mocked onboarding keys (replace later with real API data)
  final List<String> onboardingSections = const [
    "basic-info",
    "life-style",
    "skin-type",
    "cycle-details",
    "cycle-info",
    "menopause-details",
    "skin-goals-details",
  ];

  List<SettingsOptionData> _buildOptions(BuildContext context) {
    if (isSkincareProfessional) {
      return [
        SettingsOptionData.option(
          'Basic Info',
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder:
                    (context) => OnboardingScreen(
                      initialStep: 1,
                      isFromSettingNavigation: true,
                      customOnBack: () {
                        Navigator.of(context).pop();
                      },
                      mainButtonText: 'Update',
                      customShowSkip: false,
                      showProgressBar: false,
                    ),
              ),
            );
          },
        ),
        SettingsOptionData.option(
          'Professional Details',
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder:
                    (context) =>
                        const SkincareProfessionalScreen(isEditMode: true),
              ),
            );
          },
        ),
      ];
    }

    return onboardingSections
        .asMap()
        .entries
        .map(
          (entry) => SettingsOptionData.option(
            _formatSectionTitle(entry.value),
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder:
                      (context) => OnboardingScreen(
                        initialStep: entry.key + 1,
                        isFromSettingNavigation: true,
                        customOnBack: () {
                          Navigator.of(context).pop();
                        },
                        mainButtonText: 'Update',
                        customShowSkip: false,
                        showProgressBar: false,
                      ),
                ),
              );
            },
          ),
        )
        .toList();
  }

  static String _formatSectionTitle(String key) {
    // Convert snake/dash-case into title case
    return key
        .split(RegExp(r"[-_]"))
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(" ");
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
              title: 'Onboarding & Initial Data',
              showBackButton: true,
            ),
            SliverToBoxAdapter(child: SettingsOptionsList(options: options)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
