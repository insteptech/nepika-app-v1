import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/constants/api_endpoints.dart';
import '../config/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenRefreshInterceptor extends Interceptor {
  Dio dio;
  final String baseUrl;
  
  TokenRefreshInterceptor({required this.dio, required this.baseUrl});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    debugPrint('🚨 TokenRefreshInterceptor: onError called!');
    debugPrint('🔍 Status Code: ${err.response?.statusCode}');
    debugPrint('🔍 Request Path: ${err.requestOptions.path}');
    debugPrint('🔍 Request URL: ${err.requestOptions.uri}');
    debugPrint('🔍 Request Headers: ${err.requestOptions.headers}');
    
    // Check if auth should be skipped
    if (err.requestOptions.extra['skipAuth'] == true) {
      debugPrint('🚫 TokenRefreshInterceptor: Skipping error handling due to skipAuth=true');
      handler.next(err);
      return;
    }

    // Special logging for validation endpoint
    if (err.requestOptions.path.contains('/auth/users/validate')) {
      debugPrint('🔐 TokenRefreshInterceptor: This is a token validation request from splash screen');
    }
    
    if (err.response?.statusCode == 401) {
      debugPrint('🔄 TokenRefreshInterceptor: 401 Unauthorized detected, attempting token refresh');
      debugPrint('🔍 TokenRefreshInterceptor: Failed request details:');
      debugPrint('   - URL: ${err.requestOptions.uri}');
      debugPrint('   - Method: ${err.requestOptions.method}');
      debugPrint('   - Headers: ${err.requestOptions.headers}');
      
      // Get stored refresh token
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
      
      debugPrint('🔍 TokenRefreshInterceptor: Refresh token exists: ${refreshToken != null && refreshToken.isNotEmpty}');
      
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('❌ TokenRefreshInterceptor: No refresh token available');
        _handleLogout();
        handler.next(err);
        return;
      }

      try {
        // Create a separate Dio instance for token refresh to avoid interceptor loops
        final refreshDio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ));

        // Attempt token refresh
        debugPrint('🔄 TokenRefreshInterceptor: Refreshing token...');
        final refreshResponse = await refreshDio.post(
          ApiEndpoints.refreshToken,
          data: {'refresh_token': refreshToken},
        );

        if (refreshResponse.statusCode == 200 && refreshResponse.data['success'] == true) {
          final newData = refreshResponse.data['data'];
          final newAccessToken = newData['token'] ?? newData['access_token'];
          final newRefreshToken = newData['refresh_token'];
          
          if (newAccessToken != null) {
            debugPrint('✅ TokenRefreshInterceptor: Token refreshed successfully');
            
            // Store new tokens
            await prefs.setString(AppConstants.accessTokenKey, newAccessToken);
            if (newRefreshToken != null) {
              await prefs.setString(AppConstants.refreshTokenKey, newRefreshToken);
            }

            // Update original request with new token
            err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            
            // Retry original request
            debugPrint('🔄 TokenRefreshInterceptor: Retrying original request');
            final response = await dio.fetch(err.requestOptions);
            handler.resolve(response);
            return;
          }
        }
        
        debugPrint('❌ TokenRefreshInterceptor: Token refresh failed');
        _handleLogout();
        handler.next(err);
        
      } catch (refreshError) {
        debugPrint('❌ TokenRefreshInterceptor: Error during token refresh: $refreshError');
        
        // If refresh fails with 401, it means refresh token is invalid
        if (refreshError is DioException && refreshError.response?.statusCode == 401) {
          debugPrint('❌ TokenRefreshInterceptor: Refresh token expired, logging out');
          _handleLogout();
        }
        
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }

  void _handleLogout() {
    debugPrint('🚪 TokenRefreshInterceptor: Handling logout due to token failure');
    TokenRefreshManager.instance._handleAuthFailure();
  }
}

class TokenRefreshManager {
  static final TokenRefreshManager instance = TokenRefreshManager._internal();
  TokenRefreshManager._internal();

  Function()? _onAuthFailure;

  void setAuthFailureHandler(Function() handler) {
    _onAuthFailure = handler;
  }

  void _handleAuthFailure() {
    _onAuthFailure?.call();
  }

  static Future<void> clearTokensAndLogout() async {
    debugPrint('🧹 TokenRefreshManager: Clearing all tokens');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userDataKey);
    await prefs.remove(AppConstants.userTokenKey);
  }
}