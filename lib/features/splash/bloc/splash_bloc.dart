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
    emit(SplashAnimating());
    
    // Initialize FCM service in background during splash animation (without token generation)
    _initializeFcmInBackground();
    
    // Wait for animation duration
    await Future.delayed(const Duration(seconds: 3));
    
    add(CheckAuthenticationStatus());
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
    emit(SplashCheckingAuth());

    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      final accessToken = sharedPrefs.getString(AppConstants.accessTokenKey);
      final prefHelper = SharedPrefsHelper();

      // Save default language
      prefHelper.saveAppLanguage('en');

      if (accessToken != null && accessToken.isNotEmpty) {
        // Validate token with backend
        await _validateUserToken(accessToken, emit);
      } else {
        // No token, navigate to welcome/login
        emit(SplashNavigateToWelcome());
      }
    } catch (e) {
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
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;

        // Check if the response indicates success
        if (responseData['success'] == true) {
          final userData = responseData['data'];
          final int activeStep = userData['active_step'] ?? 1;

          // Navigate to onboarding regardless of completion status
          emit(SplashNavigateToOnboarding(activeStep: activeStep));
        } else {
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
      logJson(e);
      emit(SplashNavigateToWelcome());
    }
  }
}