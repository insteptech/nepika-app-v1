import 'package:flutter/material.dart';
import '../../../core/config/constants/assets.dart';

class WelcomeBackgroundImage extends StatelessWidget {
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;

  const WelcomeBackgroundImage({
    super.key,
    required this.slideAnimation,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: slideAnimation,
        builder: (context, child) {
          final imageHeight = MediaQuery.of(context).size.height * 0.45;
          final animationOffset = slideAnimation.value.dy * (imageHeight * 0.5);

          return Transform.translate(
            offset: Offset(0, -animationOffset),
            child: FadeTransition(
              opacity: fadeAnimation,
              child: Container(
                height: imageHeight,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  image: DecorationImage(
                    image: AssetImage(AppAssets.onboardingGirlImage),
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}