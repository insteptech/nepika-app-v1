import 'package:flutter/material.dart';
import 'package:nepika/core/constants/theme.dart';
import '../../../core/constants/routes.dart';
import '../../../core/constants/assets.dart';
import '../../../core/widgets/custom_button.dart';

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
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(
            0.0,
            -1.0,
          ),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _contentSlideAnimation =
        Tween<Offset>(
          begin: const Offset(0.0, -0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Animated Bottom Positioned Image
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final imageHeight = MediaQuery.of(context).size.height * 0.45;
                  final animationOffset =
                      _slideAnimation.value.dy *
                      (imageHeight * 0.5); // 50% of image height

                  return Transform.translate(
                    offset: Offset(
                      0,
                      -animationOffset,
                    ), // Negative because we're moving up from below
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        height: imageHeight,
                        decoration: BoxDecoration(
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
            ),

            // Animated Content above image
            SlideTransition(
              position: _contentSlideAnimation,
              child: FadeTransition(
                opacity: _contentFadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // Logo
                      Image.asset(
                        AppAssets.nepikaLogoShadow,
                        height: 200,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 0),

                      // Main Title
                      Text(
                        'What is your Nepika',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 28,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Subtitle
                      Text(
                        'Your personal skincare assistant to\nachieve healthier, glowing skin',
                        style: Theme.of(context).textTheme.headlineMedium!.secondary(context),
                        textAlign: TextAlign.center,
                      ),

                      const Spacer(),

                      // Get Started Button
                      CustomButton(
                        text: 'Get Started',
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRoutes.phoneEntry);
                        },
                        type: ButtonType.primary,
                        size: ButtonSize.large,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
