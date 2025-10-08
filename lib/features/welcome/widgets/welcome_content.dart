import 'package:flutter/material.dart';
import '../../../core/config/constants/theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/config/constants/routes.dart';
import 'welcome_logo.dart';

class WelcomeContent extends StatelessWidget {
  const WelcomeContent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Logo
          const WelcomeLogo(),
          const SizedBox(height: 20),

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
    );
  }
}