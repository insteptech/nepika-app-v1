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
        if (state is SplashNavigateToWelcome) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
        } else if (state is SplashNavigateToOnboarding) {
          if (state.activeStep != null && state.activeStep! > 0) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.dashboardHome);
          } else {
            Navigator.of(context).pushReplacementNamed(
              AppRoutes.onboarding,
              arguments: {'activeStep': state.activeStep},
            );
          }
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