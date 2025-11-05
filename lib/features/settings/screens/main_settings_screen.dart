import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/core/di/injection_container.dart' as di;
import 'package:nepika/features/reminders/bloc/reminder_bloc.dart';
import 'package:nepika/features/settings/screens/onboarding_data_screen.dart';
import 'package:nepika/features/dashboard/screens/set_reminder_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../components/logout_dialog.dart';
import '../components/settings_options_list.dart';
import '../models/settings_option_data.dart';
import '../widgets/settings_header.dart';
import 'community_settings_screen.dart';
import 'help_support_screen.dart';
import 'notifications_settings_screen.dart';
import 'terms_of_use_screen.dart';
import 'privacy_policy_screen.dart';

class MainSettingsScreen extends StatelessWidget {
  const MainSettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();

      // Clear all authentication data
      await sharedPrefs.remove(AppConstants.accessTokenKey);
      await sharedPrefs.remove(AppConstants.refreshTokenKey);
      await sharedPrefs.remove(AppConstants.userTokenKey);
      await sharedPrefs.remove(AppConstants.userDataKey);
      await sharedPrefs.remove(AppConstants.onboardingKey);

      // Navigate to welcome screen and clear navigation stack
      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamedAndRemoveUntil(
          AppRoutes.welcome,
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamedAndRemoveUntil(
          AppRoutes.welcome,
          (route) => false,
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LogoutDialog(
        onConfirm: () => _logout(context),
      ),
    );
  }

  List<SettingsOptionData> _buildSettingsOptions(BuildContext context) {
    return [
      // SettingsOptionData.option(
      //   'My Products',
      //   onTap: () {
      //     Navigator.of(context).pushNamed(AppRoutes.dashboardAllProducts);
      //   },
      // ),
      SettingsOptionData.option(
        'Community & Engagement',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CommunitySettingsScreen(),
            ),
          );
        },
      ),
      SettingsOptionData.option(
        'Update Onboarding Data',
        onTap: () {
          Navigator.of(
            context,
            rootNavigator: false,
          ).push(MaterialPageRoute(builder: (_) => const OnboardingDataScreen()));
        },
      ),
      SettingsOptionData.option(
        'Notifications & Settings',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const NotificationsSettingsScreen(),
            ),
          );
        },
      ),
      SettingsOptionData.option(
        'Reminders',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (context) => di.ServiceLocator.get<ReminderBloc>(),
                child: const ReminderSettings(),
              ),
            ),
          );
        },
      ),
      SettingsOptionData.option(
        'Help and Support',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
          );
        },
      ),
      SettingsOptionData.option(
        'Terms of use',
        onTap: () {
          Navigator.of(
            context,
            rootNavigator: true,
          ).push(MaterialPageRoute(builder: (_) => const TermsOfUseScreen()));
        },
      ),
      SettingsOptionData.option(
        'Privacy Policy',
        onTap: () {
          Navigator.of(
            context,
            rootNavigator: true,
          ).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
        },
      ),
      SettingsOptionData.option(
        'Subscription & Payment',
        onTap: () {
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed(AppRoutes.subscription);
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final options = _buildSettingsOptions(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SettingsHeader(title: 'Settings'),
            SliverToBoxAdapter(
              child: SettingsOptionsList(options: options),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _BottomSection(
                  onLogoutTap: () => _showLogoutDialog(context),
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSection extends StatefulWidget {
  final VoidCallback onLogoutTap;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _BottomSection({
    required this.onLogoutTap,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  State<_BottomSection> createState() => _BottomSectionState();
}

class _BottomSectionState extends State<_BottomSection> {
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Small delay to ensure init
      final packageInfo = await PackageInfo.fromPlatform();
      debugPrint('PackageInfo - Version: ${packageInfo.version}');
      debugPrint('PackageInfo - BuildNumber: ${packageInfo.buildNumber}');
      debugPrint('PackageInfo - AppName: ${packageInfo.appName}');
      debugPrint('PackageInfo - PackageName: ${packageInfo.packageName}');
      
      if (mounted) {
        // Check if the values are empty or null
        final version = packageInfo.version.isNotEmpty ? packageInfo.version : '1.0.0';
        final buildNumber = packageInfo.buildNumber.isNotEmpty ? packageInfo.buildNumber : '1';
        
        setState(() {
          _version = 'Version $version ($buildNumber)';
        });
        debugPrint('Final version string: $_version');
      }
    } catch (e) {
      debugPrint('Error loading package info: $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (mounted) {
        setState(() {
          _version = 'Version 1.0.0 (1)';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: widget.onLogoutTap,
            child: Text(
              'Log Out',
              style: widget.textTheme.headlineMedium?.copyWith(
                color: widget.colorScheme.error,
              ),
            ),
          ),
          Text(
            _version,
            style: widget.textTheme.bodyLarge?.copyWith(
              color: widget.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}