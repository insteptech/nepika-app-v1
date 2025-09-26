import 'package:flutter/material.dart';
import '../models/settings_option_data.dart';
import '../widgets/settings_option_tile.dart';

class SettingsOptionsList extends StatelessWidget {
  final List<SettingsOptionData> options;
  final EdgeInsetsGeometry? padding;

  const SettingsOptionsList({
    super.key,
    required this.options,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: options.map((option) {
        // Handle toggle options with FutureBuilder for persistent storage
        if (option.showToggle) {
          return _ToggleOptionTile(option: option);
        }
        
        // Handle regular options
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
      }).toList(),
    );
  }
}

class _ToggleOptionTile extends StatelessWidget {
  final SettingsOptionData option;

  const _ToggleOptionTile({
    required this.option,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsOptionTile(
      text: option.text,
      onTap: option.onTap,
      showToggle: true,
      toggleValue: option.toggleValue,
      onToggleChanged: option.onToggle,
      toggleStorageKey: option.text,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      textColor: Theme.of(context).textTheme.bodyLarge?.color,
      showDivider: false,
    );
  }
}