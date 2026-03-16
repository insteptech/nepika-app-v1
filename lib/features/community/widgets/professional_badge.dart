import 'package:flutter/material.dart';

class ProfessionalBadge extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry padding;

  const ProfessionalBadge({
    super.key,
    this.height = 16.0,
    this.padding = const EdgeInsets.only(left: 6.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 4.5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(4.0),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome, // Sparkle icon
              color: Colors.white,
              size: height * 0.55,
            ),
            const SizedBox(width: 2.5),
            Text(
              'PRO',
              style: TextStyle(
                color: Colors.white,
                fontSize: height * 0.65,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
