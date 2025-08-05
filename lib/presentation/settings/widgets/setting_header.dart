import 'package:flutter/material.dart';
import 'package:nepika/core/widgets/back_button.dart';

class SettingHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;

  const SettingHeader({
    super.key,
    this.title = 'Settings',
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(
        children: [
          SizedBox(
            height: 32,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (showBackButton)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CustomBackButton(
                        onPressed: onBack ?? () => Navigator.of(context).pop(),
                      ),
                    ),
                  Center(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
        ],
      ),
    );
  }
}
