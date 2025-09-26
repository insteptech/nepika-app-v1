import 'package:flutter/material.dart';
import '../../../core/config/constants/assets.dart';

class WelcomeLogo extends StatelessWidget {
  const WelcomeLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
      ),
      padding: const EdgeInsets.all(10),
      height: 120,
      width: 120,
      child: Image.asset(
        AppAssets.appLogoStroke,
        height: 90,
        fit: BoxFit.contain,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}