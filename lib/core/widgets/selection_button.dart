import 'package:flutter/material.dart';

class SelectionButton extends StatelessWidget {
  final String text;
  final IconData? prefixIcon;
  final bool isSelected;
  final VoidCallback? onPressed;
  final String? prefixIconAsset;
  final EdgeInsetsGeometry? padding;

  const SelectionButton({
    super.key,
    required this.text,
    this.prefixIcon,
    this.isSelected = false,
    this.onPressed,
    this.prefixIconAsset,
    this.padding
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 48,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.6), width: 1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (prefixIcon != null || prefixIconAsset != null) ...[
                if (prefixIcon != null)
                  Icon(
                    prefixIcon,
                    color: isSelected
                        ? theme.colorScheme.surface
                        : theme.textTheme.bodyLarge?.color,
                    size: 20,
                  )
                else if (prefixIconAsset != null)
                  Image.asset(
                    prefixIconAsset!,
                    width: 16,
                    height: 16,
                    color: isSelected
                        ? theme.colorScheme.surface
                        : theme.textTheme.bodyLarge?.color,
                  ),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.surface
                      : theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}