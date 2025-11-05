import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/constants/app_constants.dart';
import '../../../core/network/secure_api_client.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/utils/shared_prefs_helper.dart';
import '../../../core/services/unified_fcm_service.dart';
import 'splash_event.dart';
import 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(SplashInitial()) {
    on<SplashStarted>(_onSplashStarted);
    on<CheckAuthenticationStatus>(_onCheckAuthenticationStatus);
  }

  Future<void> _onSplashStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    logJson('🚀 SPLASH STARTED: Beginning splash flow');
    emit(SplashAnimating());
    
    // Initialize FCM service in background during splash animation (without token generation)
    _initializeFcmInBackground();
    
    // Start auth check immediately (no delay needed)
    logJson('🔍 SPLASH: Starting auth check immediately');
    add(CheckAuthenticationStatus());
    
    // The CheckAuthenticationStatus handler will emit navigation states
    // No need to wait here - the BlocListener will handle navigation
    logJson('✅ SPLASH: Auth check initiated, waiting for state changes...');
  }

  /// Initialize FCM service in background without blocking splash flow
  void _initializeFcmInBackground() {
    // Run FCM initialization asynchronously without blocking the splash flow
    UnifiedFcmService.instance.initializeWithoutToken().then((_) {
      logJson('✅ FCM Service initialized successfully during splash');
    }).catchError((error) {
      logJson('❌ FCM Service initialization failed during splash: $error');
      // Don't block app flow for FCM failures
    });
  }

  Future<void> _onCheckAuthenticationStatus(
    CheckAuthenticationStatus event,
    Emitter<SplashState> emit,
  ) async {
    logJson('🔍 SPLASH: CheckAuthenticationStatus event started');
    emit(SplashCheckingAuth());

    try {
      logJson('📱 SPLASH: Getting shared preferences...');
      final sharedPrefs = await SharedPreferences.getInstance();
      final accessToken = sharedPrefs.getString(AppConstants.accessTokenKey);
      final prefHelper = SharedPrefsHelper();

      // Save default language
      prefHelper.saveAppLanguage('en');

      if (accessToken != null && accessToken.isNotEmpty) {
        logJson('🔑 SPLASH: Access token found, validating with backend...');
        logJson('🔑 SPLASH: Token preview: ${accessToken.substring(0, 20)}...');
        // Validate token with backend
        await _validateUserToken(accessToken, emit);
      } else {
        logJson('❌ SPLASH: No access token found, navigating to welcome');
        // No token, navigate to welcome/login
        emit(SplashNavigateToWelcome());
      }
    } catch (e) {
      logJson('❌ SPLASH: Error in CheckAuthenticationStatus: $e');
      emit(SplashNavigateToWelcome());
    }
  }

  Future<void> _validateUserToken(
    String token,
    Emitter<SplashState> emit,
  ) async {
    try {
      // Use SecureApiClient which includes token refresh interceptor
      final secureClient = SecureApiClient.instance;
      
      final response = await secureClient.request(
        path: '/auth/users/validate',
        method: 'GET',
      ).timeout(const Duration(seconds: 10)); // Increased from 3s to 10s for better reliability

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;

        // Check if the response indicates success
        if (responseData['success'] == true) {
          final userData = responseData['data'];
          final int activeStep = userData['active_step'] ?? 1;
          final bool onboardingCompleted = userData['onboarding_completed'] ?? false;

          logJson('🔍 SPLASH DEBUG: User data received');
          logJson('  - Active Step: $activeStep');
          logJson('  - Onboarding Completed: $onboardingCompleted');
          logJson('  - Will emit: SplashNavigateToOnboarding(activeStep: $activeStep)');

          // Navigate to onboarding regardless of completion status
          emit(SplashNavigateToOnboarding(activeStep: activeStep));
          
          logJson('✅ SPLASH: SplashNavigateToOnboarding state emitted');
        } else {
          logJson('❌ SPLASH: Backend returned success: false, navigating to welcome');
          // Backend returned success: false
          emit(SplashNavigateToWelcome());
        }
      } else {
        // Invalid response structure
        emit(SplashNavigateToWelcome());
      }
    } on DioException catch (e) {
      // Log error for debugging
      logJson('DioException during token validation: ${e.message}');
      
      // Check if it's a 401 - the token refresh interceptor should have already tried
      if (e.response?.statusCode == 401) {
        // Token refresh failed, navigate to welcome
        logJson('Token validation failed with 401 after refresh attempt');
      }
      
      emit(SplashNavigateToWelcome());
    } catch (e) {
      // Handle different exception types appropriately
      if (e is TimeoutException) {
        logJson({
          'error': 'Token validation timeout',
          'message': e.message ?? 'Request timed out',
          'duration': e.duration?.toString(),
          'action': 'Redirecting to welcome screen'
        });
      } else {
        logJson({
          'error': 'Token validation failed',
          'type': e.runtimeType.toString(),
          'message': e.toString(),
          'action': 'Redirecting to welcome screen'
        });
      }
      emit(SplashNavigateToWelcome());
    }
  }
}