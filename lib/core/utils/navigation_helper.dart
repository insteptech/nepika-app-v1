// import 'package:flutter/material.dart';
// import '../constants/onboarding_steps.dart';
// import '../constants/routes.dart';
// import '../../domain/auth/entities/user.dart';

// class NavigationHelper {
//   static void navigateAfterOtpVerification(
//     BuildContext context,
//     AuthResponse authResponse,
//   ) {
//     final user = authResponse.user;
//     debugPrint('User data after OTP verification:');
//     debugPrint(authResponse.user.activeStep);
    
//     if (user.onboardingCompleted) {
//       // Navigate to dashboard if onboarding is completed
//       Navigator.pushNamedAndRemoveUntil(
//         context,
//         AppRoutes.dashboardHome,
//         (route) => false,
//       );
//     } else {
//       // Navigate to the appropriate onboarding step
//       final route = OnboardingSteps.getRouteForStep(user.activeStep);
//       debugPrint(route);
//       Navigator.pushNamedAndRemoveUntil(
//         context,
//         route,
//         (route) => false,
//       );
//     }
//   }
// }


import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/onboarding_steps.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/domain/auth/entities/user.dart';

class NavigationHelper {
  static void navigateAfterOtpVerification(
    BuildContext context,
    AuthResponse authResponse,
  ) {
    final user = authResponse.user;

    if (user.onboardingCompleted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboardHome,
        (route) => false,
      );
    } else {
      final route = OnboardingSteps.getRouteForStep(user.activeStep.toString());
      
      // Use standard Flutter navigation with the routes defined in main.dart
      Navigator.pushNamedAndRemoveUntil(
        context,
        route,
        (route) => false,
      );
    }
  }
}
