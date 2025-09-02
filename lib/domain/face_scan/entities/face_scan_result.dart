import 'package:equatable/equatable.dart';

import 'skin_analysis.dart';
import 'scan_image.dart';

/// Core entity representing the complete result of a face scanning operation.
/// This is the main aggregate root that encapsulates all face scan data.
class FaceScanResult extends Equatable {
  /// Unique identifier for this scan session
  final String scanId;
  
  /// User identifier who performed the scan
  final String userId;
  
  /// Timestamp when the scan was performed
  final DateTime scanTimestamp;
  
  /// Detailed skin analysis results from the AI model
  final SkinAnalysis skinAnalysis;
  
  /// Original captured image and processed annotated image
  final ScanImage scanImage;
  
  /// Overall success status of the scan operation
  final bool isSuccessful;
  
  /// Any error message if scan was not successful
  final String? errorMessage;
  
  /// Processing time in milliseconds
  final int processingTimeMs;

  const FaceScanResult({
    required this.scanId,
    required this.userId,
    required this.scanTimestamp,
    required this.skinAnalysis,
    required this.scanImage,
    required this.isSuccessful,
    this.errorMessage,
    required this.processingTimeMs,
  });

  /// Creates a copy of this FaceScanResult with the given fields replaced with new values
  FaceScanResult copyWith({
    String? scanId,
    String? userId,
    DateTime? scanTimestamp,
    SkinAnalysis? skinAnalysis,
    ScanImage? scanImage,
    bool? isSuccessful,
    String? errorMessage,
    int? processingTimeMs,
  }) {
    return FaceScanResult(
      scanId: scanId ?? this.scanId,
      userId: userId ?? this.userId,
      scanTimestamp: scanTimestamp ?? this.scanTimestamp,
      skinAnalysis: skinAnalysis ?? this.skinAnalysis,
      scanImage: scanImage ?? this.scanImage,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      errorMessage: errorMessage ?? this.errorMessage,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
    );
  }

  /// Creates a failed scan result with error information
  factory FaceScanResult.failed({
    required String scanId,
    required String userId,
    required DateTime scanTimestamp,
    required String errorMessage,
    required int processingTimeMs,
  }) {
    return FaceScanResult(
      scanId: scanId,
      userId: userId,
      scanTimestamp: scanTimestamp,
      skinAnalysis: SkinAnalysis.empty(),
      scanImage: ScanImage.empty(),
      isSuccessful: false,
      errorMessage: errorMessage,
      processingTimeMs: processingTimeMs,
    );
  }

  @override
  List<Object?> get props => [
        scanId,
        userId,
        scanTimestamp,
        skinAnalysis,
        scanImage,
        isSuccessful,
        errorMessage,
        processingTimeMs,
      ];

  @override
  String toString() {
    return 'FaceScanResult('
        'scanId: $scanId, '
        'userId: $userId, '
        'scanTimestamp: $scanTimestamp, '
        'skinAnalysis: $skinAnalysis, '
        'scanImage: $scanImage, '
        'isSuccessful: $isSuccessful, '
        'errorMessage: $errorMessage, '
        'processingTimeMs: $processingTimeMs'
        ')';
  }
}