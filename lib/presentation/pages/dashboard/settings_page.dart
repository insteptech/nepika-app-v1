import 'package:flutter/material.dart';
import 'package:nepika/core/constants/routes.dart';
import 'package:nepika/core/constants/theme.dart';
import 'package:nepika/presentation/pages/dashboard/components/settings/community_and_engagement_page.dart';
import 'package:nepika/presentation/pages/dashboard/components/settings/help_and_support_page.dart';
import 'package:nepika/presentation/pages/dashboard/components/settings/notifications_and_settings_page.dart';
import 'package:nepika/presentation/pages/dashboard/products_page.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/setting_header.dart';
import 'package:nepika/presentation/pages/terms_and_policy/terms_of_use_page.dart';
import 'widgets/settings_option_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final options = [
      _SettingsOptionData(
        'My Products',
        onTap: () {
          Navigator.of(
            context,
          ).pushNamed(AppRoutes.dashboardAllProducts);
        },
      ),
      _SettingsOptionData(
        'Community & Engagement',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CommunityAndEngagement()),
          );
        },
      ),
      _SettingsOptionData(
        'Notifications & Settings',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsAndSettings()),
          );
        },
      ),
      _SettingsOptionData(
        'Help and Support',
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const HelpAndSupport()));
        },
      ),
      _SettingsOptionData(
        'Terms of use',
        onTap: () {
          Navigator.of(
            context,
            rootNavigator: true,
          ).push(MaterialPageRoute(builder: (_) => const TermsOfUsePage()));
        },
      ),
      _SettingsOptionData(
        'Privacy Policy',
        onTap: () {
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed(AppRoutes.privacyPolicy);
        },
      ),
      _SettingsOptionData(
        'Subscription & Payment',
        onTap: () {
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed(AppRoutes.subscription);
        },
      ),
    ];

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingHeader(title: 'Settings'),

            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  return SettingsOptionTile(
                    text: option.text,
                    onTap: option.onTap,
                    rightIcon: Image.asset(
                      'assets/icons/chevron_right.png',
                      width: 14,
                      height: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    textColor: colorScheme.onSurface,
                    showDivider: false,
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Dialog(
                            insetPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 32,
                                horizontal: 24,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Are you sure you\nwant to log out?',
                                    textAlign: TextAlign.center,
                                    style: textTheme.displaySmall,
                                  ),
                                  const SizedBox(height: 30),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            Navigator.of(
                                              context,
                                              rootNavigator: true,
                                            ).pushNamedAndRemoveUntil(
                                              AppRoutes.welcome,
                                              (route) => false,
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            side: BorderSide(
                                              color: colorScheme.primary,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            'Yes',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge!
                                                .hint(context),
                                          ),
                                        ),
                                      ),

                                      SizedBox(width: 20),
                                      // No Button
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            side: BorderSide(
                                              color: colorScheme.primary,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            'No',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge!
                                                .hint(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },

                    child: Text(
                      'Log Out',
                      style: textTheme.headlineMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                  Text(
                    'Version 1.4.0',
                    style: textTheme.bodyLarge!.secondary(context),
                  ),
                ],
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
  _SettingsOptionData(this.text, {this.onTap});
}
