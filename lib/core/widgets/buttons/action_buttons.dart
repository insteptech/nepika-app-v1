import 'package:flutter/material.dart';
import '../base/base_widgets.dart';
import '../mixins/widget_behaviors.dart';

/// Primary Button following Single Responsibility Principle (S)
/// Only responsible for displaying a primary styled button
class PrimaryButton extends BaseButton with ThemeAwareBehavior {
  const PrimaryButton({
    super.key,
    required super.text,
    super.onPressed,
    super.isDisabled = false,
    super.icon,
    super.width,
    super.height,
  });

  @override
  Widget buildButtonContent(BuildContext context) {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor ?? Colors.white),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }
    return Text(text);
  }

  @override
  ButtonStyle getButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? getPrimaryColor(context),
      foregroundColor: textColor ?? Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: isEnabled ? 2 : 0,
    );
  }
}

/// Secondary Button following Open/Closed Principle (O)
/// Extends BaseButton but changes styling behavior
class SecondaryButton extends BaseButton with ThemeAwareBehavior {
  const SecondaryButton({
    super.key,
    required super.text,
    super.onPressed,
    super.isDisabled = false,
    super.icon,
    super.width,
    super.height,
  });

  @override
  Widget buildButtonContent(BuildContext context) {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor ?? getPrimaryColor(context)),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }
    return Text(text);
  }

  @override
  ButtonStyle getButtonStyle(BuildContext context) {
    return OutlinedButton.styleFrom(
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor: textColor ?? getPrimaryColor(context),
      side: BorderSide(
        color: getPrimaryColor(context),
        width: 1.5,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: getButtonStyle(context),
        child: buildButtonContent(context),
      ),
    );
  }
}

/// Text Button for minimal actions
class TextActionButton extends BaseButton with ThemeAwareBehavior {
  const TextActionButton({
    super.key,
    required super.text,
    super.onPressed,
    super.isDisabled = false,
    super.icon,
    super.width,
    super.height,
  });

  @override
  Widget buildButtonContent(BuildContext context) {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(text),
        ],
      );
    }
    return Text(text);
  }

  @override
  ButtonStyle getButtonStyle(BuildContext context) {
    return TextButton.styleFrom(
      foregroundColor: textColor ?? getPrimaryColor(context),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: TextButton(
        onPressed: isEnabled ? onPressed : null,
        style: getButtonStyle(context),
        child: buildButtonContent(context),
      ),
    );
  }
}
