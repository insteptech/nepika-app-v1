import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/config/env.dart';
import '../../../core/error/failures.dart';
import '../models/face_scan_result_model.dart';
import 'face_scan_remote_data_source.dart';

/// Implementation of face scan remote data source using Dio HTTP client.
/// 
/// This implementation handles API communication with the face analysis service,
/// including image upload, result parsing, and comprehensive error handling.
@injectable
class FaceScanRemoteDataSourceImpl implements FaceScanRemoteDataSource {
  final Dio _dio;

  /// API endpoint for complete face analysis
  static const String _analysisEndpoint = '/model/face-scan/analyze_face_complete';
  
  /// API endpoint for health checks
  static const String _healthEndpoint = '/health';
  
  /// API endpoint for configuration
  static const String _configEndpoint = '/config';

  FaceScanRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? _createDefaultDio();

  /// Creates a configured Dio instance for face scan API calls
  static Dio _createDefaultDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'multipart/form-data'},
        responseType: ResponseType.json,
      ),
    );

    // Add logging interceptor for debugging
    dio.interceptors.add(
      LogInterceptor(
        requestBody: false, // Don't log binary image data
        responseBody: false, // Don't log large response bodies
        logPrint: (object) => debugPrint('[Face Scan API] $object'),
      ),
    );

    return dio;
  }

  @override
  Future<FaceScanResultModel> analyzeFaceImage({
    required Uint8List imageBytes,
    required String userId,
    bool includeAnnotatedImage = true,
    DateTime? processingStartTime,
  }) async {
    final startTime = processingStartTime ?? DateTime.now();
    final scanId = _generateScanId();

    try {
      // Validate image before sending
      final validationResult = await validateImageForAnalysis(imageBytes: imageBytes);
      if (validationResult['isValid'] != true) {
        throw FaceAnalysisFailure(
          message: validationResult['message'] ?? 'Image validation failed',
        );
      }

      // Create form data for multipart upload
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: 'face_image_$scanId.jpg',
        ),
        'include_annotated_image': includeAnnotatedImage.toString(),
        'user_id': userId,
      });

      debugPrint('🚀 Sending face image analysis request to $_analysisEndpoint');
      debugPrint('   - Image size: ${imageBytes.length} bytes');
      debugPrint('   - User ID: $userId');
      debugPrint('   - Include annotated: $includeAnnotatedImage');

      final response = await _dio.post(
        _analysisEndpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.json,
        ),
      );

      final processingTime = DateTime.now().difference(startTime).inMilliseconds;

      debugPrint('✅ Face analysis API response received:');
      debugPrint('   - Status: ${response.statusCode}');
      debugPrint('   - Processing time: ${processingTime}ms');

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;

        // Check if the API returned a successful result
        if (responseData['success'] == true) {
          return FaceScanResultModel.fromJson(
            responseData,
            userId: userId,
            scanId: scanId,
            processingTimeMs: processingTime,
          );
        } else {
          // API returned an error response
          final errorMessage = responseData['error_message'] as String? ?? 
              responseData['message'] as String? ?? 
              'Analysis failed without specific error';
          
          return FaceScanResultModel.failed(
            userId: userId,
            scanId: scanId,
            errorMessage: errorMessage,
            processingTimeMs: processingTime,
          );
        }
      } else {
        throw FaceAnalysisFailure(
          message: 'API returned unexpected status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      final errorMessage = _handleDioError(e);
      
      debugPrint('❌ Face analysis API error: $errorMessage');
      
      return FaceScanResultModel.failed(
        userId: userId,
        scanId: scanId,
        errorMessage: errorMessage,
        processingTimeMs: processingTime,
      );
    } catch (e) {
      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      final errorMessage = 'Failed to analyze image: ${e.toString()}';
      
      debugPrint('❌ Face analysis unexpected error: $errorMessage');
      
      return FaceScanResultModel.failed(
        userId: userId,
        scanId: scanId,
        errorMessage: errorMessage,
        processingTimeMs: processingTime,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> validateImageForAnalysis({
    required Uint8List imageBytes,
  }) async {
    try {
      // Basic validation checks
      const minSize = 50 * 1024; // 50KB minimum
      const maxSize = 10 * 1024 * 1024; // 10MB maximum

      if (imageBytes.isEmpty) {
        return {
          'isValid': false,
          'message': 'Image data is empty',
          'issues': ['empty_data'],
        };
      }

      if (imageBytes.length < minSize) {
        return {
          'isValid': false,
          'message': 'Image file is too small. Minimum size is 50KB.',
          'issues': ['file_too_small'],
        };
      }

      if (imageBytes.length > maxSize) {
        return {
          'isValid': false,
          'message': 'Image file is too large. Maximum size is 10MB.',
          'issues': ['file_too_large'],
        };
      }

      // Check for basic image format (JPEG/PNG magic bytes)
      if (!_isValidImageFormat(imageBytes)) {
        return {
          'isValid': false,
          'message': 'Invalid image format. Only JPEG and PNG are supported.',
          'issues': ['invalid_format'],
        };
      }

      return {
        'isValid': true,
        'message': 'Image validation passed',
        'fileSize': imageBytes.length,
        'estimatedFormat': _detectImageFormat(imageBytes),
      };
    } catch (e) {
      return {
        'isValid': false,
        'message': 'Image validation failed: ${e.toString()}',
        'issues': ['validation_error'],
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getApiHealthStatus() async {
    try {
      final response = await _dio.get(
        _healthEndpoint,
        options: Options(
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        return {
          'status': 'healthy',
          'timestamp': DateTime.now().toIso8601String(),
          'responseTime': response.extra?['responseTime'] ?? 0,
          'data': response.data ?? {},
        };
      } else {
        return {
          'status': 'unhealthy',
          'statusCode': response.statusCode,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } on DioException catch (e) {
      return {
        'status': 'error',
        'error': _handleDioError(e),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getApiConfiguration() async {
    try {
      final response = await _dio.get(
        _configEndpoint,
        options: Options(
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'config': response.data ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'success': false,
          'error': 'Config request failed with status: ${response.statusCode}',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'error': _handleDioError(e),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // ===== Private Helper Methods =====

  /// Generates a unique scan ID for tracking requests
  String _generateScanId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'scan_${timestamp}_$random';
  }

  /// Handles Dio errors and returns user-friendly messages
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout. The analysis is taking too long.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final errorData = e.response?.data;
        
        if (statusCode == 400) {
          if (errorData is Map && errorData['message'] != null) {
            return errorData['message'].toString();
          }
          return 'Invalid request. Please check your image and try again.';
        } else if (statusCode == 413) {
          return 'Image file is too large. Please use a smaller image.';
        } else if (statusCode == 429) {
          return 'Too many requests. Please wait and try again.';
        } else if (statusCode == 500) {
          return 'Server error. Please try again later.';
        } else if (statusCode == 503) {
          return 'Service temporarily unavailable. Please try again later.';
        }
        
        return 'Server error (${statusCode}): ${e.response?.statusMessage ?? 'Unknown error'}';
      case DioExceptionType.connectionError:
        return 'Connection error. Please check your internet connection.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
      default:
        return 'Network error: ${e.message ?? 'Unknown error occurred'}';
    }
  }

  /// Checks if the image data has valid JPEG or PNG format
  bool _isValidImageFormat(Uint8List bytes) {
    if (bytes.length < 4) return false;

    // JPEG magic bytes: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }

    // PNG magic bytes: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return true;
    }

    return false;
  }

  /// Detects the image format from magic bytes
  String _detectImageFormat(Uint8List bytes) {
    if (bytes.length < 4) return 'unknown';

    // JPEG magic bytes: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'jpeg';
    }

    // PNG magic bytes: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'png';
    }

    return 'unknown';
  }
}