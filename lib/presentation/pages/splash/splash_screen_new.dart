// import 'package:flutter/material.dart';
// import 'dart:async';
// import '../../../core/constants/routes.dart';
// import '../../../core/constants/assets.dart';
// import '../../../core/services/auth_service.dart';
// import '../../../core/constants/onboarding_steps.dart';
// import '../../../data/auth/datasources/auth_local_data_source_impl.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> 
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _opacityAnimation;

//   @override
//   void initState() {
//     super.initState();
    
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 2000),
//       vsync: this,
//     );
    
//     _scaleAnimation = Tween<double>(
//       begin: 0.5,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.elasticOut,
//     ));
    
//     _opacityAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
//     ));
    
//     _animationController.forward();
    
//     // Check authentication status and navigate accordingly after splash animation
//     Timer(const Duration(seconds: 3), () {
//       _navigateBasedOnAuthStatus();
//     });
//   }

//   Future<void> _navigateBasedOnAuthStatus() async {
//     if (!mounted) return;

//     try {
//       final sharedPrefs = await SharedPreferences.getInstance();
//       final authLocalDataSource = AuthLocalDataSourceImpl(sharedPrefs);
//       final authService = AuthService(authLocalDataSource);
      
//       final authStatus = await authService.getAuthStatus();
      
//       if (!mounted) return;

//       switch (authStatus) {
//         case AuthStatusAuthenticated():
//           // User is fully authenticated and onboarded - go to dashboard
//           Navigator.of(context).pushReplacementNamed(AppRoutes.dashboardHome);
//           break;
          
//         case AuthStatusNeedsOnboarding():
//           // User is authenticated but needs to complete onboarding
//           final route = OnboardingSteps.getRouteForStep(authStatus.activeStep);
//           Navigator.of(context).pushReplacementNamed(route);
//           break;
          
//         case AuthStatusUnauthenticated():
//           // User is not authenticated - go to welcome/login
//           Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
//           break;
//       }
//     } catch (e) {
//       // If there's any error, default to welcome screen
//       print('Error checking auth status: $e');
//       if (mounted) {
//         Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
//       }
//     }
//   }s

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//                Theme.of(context).colorScheme.onPrimary,
//                Theme.of(context).colorScheme.onPrimary,
//             ],
//           ),
//         ),
//         child: Center(
//           child: AnimatedBuilder(
//             animation: _animationController,
//             builder: (context, child) {
//               return Opacity(
//                 opacity: _opacityAnimation.value,
//                 child: Transform.scale(
//                   scale: _scaleAnimation.value,
//                   child: Container(
//                     width: 150,
//                     height: 150,
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       shape: BoxShape.circle,
//                     ),
//                     child: Center(
//                       child: ClipOval(
//                         child: Container(
//                           width: 120,
//                           height: 120,
//                           padding: const EdgeInsets.all(20),
//                           child: Image.asset(
//                             AppAssets.nepikaLogo,
//                             fit: BoxFit.contain,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
