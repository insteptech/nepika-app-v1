import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:nepika/core/config/env.dart';
import 'package:nepika/core/utils/secure_storage.dart';

/// Handles API communication for face scan analysis
class FaceScanApiHandler {
  late Dio _dio;
  
  // API endpoints
  static const String _apiEndpoint = '${Env.baseUrl}/model/face-scan/analyze_face_complete';

  /// Initialize Dio client
  void initialize() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'multipart/form-data'},
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (object) => debugPrint(object.toString()),
      ),
    );
  }

  /// Send image to API for analysis
  Future<FaceScanApiResult> analyzeImage(XFile imageFile) async {
    try {
      final secureStorage = SecureStorage();
      final userId = await secureStorage.getUserId();

      // Create FormData for multipart upload
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'face_image.jpg',
        ),
        'include_annotated_image': 'true',
        'user_id': userId,
      });

      debugPrint('Sending image to API: $_apiEndpoint');

      final response = await _dio.post(
        _apiEndpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.json,
        ),
      );

      debugPrint('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true) {
          // Extract report image URL
          final report = responseData['report'] as Map<String, dynamic>?;
          final imageUrl = report?['image_url'] as String?;
          
          String? fullImageUrl;
          if (imageUrl != null) {
            fullImageUrl = '${Env.backendBase}$imageUrl';
            debugPrint('Report image URL: $fullImageUrl');
          }

          return FaceScanApiResult.success(
            analysisResults: responseData,
            reportImageUrl: fullImageUrl,
          );
        } else {
          final errorMessage = responseData['error_message'] ?? 'Analysis failed';
          return FaceScanApiResult.error(errorMessage);
        }
      } else {
        return FaceScanApiResult.error('API returned status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Dio Error: $e');
      final errorMessage = _handleDioError(e);
      return FaceScanApiResult.error(errorMessage);
    } catch (e) {
      debugPrint('API Error: $e');
      return FaceScanApiResult.error('Failed to analyze image: ${e.toString()}');
    }
  }

  /// Handle Dio errors with user-friendly messages
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout. Please try again.';
      case DioExceptionType.badResponse:
        return 'Server error (${e.response?.statusCode}): ${e.response?.statusMessage}';
      case DioExceptionType.connectionError:
        return 'Connection error. Please check your internet connection.';
      default:
        return 'Network error: ${e.message}';
    }
  }

  /// Cancel any ongoing requests
  void cancelRequests() {
    _dio.close();
  }
}

/// Result of face scan API call
class FaceScanApiResult {
  final bool isSuccess;
  final String? errorMessage;
  final Map<String, dynamic>? analysisResults;
  final String? reportImageUrl;

  const FaceScanApiResult._({
    required this.isSuccess,
    this.errorMessage,
    this.analysisResults,
    this.reportImageUrl,
  });

  factory FaceScanApiResult.success({
    required Map<String, dynamic> analysisResults,
    String? reportImageUrl,
  }) {
    return FaceScanApiResult._(
      isSuccess: true,
      analysisResults: analysisResults,
      reportImageUrl: reportImageUrl,
    );
  }

  factory FaceScanApiResult.error(String errorMessage) {
    return FaceScanApiResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}