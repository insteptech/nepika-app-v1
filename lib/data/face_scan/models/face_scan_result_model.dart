import 'dart:convert';
import 'dart:typed_data';

import '../../../domain/face_scan/entities/face_scan_result.dart';
import '../../../domain/face_scan/entities/scan_image.dart';
import 'scan_image_model.dart';
import 'skin_analysis_model.dart';

/// Data model for face scan API responses.
/// This model handles the conversion between API JSON structure and domain entities.
class FaceScanResultModel {
  /// Success status of the API call
  final bool success;
  
  /// Complete analysis data from the API
  final Map<String, dynamic> analysis;
  
  /// Processing time in milliseconds
  final int processingTimeMs;
  
  /// Error message if any
  final String? errorMessage;
  
  /// Timestamp when scan was performed
  final DateTime timestamp;
  
  /// User ID who performed the scan
  final String userId;
  
  /// Unique scan session ID
  final String scanId;

  const FaceScanResultModel({
    required this.success,
    required this.analysis,
    required this.processingTimeMs,
    this.errorMessage,
    required this.timestamp,
    required this.userId,
    required this.scanId,
  });

  /// Creates a FaceScanResultModel from API JSON response
  factory FaceScanResultModel.fromJson(
    Map<String, dynamic> json, {
    required String userId,
    required String scanId,
    required int processingTimeMs,
  }) {
    return FaceScanResultModel(
      success: json['success'] == true,
      analysis: json['analysis'] as Map<String, dynamic>? ?? {},
      processingTimeMs: processingTimeMs,
      errorMessage: json['error_message'] as String?,
      timestamp: DateTime.now(),
      userId: userId,
      scanId: scanId,
    );
  }

  /// Creates a failed scan result model
  factory FaceScanResultModel.failed({
    required String userId,
    required String scanId,
    required String errorMessage,
    required int processingTimeMs,
  }) {
    return FaceScanResultModel(
      success: false,
      analysis: {},
      processingTimeMs: processingTimeMs,
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
      userId: userId,
      scanId: scanId,
    );
  }

  /// Converts to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'analysis': analysis,
      'processing_time_ms': processingTimeMs,
      'error_message': errorMessage,
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
      'scan_id': scanId,
    };
  }

  /// Converts to domain entity
  FaceScanResult toEntity({
    required ScanImage scanImage,
  }) {
    if (!success || analysis.isEmpty) {
      return FaceScanResult.failed(
        scanId: scanId,
        userId: userId,
        scanTimestamp: timestamp,
        errorMessage: errorMessage ?? 'Analysis failed',
        processingTimeMs: processingTimeMs,
      );
    }

    // Extract skin analysis from the API response
    final skinAnalysisModel = SkinAnalysisModel.fromJson(analysis);
    final skinAnalysis = skinAnalysisModel.toEntity();

    return FaceScanResult(
      scanId: scanId,
      userId: userId,
      scanTimestamp: timestamp,
      skinAnalysis: skinAnalysis,
      scanImage: scanImage,
      isSuccessful: true,
      processingTimeMs: processingTimeMs,
    );
  }

  /// Creates a copy with updated fields
  FaceScanResultModel copyWith({
    bool? success,
    Map<String, dynamic>? analysis,
    int? processingTimeMs,
    String? errorMessage,
    DateTime? timestamp,
    String? userId,
    String? scanId,
  }) {
    return FaceScanResultModel(
      success: success ?? this.success,
      analysis: analysis ?? this.analysis,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      errorMessage: errorMessage ?? this.errorMessage,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      scanId: scanId ?? this.scanId,
    );
  }

  /// Extracts the annotated image base64 string from the analysis
  String? get annotatedImageBase64 {
    final skinAreas = analysis['skin_areas'] as Map<String, dynamic>?;
    final annotatedImage = skinAreas?['annotated_image'] as String?;
    
    if (annotatedImage != null) {
      // Remove data URL prefix if present
      String base64String = annotatedImage;
      if (base64String.startsWith('data:image')) {
        final commaIndex = base64String.indexOf(',');
        if (commaIndex != -1) {
          base64String = base64String.substring(commaIndex + 1);
        }
      }
      return base64String;
    }
    
    return null;
  }

  /// Extracts annotated image bytes from base64
  Uint8List? get annotatedImageBytes {
    final base64String = annotatedImageBase64;
    if (base64String != null) {
      try {
        return base64Decode(base64String);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Extracts skin condition predictions from the analysis
  Map<String, double> get skinConditionPredictions {
    final skinCondition = analysis['skin_condition'] as Map<String, dynamic>?;
    final allPredictions = skinCondition?['all_predictions'] as Map<String, dynamic>?;
    
    if (allPredictions != null) {
      return allPredictions.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    }
    
    return {};
  }

  /// Gets the dominant skin condition with confidence
  MapEntry<String, double>? get dominantCondition {
    final predictions = skinConditionPredictions;
    if (predictions.isEmpty) return null;
    
    // Find the condition with highest confidence
    MapEntry<String, double>? dominant;
    for (final entry in predictions.entries) {
      if (dominant == null || entry.value > dominant.value) {
        dominant = entry;
      }
    }
    
    return dominant;
  }

  @override
  String toString() {
    return 'FaceScanResultModel('
        'success: $success, '
        'processingTimeMs: $processingTimeMs, '
        'errorMessage: $errorMessage, '
        'timestamp: $timestamp, '
        'userId: $userId, '
        'scanId: $scanId, '
        'hasAnalysis: ${analysis.isNotEmpty}'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FaceScanResultModel &&
        other.success == success &&
        other.analysis == analysis &&
        other.processingTimeMs == processingTimeMs &&
        other.errorMessage == errorMessage &&
        other.timestamp == timestamp &&
        other.userId == userId &&
        other.scanId == scanId;
  }

  @override
  int get hashCode {
    return success.hashCode ^
        analysis.hashCode ^
        processingTimeMs.hashCode ^
        errorMessage.hashCode ^
        timestamp.hashCode ^
        userId.hashCode ^
        scanId.hashCode;
  }
}