import 'package:flutter/material.dart';
import 'package:nepika/core/constants/theme.dart';
import 'back_button.dart';
import '../../presentation/pages/first_scan/face_scan_page.dart';

class QuestionHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final bool showBackButton;
  final bool showSkipButton;
  final bool showOnlyCurrentStep; // New prop

  const QuestionHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.onBack,
    this.onSkip,
    this.showBackButton = true,
    this.showSkipButton = true,
    this.showOnlyCurrentStep = true, 
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showBackButton)
                  CustomBackButton(
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  )
                else
                  const SizedBox(width: 60),

                if (showSkipButton)
                  GestureDetector(
                    onTap: () {
                      if (onSkip != null) {
                        onSkip!();
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const FaceScanPage(),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Skip',
                      style: Theme.of(context).textTheme.headlineMedium!.secondary(context),
                    ),
                  )
                else
                  const SizedBox(width: 60),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            Row(
              children: List.generate(totalSteps, (index) {
                final isActive = showOnlyCurrentStep
                    ? index == currentStep - 1
                    : index < currentStep;

                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(
                      right: index < totalSteps - 1 ? 8 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
