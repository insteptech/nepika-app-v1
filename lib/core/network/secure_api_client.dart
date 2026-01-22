import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:nepika/core/utils/debug_logger.dart';
import '../config/env.dart';
import '../config/constants/app_constants.dart';
import '../services/navigation_service.dart';
import 'token_refresh_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureApiClient {
  static SecureApiClient? _instance;
  static SecureApiClient get instance => _instance ??= SecureApiClient._internal();
  
  late final Dio _dio;
  final TokenRefreshInterceptor _tokenRefreshInterceptor;

  SecureApiClient._internal() : _tokenRefreshInterceptor = TokenRefreshInterceptor(
    dio: Dio(), // Will be set properly in _initializeDio
    baseUrl: Env.baseUrl,
  ) {
    _initializeDio();
    _setupAuthFailureHandler();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 30), // Increased connection timeout
        receiveTimeout: const Duration(seconds: 60), // Increased receive timeout for OTP verification
        sendTimeout: const Duration(seconds: 30),   // Increased send timeout
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Update the interceptor with the actual Dio instance
    _tokenRefreshInterceptor.dio = _dio;
    
    // Add token refresh interceptor
    _dio.interceptors.add(_tokenRefreshInterceptor);
    
    // Add request interceptor to automatically add auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await _addAuthToken(options);
          handler.next(options);
        },
      ),
    );
  }

  void _setupAuthFailureHandler() {
    TokenRefreshManager.instance.setAuthFailureHandler(() {
      _handleLogout();
    });
  }

  Future<void> _addAuthToken(RequestOptions options) async {
    // Check if auth should be skipped (via extra options or specific endpoints)
    debugPrint('🔍 _addAuthToken: extra=${options.extra}');
    if (options.extra['skipAuth'] == true) {
      debugPrint('🚫 Skipping auth token injection');
      return;
    }

    // Skip adding token for auth endpoints
    final authEndpoints = ['/auth/users/send-otp', '/auth/users/verify-otp', '/auth/users/resend-otp'];
    final isAuthEndpoint = authEndpoints.any((endpoint) => options.path.contains(endpoint));
    
    if (isAuthEndpoint) {
      return;
    }

    // Get stored access token
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(AppConstants.accessTokenKey);
    
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
  }

  void _handleLogout() async {
    debugPrint('🚪 SecureApiClient: Handling logout due to auth failure');
    
    try {
      // Clear all tokens
      await TokenRefreshManager.clearTokensAndLogout();
      
      // Navigate to login
      _navigateToLogin();
    } catch (e) {
      debugPrint('❌ SecureApiClient: Error during logout: $e');
    }
  }

  void _navigateToLogin() {
    try {
      NavigationService.navigateToLogin();
    } catch (e) {
      debugPrint('❌ SecureApiClient: Error navigating to login: $e');
      // Fallback to callback if navigation service fails
      _logoutCallback?.call();
    }
  }

  // Optional callback for additional logout handling
  static Function()? _logoutCallback;
  
  static void setLogoutCallback(Function() callback) {
    _logoutCallback = callback;
  }

  Future<Response> request({
    required String path,
    String method = 'GET',
    dynamic body, // Changed from Map<String, dynamic>? to dynamic for FormData support
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    bool skipAuth = false,
  }) async {
    debugPrint('🚀🚀  Requesting: $method ${Env.baseUrl}$path 🚀🚀');
    
    final mergedHeaders = {
      ..._dio.options.headers,
      if (headers != null) ...headers,
    };
    
    debugPrint('Headers: $mergedHeaders');
    
    try {
      final response = await _dio.request(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method.toUpperCase(),
          headers: mergedHeaders,
          extra: {'skipAuth': skipAuth},
        ),
      );
      
      debugPrint('\n\n\n✅✅ Response [${response.statusCode}] ✅✅\n');
      logJson(response.data);
      debugPrint('\n\n\n');
      
      return response;
    } on DioException catch (e) {
      debugPrint('\n\n\n❌❌ Dio error: ${e.response?.statusCode} - ${e.message} ❌❌');
      debugPrint('❌❌ Dio error type: ${e.type}');
      debugPrint('❌❌ Request URL: ${e.requestOptions.uri}');
      debugPrint('❌❌ Error details: ${e.toString()}\n\n\n');
      
      // Provide more specific error messages
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet connection and try again.');
      } else if (e.type == DioExceptionType.sendTimeout) {
        throw Exception('Request timeout. Please try again.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        // Special handling for OTP verification timeout
        if (e.requestOptions.path.contains('/auth/users/verify-otp')) {
          throw Exception('OTP verification is taking longer than expected. Your OTP may have been processed. Please check if you\'ve been logged in or try again.');
        }
        throw Exception('Server response timeout. Please try again.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Connection error. Please check your internet connection.');
      } else if (e.response?.statusCode == null) {
        throw Exception('Failed to connect to server. Please check your internet connection.');
      }
      
      rethrow;
    } catch (e) {
      debugPrint('\n❌❌ Unexpected error: $e ❌❌\n');
      rethrow;
    }
  }
  
  // Method to manually refresh token (for testing or explicit calls)
  Future<bool> refreshTokenManually() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
      
      if (refreshToken == null) {
        debugPrint('❌ SecureApiClient: No refresh token available for manual refresh');
        return false;
      }

      final refreshResponse = await _dio.post(
        '/auth/users/refresh-token',
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (refreshResponse.statusCode == 200 && refreshResponse.data['success'] == true) {
        final newData = refreshResponse.data['data'];
        final newAccessToken = newData['token'] ?? newData['access_token'];
        final newRefreshToken = newData['refresh_token'];
        
        if (newAccessToken != null) {
          await prefs.setString(AppConstants.accessTokenKey, newAccessToken);
          if (newRefreshToken != null) {
            await prefs.setString(AppConstants.refreshTokenKey, newRefreshToken);
          }
          debugPrint('✅ SecureApiClient: Manual token refresh successful');
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ SecureApiClient: Manual token refresh failed: $e');
      return false;
    }
  }
}