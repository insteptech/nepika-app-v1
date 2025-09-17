import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nepika/core/utils/debug_logger.dart';
import 'config/constants/app_constants.dart';
import '../../core/config/env.dart';

class ApiBase {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  static bool _isRefreshing = false;
  static final List<_QueuedRequest> _queuedRequests = [];

  ApiBase() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = "Bearer $token";
        }
        return handler.next(options);
      },
      onError: (DioException err, handler) async {
        debugPrint("🚨 ApiBase: Error interceptor triggered");
        debugPrint("🔍 ApiBase: Status Code: ${err.response?.statusCode}");
        debugPrint("🔍 ApiBase: Request URL: ${err.requestOptions.uri}");
        debugPrint("🔍 ApiBase: Request Method: ${err.requestOptions.method}");
        debugPrint("🔍 ApiBase: Request Headers: ${err.requestOptions.headers}");
        
        // Handle only 401 Unauthorized
        if (err.response?.statusCode == 401) {
          debugPrint("🔄 ApiBase: 401 Unauthorized detected, attempting token refresh");
          final requestOptions = err.requestOptions;

          if (!_isRefreshing) {
            debugPrint("🔄 ApiBase: Starting token refresh process");
            _isRefreshing = true;

            try {
              final newToken = await _refreshToken();
              if (newToken != null) {
                debugPrint("✅ ApiBase: Token refresh successful, retrying requests");
                // Retry all queued requests
                for (var queued in _queuedRequests) {
                  queued.retry(newToken);
                }
                _queuedRequests.clear();

                // Retry original request
                final response = await _retryRequest(requestOptions, newToken);
                debugPrint("✅ ApiBase: Original request retry successful");
                return handler.resolve(response);
              } else {
                debugPrint("❌ ApiBase: Token refresh failed");
                // Refresh failed - logout is handled inside _refreshToken() if needed
              }
            } catch (e) {
              debugPrint("❌ ApiBase: Refresh token error: $e");
              // Logout is handled inside _refreshToken() if needed
            } finally {
              _isRefreshing = false;
            }
          } else {
            debugPrint("🔄 ApiBase: Refresh in progress, queueing request");
            // If refresh is in progress → queue request
            final completer = Completer<Response>();
            _queuedRequests.add(_QueuedRequest(
              requestOptions: requestOptions,
              completer: completer,
            ));
            final response = await completer.future;
            return handler.resolve(response);
          }
        }

        return handler.next(err);
      },
    ));
  }

  /// Main request method
  Future<Response> request({
    required String path,
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    debugPrint('🚀🚀 Requesting: $method ${Env.baseUrl}$path 🚀🚀');
    try {
      final response = await _dio.request(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method.toUpperCase(),
          headers: headers,
        ),
      );
      debugPrint('\n✅✅ Response [${response.statusCode}] ✅✅\n');
      logJson(response.data);
      return response;
    } on DioException catch (e) {
      debugPrint('\n❌ Dio error: ${e.response?.statusCode} - ${e.message} ❌\n');
      rethrow;
    }
  }

  /// Refresh token API call
  static Future<String?> _refreshToken() async {
    debugPrint("🔄 ApiBase: Starting token refresh...");
    
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
    debugPrint("🔍 ApiBase: Retrieved refresh token from SharedPreferences: ${refreshToken == null ? 'NULL' : refreshToken.isEmpty ? 'EMPTY' : '${refreshToken.substring(0, 20)}...'}");
    
    if (refreshToken == null || refreshToken.isEmpty) {
      debugPrint("❌ ApiBase: No refresh token available");
      return null;
    }

    debugPrint("🔍 ApiBase: Refresh token exists, attempting refresh");
    
    final dio = Dio(BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    try {
      debugPrint("🚀 ApiBase: Sending refresh token request to ${Env.baseUrl}/auth/users/refresh-token");
      debugPrint("🔍 ApiBase: Request payload: {\"refresh_token\": \"${refreshToken.substring(0, 20)}...\"}");
      
      final response = await dio.post(
        "/auth/users/refresh-token",
        data: {"refresh_token": refreshToken}, // 👈 matches backend
      );

      debugPrint("✅ ApiBase: Refresh response status: ${response.statusCode}");
      debugPrint("🔍 ApiBase: Refresh response data: ${response.data}");

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        final success = responseData["success"] ?? responseData["sucsess"];
        
        if (success == true) {
          final data = responseData["data"];
          final newAccessToken = data["access_token"] ?? data["token"];
          final newRefreshToken = data["refresh_token"];

          if (newAccessToken != null) {
            // Save tokens
            await prefs.setString(AppConstants.accessTokenKey, newAccessToken);
            if (newRefreshToken != null) {
              await prefs.setString(AppConstants.refreshTokenKey, newRefreshToken);
            }
            debugPrint("✅ ApiBase: Token refreshed successfully");
            debugPrint("🔍 ApiBase: New access token: ${newAccessToken.substring(0, 20)}...");
            return newAccessToken;
          } else {
            debugPrint("❌ ApiBase: No access token in refresh response");
          }
        } else {
          debugPrint("❌ ApiBase: Refresh response indicates failure: success=$success");
        }
      } else {
        debugPrint("❌ ApiBase: Invalid refresh response: status=${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ ApiBase: Error during token refresh: $e");
      if (e is DioException) {
        debugPrint("❌ ApiBase: Dio error details:");
        debugPrint("   - Status Code: ${e.response?.statusCode}");
        debugPrint("   - Response Data: ${e.response?.data}");
        debugPrint("   - Message: ${e.message}");
        
        // Only force logout if the refresh token itself is invalid (401)
        // Don't logout for validation errors (422) or other temporary issues
        if (e.response?.statusCode == 401) {
          debugPrint("❌ ApiBase: Refresh token is invalid (401), forcing logout");
          await _forceLogout();
        }
      }
    }
    return null;
  }

  /// Retry original failed request with new token
  static Future<Response> _retryRequest(RequestOptions requestOptions, String token) async {
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        "Authorization": "Bearer $token",
      },
    );
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  /// Force logout (clear tokens + optionally redirect)
  static Future<void> _forceLogout() async {
    debugPrint("⚠️ Logging out user - refresh token expired/invalid");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);

    // TODO: Add navigation to login screen if using Flutter routing
    // e.g., Navigator.of(context).pushReplacementNamed('/login');
  }
}

/// Queue model for pending requests
class _QueuedRequest {
  final RequestOptions requestOptions;
  final Completer<Response> completer;

  _QueuedRequest({required this.requestOptions, required this.completer});

  void retry(String newToken) async {
    try {
      final response = await ApiBase._retryRequest(requestOptions, newToken);
      completer.complete(response);
    } catch (e) {
      completer.completeError(e);
    }
  }
}
