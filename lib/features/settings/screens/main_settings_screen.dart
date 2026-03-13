import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/core/di/injection_container.dart' as di;
import 'package:nepika/features/reminders/bloc/reminder_bloc.dart';
import 'package:nepika/features/settings/bloc/delete_account_bloc.dart';
import 'package:nepika/features/settings/components/delete_account_dialog.dart';
import 'package:nepika/features/settings/screens/onboarding_data_screen.dart';
import 'package:nepika/features/dashboard/screens/set_reminder_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:nepika/core/utils/shared_prefs_helper.dart';

import '../components/logout_dialog.dart';
// import '../components/delete_account_dialog.dart';
import '../components/settings_options_list.dart';
import '../models/settings_option_data.dart';
import '../widgets/settings_header.dart';
import '../widgets/settings_section.dart';
// import '../bloc/delete_account_bloc.dart';
import 'community_settings_screen.dart';
import 'help_support_screen.dart';
import 'notifications_settings_screen.dart';
import '../../community/screens/edit_profile_screen.dart';
import '../../../domain/community/repositories/community_repository.dart';
import '../../community/bloc/blocs/profile_bloc.dart';
import 'update_mobile_number_screen.dart';
import 'package:nepika/core/services/unified_fcm_service.dart';

class MainSettingsScreen extends StatefulWidget {
  const MainSettingsScreen({super.key});

  @override
  State<MainSettingsScreen> createState() => _MainSettingsScreenState();
}

