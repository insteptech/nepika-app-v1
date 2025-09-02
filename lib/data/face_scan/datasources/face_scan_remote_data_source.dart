import 'dart:typed_data';

import '../models/face_scan_result_model.dart';

/// Abstract interface for remote face scanning operations.
/// 
/// This interface defines the contract for API communication with the face analysis service.
/// Implementations should handle network communication, request/response parsing,
/// and proper error handling for various failure scenarios.
abstract class FaceScanRemoteDataSource {
  /// Sends an image to the face analysis API for complete skin analysis.
  /// 
  /// Parameters:
  /// - [imageBytes]: Raw image data to analyze
  /// - [userId]: ID of the user requesting analysis
  /// - [includeAnnotatedImage]: Whether to include processed/annotated image in response
  /// - [processingStartTime]: When processing began (for timing calculation)
  /// 
  /// Returns:
  /// - [FaceScanResultModel]: Complete analysis results from the API
  /// 
  /// Throws:
  /// - [DioException]: For network-related errors
  /// - [FormatException]: For JSON parsing errors
  /// - [Exception]: For other processing errors
  Future<FaceScanResultModel> analyzeFaceImage({
    required Uint8List imageBytes,
    required String userId,
    bool includeAnnotatedImage = true,
    DateTime? processingStartTime,
  });

  /// Validates image before sending to API.
  /// 
  /// Performs client-side validation to catch basic issues before making API calls.
  /// This can help reduce unnecessary network requests and provide faster feedback.
  /// 
  /// Parameters:
  /// - [imageBytes]: Image data to validate
  /// 
  /// Returns:
  /// - [Map<String, dynamic>]: Validation result with status and messages
  /// 
  /// Throws:
  /// - [Exception]: For validation processing errors
  Future<Map<String, dynamic>> validateImageForAnalysis({
    required Uint8List imageBytes,
  });

  /// Gets the health status of the face analysis API.
  /// 
  /// Used to check if the API service is available and responsive
  /// before attempting analysis operations.
  /// 
  /// Returns:
  /// - [Map<String, dynamic>]: API health status information
  /// 
  /// Throws:
  /// - [DioException]: For network-related errors
  /// - [Exception]: For other processing errors
  Future<Map<String, dynamic>> getApiHealthStatus();

  /// Gets API configuration and capabilities.
  /// 
  /// Retrieves information about API limits, supported features,
  /// and configuration settings that may affect client behavior.
  /// 
  /// Returns:
  /// - [Map<String, dynamic>]: API configuration information
  /// 
  /// Throws:
  /// - [DioException]: For network-related errors
  /// - [Exception]: For other processing errors
  Future<Map<String, dynamic>> getApiConfiguration();
}