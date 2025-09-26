import 'package:flutter/material.dart';
import '../services/welcome_animation_service.dart';
import '../widgets/welcome_background_image.dart';
import '../widgets/welcome_content.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _contentSlideAnimation;
  late Animation<double> _contentFadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: WelcomeAnimationService.animationDuration,
      vsync: this,
    );

    _slideAnimation = WelcomeAnimationService.createSlideAnimation(_animationController);
    _fadeAnimation = WelcomeAnimationService.createFadeAnimation(_animationController);
    _contentSlideAnimation = WelcomeAnimationService.createContentSlideAnimation(_animationController);
    _contentFadeAnimation = WelcomeAnimationService.createContentFadeAnimation(_animationController);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Animated Bottom Positioned Image
            WelcomeBackgroundImage(
              slideAnimation: _slideAnimation,
              fadeAnimation: _fadeAnimation,
            ),

            // Animated Content above image
            WelcomeContent(
              slideAnimation: _contentSlideAnimation,
              fadeAnimation: _contentFadeAnimation,
            ),
          ],
        ),
      ),
    );
  }
}