import 'package:flutter/material.dart';

/// Data model for settings options used throughout the settings feature.
/// Supports both regular options and toggle options with consistent interface.
class SettingsOptionData {
  final String text;
  final VoidCallback? onTap;
  final bool showToggle;
  final bool toggleValue;
  final ValueChanged<bool>? onToggle;
  final Color? textColor;

  const SettingsOptionData(
    this.text, {
    this.onTap,
    this.showToggle = false,
    this.toggleValue = false,
    this.onToggle,
    this.textColor,
  });

  /// Creates a regular option without toggle functionality
  const SettingsOptionData.option(
    this.text, {
    required this.onTap,
    this.textColor,
  })  : showToggle = false,
        toggleValue = false,
        onToggle = null;

  /// Creates a toggle option with switch functionality
  const SettingsOptionData.toggle(
    this.text, {
    this.toggleValue = false,
    required this.onToggle,
    this.textColor,
  })  : showToggle = true,
        onTap = null;

  /// Creates a combined option that supports both tap and toggle
  const SettingsOptionData.combined(
    this.text, {
    this.onTap,
    this.toggleValue = false,
    this.onToggle,
    this.textColor,
  }) : showToggle = true;
}