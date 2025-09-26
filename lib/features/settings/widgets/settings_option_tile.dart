import 'dart:math';
import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/utils/shared_prefs_helper.dart';
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

  // Storage
  final String? toggleStorageKey;

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
    this.toggleStorageKey,
  });

  @override
  State<SettingsOptionTile> createState() => _SettingsOptionTileState();
}

class _SettingsOptionTileState extends State<SettingsOptionTile> {
  bool? _localToggleValue;

  String get _transformedKey {
    final baseKey = widget.toggleStorageKey ?? widget.text;
    final random = Random().nextInt(9000) + 1000;
    return '${baseKey.trim().toLowerCase().replaceAll(' ', '-')}-$random';
  }

  String? _persistentKey;

  @override
  void initState() {
    super.initState();
    _initToggleValue();
  }

  Future<void> _initToggleValue() async {
    if (widget.showToggle && widget.toggleStorageKey != null) {
      final transformedKey = _transformedKey;
      _persistentKey = transformedKey;
      final storedValue = await SharedPrefsHelper().getBool(transformedKey);
      if (mounted) {
        final bool initialValue;
        if (storedValue) {
          initialValue = storedValue;
        } else {
          initialValue = widget.toggleValue ?? false;
          // Save initial value since it doesn't exist in storage
          await SharedPrefsHelper().setBool(transformedKey, initialValue);
        }
        setState(() {
          _localToggleValue = initialValue;
        });
      }
    } else {
      _localToggleValue = widget.toggleValue ?? false;
    }
  }

  Future<void> _handleToggleChange(bool value) async {
    setState(() {
      _localToggleValue = value;
    });

    // Save to shared preferences if storage key exists
    if (_persistentKey != null) {
      await SharedPrefsHelper().setBool(_persistentKey!, value);
    }

    widget.onToggleChanged?.call(value);
  }

  @override
  void didUpdateWidget(covariant SettingsOptionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.toggleValue != oldWidget.toggleValue) {
      _localToggleValue = widget.toggleValue;
    }
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
              padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.text,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  if (widget.showToggle)
                    ToggleSwitch(
                      value: _localToggleValue ?? false,
                      onChanged: _handleToggleChange,
                    )
                  else
                    widget.rightIcon ??
                        Image.asset(
                          'assets/icons/chevron_right.png',
                          width: 14,
                          height: 14,
                          color: Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .secondary(context)
                              .color,
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