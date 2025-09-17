import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme_notifier.dart';
import 'package:nepika/core/utils/debug_logger.dart';
import 'package:nepika/core/utils/shared_prefs_helper.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../core/config/constants/theme.dart';
import '../../../core/config/constants/routes.dart';
import '../../../core/config/constants/assets.dart';
import '../../../core/config/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../core/config/env.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;


  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // Initialize the SharedPreferences instance
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();

    // Check authentication status and navigate accordingly after splash animation
    Timer(const Duration(seconds: 3), () {
      _navigateBasedOnAuthStatus();
    });
  }

  Future<void> _navigateBasedOnAuthStatus() async {
    if (!mounted) return;

    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      final accessToken = sharedPrefs.getString(AppConstants.accessTokenKey);
      final prefHelper = SharedPrefsHelper();

      if (!mounted) return;

      // Save default language
      prefHelper.saveAppLanguage('en');

      if (accessToken != null && accessToken.isNotEmpty) {
        // Validate token with backend
        await _validateUserToken(accessToken);
      } else {
        // No token, navigate to welcome/login
        _navigateToLogin();
      }
    } catch (e) {
      if (mounted) {
        _navigateToLogin();
      }
    }
  }

  Future<void> _validateUserToken(String token) async {
    if (!mounted) return;

    try {
      final dio = Dio();
      // Add timeout configuration
      dio.options.connectTimeout = const Duration(seconds: 5);
      dio.options.receiveTimeout = const Duration(seconds: 10);
      dio.options.sendTimeout = const Duration(seconds: 5);
      
      final response = await dio.get(
        '${Env.baseUrl}/auth/users/validate',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;

        // Check if the response indicates success
        if (responseData['success'] == true) {
          final userData = responseData['data'];
          final bool onboardingCompleted =
              userData['onboarding_completed'] ?? false;
          final int activeStep = userData['active_step'] ?? 0;

          if (!mounted) return;

          // Navigate based on onboarding status
          if (token.isNotEmpty) {
            // Onboarding completed, go to dashboard
            Navigator.of(context).pushReplacementNamed(AppRoutes.dashboardHome);
          } else {
            // Onboarding not completed, navigate based on active step
            Navigator.of(context).pushReplacementNamed(
              AppRoutes.onboarding,
              arguments: {'activeStep': activeStep},
            );

            // _navigateToOnboardingStep(activeStep);
          }
        } else {
          // Backend returned success: false
          _showErrorAndNavigateToLogin(
            responseData['message'] ?? 'Authentication failed',
          );
        }
      } else {
        // Invalid response structure
        _showErrorAndNavigateToLogin('Invalid server response');
      }
    } on DioException catch (e) {
      if (!mounted) return;

      String errorMessage = 'Connection error';

      if (e.response != null && e.response!.data != null) {
        try {
          final errorData = e.response!.data;
          errorMessage = errorData['message'] ?? 'Authentication failed';
        } catch (_) {
          errorMessage = 'Authentication failed';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection';
      }

      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      logJson(e);
      _showErrorAndNavigateToLogin('An unexpected error occurred');
    }
  }

  void _navigateToOnboardingStep(String activeStep) {
    if (!mounted) return;

    // Navigate based on the active step
    switch (activeStep.toLowerCase()) {
      case 'user_info':
        Navigator.of(context).pushReplacementNamed(OnboardingRoutes.userInfo);
        break;
      case 'skin_goals':
        Navigator.of(context).pushReplacementNamed(OnboardingRoutes.skinGoals);
        break;
      case 'skin_type':
        Navigator.of(context).pushReplacementNamed(OnboardingRoutes.skinType);
        break;
      case 'lifestyle':
        Navigator.of(context).pushReplacementNamed(OnboardingRoutes.lifestyle);
        break;
      case 'menstrual_cycle':
      case 'cycle_info':
        Navigator.of(context).pushReplacementNamed(OnboardingRoutes.cycleInfo);
        break;
      case 'natural_rhythm':
        Navigator.of(
          context,
        ).pushReplacementNamed(OnboardingRoutes.naturalRhythm);
        break;
      default:
        // If unknown step, start from beginning
        Navigator.of(context).pushReplacementNamed(OnboardingRoutes.userInfo);
        break;
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
  }

  void _showErrorAndNavigateToLogin(String errorMessage) {
    if (!mounted) return;
    // Directly navigate to login without showing alert dialog
    _navigateToLogin();
  }

  bool _isDarkMode(BuildContext context, ThemeNotifier themeNotifier) {
    switch (themeNotifier.themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
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
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 150,
                    height: 150, 
                    child: Center(
                      child: ClipOval(
                        child: Image.asset(
                          AppAssets.appLogoStroke,
                          fit: BoxFit.contain,
                          color: _isDarkMode(context, themeNotifier) ? Theme.of(context).colorScheme.primary : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
