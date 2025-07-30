import 'package:flutter/material.dart';
import 'package:nepika/core/constants/theme.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final Color? textColor;
  final Color? iconColor;
  final double? fontSize;
  final double? iconSize;

  const CustomBackButton({
    super.key,
    this.onPressed,
    this.label = 'Back',
    this.textColor,
    this.iconColor,
    this.fontSize = 16,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8), // Optional ripple border
        onTap: onPressed ?? () => Navigator.of(context).pop(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back,
                size: iconSize,
                color: iconColor ?? Theme.of(context).textTheme.headlineMedium!.secondary(context).color,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize ?? Theme.of(context).textTheme.headlineMedium?.fontSize,
                  color: textColor ?? Theme.of(context).textTheme.headlineMedium!.secondary(context).color,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