class _MainSettingsScreenState extends State<MainSettingsScreen> {
  bool _isProfessional = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      setState(() {
        _isProfessional = SharedPrefsHelper().isSkincareProfessionalSync();
      });
    } catch (e) {
      debugPrint('Error loading user role in settings: $e');
    }
  }
  Future<void> _logout(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Capture navigator reference before async gap to prevent 'deactivated widget' errors
    final navigator = Navigator.of(context, rootNavigator: true);

    try {
      // Clear FCM token first to stop notifications
      await UnifiedFcmService.instance.logout();

      final sharedPrefs = await SharedPreferences.getInstance();

      // Clear all authentication data
      await sharedPrefs.remove(AppConstants.accessTokenKey);
      await sharedPrefs.remove(AppConstants.refreshTokenKey);
      await sharedPrefs.remove(AppConstants.userTokenKey);
      await sharedPrefs.remove(AppConstants.userDataKey);
      await sharedPrefs.remove(AppConstants.onboardingKey);
      // Clear subscription cache so next user doesn't see stale badge
      await sharedPrefs.remove('cached_subscription_plan');

      // Navigate to welcome screen and clear navigation stack
      // Use the captured navigator
      navigator.pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
    } catch (e) {
      // Even on error, force logout navigation
      navigator.pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LogoutDialog(onConfirm: () => _logout(context)),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    try {
      // Ensure services are initialized
      await di.ServiceLocator.init();

      // Test if the service is available
      di.ServiceLocator.get<DeleteAccountBloc>();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => const DeleteAccountConfirmationDialog(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Delete account service not available: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SettingsHeader(title: 'Settings', showBackButton: true),

            // Profile Section
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'PROFILE',
                options: [
                  SettingsOptionData.option(
                    'Edit Profile',
                    onTap: () async {
                      try {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder:
                              (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                        );

                        final sharedPrefs =
                            await SharedPreferences.getInstance();
                        final token = sharedPrefs.getString(
                          AppConstants.accessTokenKey,
                        );
                        final userDataStr = sharedPrefs.getString(
                          AppConstants.userDataKey,
                        );

                        // Parse userId from stored user data if possible, or handle otherwise
                        String? userId;
                        // Note: AppConstants.userDataKey usually stores JSON.
                        // We might need to fetch the user ID from the token or stored data.
                        // Assuming we can get the profile just with the token if the repo supports 'me'
                        // or we interpret the token.
                        // Actually CommunityRepository.getUserProfile requires userId.
                        // Let's try to get it from local storage.

                        if (token != null && userDataStr != null) {
                          // Quick parsing of user data specific to this app structure
                          // This part depends on how UserData is stored.
                          // Let's assume standard extraction or fetch "my profile"

                          // Option B: Fetch "my" profile if repository supports it.
                          // The repository method is getUserProfile(token, userId).

                          // Using a workaround: The repository in this app usually requires a user ID.
                          // Let's try to find where we can get the current user ID.
                          // Usually it's in AppConstants.userDataKey decoded JSON 'id'.

                          // Simpler approach: Verify if we can just navigate to UserProfileScreen?
                          // No, user specifically asked for Edit Profile.

                          // Let's assume we can get ID from sharedPrefs.
                          // For now, I'll attempt to parse specific ID logic or use a known pattern.

                          // Actually, let's look at `_logout` it clears AppConstants.userTokenKey.
                          // Is there a helper class for UserData?
                          // Let's rely on `CommunityRepository` fetching the profile.

                          // Assuming we have to verify the user ID first.
                          // I will peek at `UserProfileScreen` again to see how it gets ID.
                          // It gets it from `_initializeData`.

                          // Let's just implement dynamic retrieval here.

                          // Only proceed if context mounted after async
                          if (!context.mounted) return;

                          // Get repo
                          final repo =
                              di.ServiceLocator.get<CommunityRepository>();

                          // We need user ID.
                          // For this implementation, let's fetch 'my' profile if possible or extract ID.
                          // Let's assume we can pass the userId if we parse it.

                          // Temporarily assuming we can invoke a "fetch my profile" or similar logic?
                          // CommunityRepository doesn't usually have "fetchMyProfile" without ID.
                          // Wait, `ProfileBloc` handles `FetchMyProfile`?
                          // Let's check `ProfileBloc`.

                          // If `ProfileBloc` exists, we can use it.
                          // But we are in Settings.

                          // Let's use `CommunityNavigation` helper if it exists for this?
                          // No.

                          // Let's parse the UserData string to get ID.
                          final regExp = RegExp(r'"id"\s*:\s*"([^"]+)"');
                          final match = regExp.firstMatch(userDataStr);
                          userId = match?.group(1);

                          if (userId != null) {
                            final profile = await repo.getUserProfile(
                              token: token,
                              userId: userId,
                            );

                            if (context.mounted) {
                              // Hide loading
                              Navigator.of(context, rootNavigator: true).pop();

                              // Navigate to Edit Profile
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => BlocProvider.value(
                                        value:
                                            di.ServiceLocator.get<
                                              ProfileBloc
                                            >(),
                                        child: EditProfileScreen(
                                          token: token,
                                          currentUsername: profile.username,
                                          currentBio: profile.bio,
                                          currentProfileImage:
                                              profile.profileImageUrl,
                                        ),
                                      ),
                                ),
                              );

                              if (result != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Profile updated successfully!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          } else {
                            throw Exception("User ID not found");
                          }
                        } else {
                          throw Exception("Not authenticated");
                        }
                      } catch (e) {
                        if (context.mounted) {
                          // Hide loading if showing (might need better logic)
                          // Currently this assumes the dialog is top.
                          Navigator.of(context, rootNavigator: true).maybePop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'ONBOARDING DATA',
                options: [
                  SettingsOptionData.option(
                    'Update Onboarding Data',
                    onTap: () async {
                      // Show loading while we fetch from SharedPreferences
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder:
                            (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                      );

                      bool isProfessional = false;
                      try {
                        final sharedPrefs =
                            await SharedPreferences.getInstance();
                        final userDataStr = sharedPrefs.getString(
                          AppConstants.userDataKey,
                        );
                        if (userDataStr != null) {
                          final Map<String, dynamic> userData = jsonDecode(
                            userDataStr,
                          );
                          isProfessional =
                              userData['is_skincare_professional'] == true;
                        }
                      } catch (e) {
                        debugPrint('Error reading user data: $e');
                      }

                      if (context.mounted) {
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pop(); // dismiss loading
                        Navigator.of(context, rootNavigator: false).push(
                          MaterialPageRoute(
                            builder:
                                (_) => OnboardingDataScreen(
                                  isSkincareProfessional: isProfessional,
                                ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            // Community Section
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'COMMUNITY',
                options: [
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
                ],
              ),
            ),

            // Notifications & Reminders Section
            SliverToBoxAdapter(
              child: SettingsSection(
                title: _isProfessional ? 'NOTIFICATIONS' : 'NOTIFICATIONS AND REMINDERS',
                options: [
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
                  if (!_isProfessional)
                    SettingsOptionData.option(
                      'Reminders',
                      onTap: () {
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushNamed(AppRoutes.dashboardScheduledReminders);
                      },
                    ),
                ],
              ),
            ),

            // Subscription Section
            if (!_isProfessional)
              SliverToBoxAdapter(
                child: SettingsSection(
                  title: 'SUBSCRIPTION',
                  options: [
                    SettingsOptionData.option(
                      'Subscription & Payment',
                      onTap: () {
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushNamed(AppRoutes.subscription);
                      },
                    ),
                  ],
                ),
              ),

            // Info Section
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'INFO',
                options: [
                  if (!_isProfessional)
                    SettingsOptionData.option(
                      'Face Scan Info',
                      onTap: () {
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushNamed(AppRoutes.faceScanInfo);
                      },
                    ),
                  SettingsOptionData.option(
                    'Help and Support',
                    onTap: () {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(AppRoutes.helpAndSupport);
                    },
                  ),
                  SettingsOptionData.option(
                    'Terms of use',
                    onTap: () {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(AppRoutes.termsOfUse);
                    },
                  ),
                  SettingsOptionData.option(
                    'Privacy Policy',
                    onTap: () {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(AppRoutes.privacyPolicy);
                    },
                  ),
                  SettingsOptionData.option(
                    'FAQ',
                    onTap: () {
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(AppRoutes.faq);
                    },
                  ),
                  SettingsOptionData.option(
                    'Feedback',
                    onTap: () async {
                      await Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(AppRoutes.feedback);
                    },
                  ),
                ],
              ),
            ),

            // Account Section
            SliverToBoxAdapter(
              child: SettingsSection(
                title: 'ACCOUNT',
                options: [
                  SettingsOptionData.option(
                    'Update Mobile Number',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UpdateMobileNumberScreen(),
                        ),
                      );
                    },
                  ),
                  SettingsOptionData.option(
                    'Delete Account',
                    onTap: () => _showDeleteAccountDialog(context),
                    textColor: Colors.red,
                  ),
                ],
              ),
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
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Small delay to ensure init
      final packageInfo = await PackageInfo.fromPlatform();
      debugPrint('PackageInfo - Version: ${packageInfo.version}');
      debugPrint('PackageInfo - BuildNumber: ${packageInfo.buildNumber}');
      debugPrint('PackageInfo - AppName: ${packageInfo.appName}');
      debugPrint('PackageInfo - PackageName: ${packageInfo.packageName}');

      if (mounted) {
        // Check if the values are empty or null
        final version =
            packageInfo.version.isNotEmpty ? packageInfo.version : '1.0.0';
        final buildNumber =
            packageInfo.buildNumber.isNotEmpty ? packageInfo.buildNumber : '1';

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
