import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/constants/routes.dart';
import '../bloc/splash_bloc.dart';
import '../bloc/splash_event.dart';
import '../bloc/splash_state.dart';
import '../widgets/splash_logo_animation.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashBloc()..add(SplashStarted()),
      child: const SplashView(),
    );
  }
}

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listener: (context, state) {
        print('🎯 SPLASH LISTENER: Received state: ${state.runtimeType}');
        
        if (state is SplashNavigateToWelcome) {
          print('🚀 SPLASH: Navigating to Welcome');
          Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
        } else if (state is SplashNavigateToOnboarding) {
          print('🔍 SPLASH: SplashNavigateToOnboarding received');
          print('  - Active Step: ${state.activeStep}');
          print('  - Should go to dashboard: ${state.activeStep != null && state.activeStep! > 1}');
          
          if (state.activeStep != null && state.activeStep! > 1) {
            print('🚀 SPLASH: Navigating to Dashboard (activeStep: ${state.activeStep})');
            Navigator.of(context).pushReplacementNamed(AppRoutes.dashboardHome);
          } else {
            print('🚀 SPLASH: Navigating to Onboarding (activeStep: ${state.activeStep})');
            Navigator.of(context).pushReplacementNamed(
              AppRoutes.onboarding,
              arguments: {'activeStep': state.activeStep},
            );
          }
        } else {
          print('🔍 SPLASH: Unhandled state: ${state.runtimeType}');
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.onPrimary,
                Theme.of(context).colorScheme.onPrimary,
              ],
            ),
          ),
          child: const Center(
            child: SplashLogoAnimation(),
          ),
        ),
      ),
    );
  }
}