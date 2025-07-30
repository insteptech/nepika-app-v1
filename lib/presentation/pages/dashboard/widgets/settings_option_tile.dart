import 'package:flutter/material.dart';
import 'package:nepika/core/constants/theme.dart';
import 'package:nepika/core/widgets/toggle_switch.dart';

class SettingsOptionTile extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final Widget? rightIcon;
  final Color? textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool showDivider;

  // Toggle parameters
  final bool showToggle;
  final bool? toggleValue;
  final ValueChanged<bool>? onToggleChanged;

  const SettingsOptionTile({
    super.key,
    required this.text,
    this.onTap,
    this.rightIcon,
    this.textColor,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w400,
    this.padding,
    this.backgroundColor,
    this.showDivider = true,
    this.showToggle = false,
    this.toggleValue,
    this.onToggleChanged,
  });

  @override
  State<SettingsOptionTile> createState() => _SettingsOptionTileState();
}

class _SettingsOptionTileState extends State<SettingsOptionTile> {
  bool? _localToggleValue;

  @override
  void initState() {
    super.initState();
    _localToggleValue = widget.toggleValue;
  }

  @override
  void didUpdateWidget(SettingsOptionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.toggleValue != oldWidget.toggleValue) {
      _localToggleValue = widget.toggleValue;
    }
  }

  void _handleToggleChange(bool value) {
    setState(() {
      _localToggleValue = value;
    });

    // Call parent callback if provided
    widget.onToggleChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: widget.backgroundColor ?? Colors.transparent,
          child: InkWell(
            onTap: widget.showToggle ? null : widget.onTap,
            child: Container(
              height: 55,
              padding:
                  widget.padding ?? const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.text,
                      style: Theme.of(context).textTheme.headlineMedium
                    ),
                  ),
                  if (widget.showToggle)
                  ToggleSwitch(
                    value: _localToggleValue ?? false,
                    onChanged: _handleToggleChange,
                  )
                  // else if (widget.onTap != null
                  // )
                    // Switch(
                    //   value: _localToggleValue ?? false,
                    //   onChanged: _handleToggleChange,
                    // )
                  else
                    widget.rightIcon ??
                        Image.asset(
                          'assets/icons/chevron_right.png',
                          width: 14,
                          height: 14,
                          color: Theme.of(context).textTheme.headlineMedium!.secondary(context).color
                        ),
                ],
              ),
            ),
          ),
        ),
        if (widget.showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).dividerColor,
            ),
          ),
      ],
    );
  }
}

// Example usage
class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Regular tile
        SettingsOptionTile(
          text: 'Profile Settings',
          onTap: () {
            // Navigate to profile
          },
        ),

        // Toggle tile with parent sync
        SettingsOptionTile(
          text: 'Notifications',
          showToggle: true,
          toggleValue: notificationsEnabled,
          onToggleChanged: (value) {
            setState(() {
              notificationsEnabled = value;
            });
            print('Notifications: $value');
            // Do something with the value
          },
        ),

        SettingsOptionTile(
          text: 'Dark Mode',
          showToggle: true,
          toggleValue: darkModeEnabled,
          onToggleChanged: (value) {
            setState(() {
              darkModeEnabled = value;
            });
            print('Dark Mode: $value');
          },
        ),

        // Toggle tile without parent callback (local only)
        SettingsOptionTile(
          text: 'Local Setting',
          showToggle: true,
          toggleValue: false,
          // No onToggleChanged - will work locally only
        ),
      ],
    );
  }
}
