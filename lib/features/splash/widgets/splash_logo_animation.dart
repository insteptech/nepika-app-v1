import 'package:flutter/material.dart';
import '../../../core/config/constants/assets.dart';
import '../../../core/utils/theme_helper.dart';

class SplashLogoAnimation extends StatefulWidget {
  const SplashLogoAnimation({super.key});

  @override
  State<SplashLogoAnimation> createState() => _SplashLogoAnimationState();
}

class _SplashLogoAnimationState extends State<SplashLogoAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500), // Reduced from 2000ms to 1500ms
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart), // Faster, smoother curve
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut), // Slightly longer opacity animation
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: 150,
              height: 150,
              child: Center(
                child: ClipOval(
                  child: Image.asset(
                    AppAssets.appLogoStroke,
                    fit: BoxFit.contain,
                    cacheWidth: 150, // Cache at exact display size for memory efficiency
                    cacheHeight: 150,
                    color: ThemeHelper.isDarkMode(context) 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}