import 'package:flutter/material.dart';
import '../models/settings_option_data.dart';
import 'settings_option_tile.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<SettingsOptionData> options;

  const SettingsSection({
    super.key,
    required this.title,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...options.map((option) {
          return SettingsOptionTile(
            text: option.text,
            onTap: option.onTap,
            rightIcon: Image.asset(
              'assets/icons/chevron_right.png',
              width: 14,
              height: 14,
              color: theme.dividerColor,
            ),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            textColor: option.textColor ?? theme.textTheme.bodyLarge?.color,
            showDivider: false,
          );
        }),
      ],
    );
  }
}
