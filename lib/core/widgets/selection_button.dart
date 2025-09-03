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
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final double minPadding = screenWidth * 0.01;
    final double maxPadding = 20.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double idealPadding =
            ((constraints.maxWidth - _estimateContentWidth(context)) / 2)
                .clamp(minPadding, maxPadding);

        return SizedBox(
          height: 44,
          child: GestureDetector(
            onTap: onPressed,
            child: Container(
              padding: padding ??
                  EdgeInsets.symmetric(
                    horizontal: idealPadding,
                  ),
              decoration: BoxDecoration(
                color:
                    isSelected ? theme.colorScheme.primary : Colors.transparent,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  width: 1,
                ),
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
                            ? theme.colorScheme.onSecondary
                            : theme.textTheme.bodyLarge?.color,
                        size: 20,
                      )
                    else if (prefixIconAsset != null)
                      Image.asset(
                        prefixIconAsset!,
                        width: 16,
                        height: 16,
                        color: isSelected
                            ? theme.colorScheme.onSecondary
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 13,
                      overflow: TextOverflow.ellipsis,
                      color: isSelected
                          ? theme.colorScheme.onSecondary
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _estimateContentWidth(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    double iconWidth = 0;
    if (prefixIcon != null || prefixIconAsset != null) {
      iconWidth += 16 + 8; // icon + spacing
    }

    return textPainter.width + iconWidth;
  }
}
