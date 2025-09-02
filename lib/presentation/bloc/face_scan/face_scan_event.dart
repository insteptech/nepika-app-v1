import 'package:equatable/equatable.dart';
import 'package:camera/camera.dart';
import '../../../domain/face_scan/entities/camera_scan_session.dart';

/// Base class for all face scanning related events.
/// Follows the existing project's BLoC patterns using Equatable for comparison.
abstract class FaceScanEvent extends Equatable {
  const FaceScanEvent();
  
  @override
  List<Object?> get props => [];
}

// ==================== Session Management Events ====================

/// Initializes a new face scanning session.
/// This is the entry point for starting the entire face scan workflow.
class InitializeFaceScanSession extends FaceScanEvent {
  /// User ID for the scanning session
  final String userId;
  
  /// Optional session configuration, uses defaults if not provided
  final CameraSessionConfig? sessionConfig;
  
  /// Optional pre-initialized camera controller from previous screen
  final CameraController? preInitializedCamera;
  
  /// Optional available cameras list from previous screen
  final List<CameraDescription>? availableCameras;

  const InitializeFaceScanSession({
    required this.userId,
    this.sessionConfig,
    this.preInitializedCamera,
    this.availableCameras,
  });

  @override
  List<Object?> get props => [
    userId,
    sessionConfig,
    preInitializedCamera,
    availableCameras,
  ];

  @override
  String toString() {
    return 'InitializeFaceScanSession('
        'userId: $userId, '
        'sessionConfig: $sessionConfig, '
        'preInitializedCamera: ${preInitializedCamera != null}, '
        'availableCameras: ${availableCameras?.length}'
        ')';
  }
}

/// Starts the face alignment process after camera is ready.
class StartFaceAlignment extends FaceScanEvent {
  /// Session ID to start alignment for
  final String sessionId;

  const StartFaceAlignment({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];

  @override
  String toString() => 'StartFaceAlignment(sessionId: $sessionId)';
}

/// Cancels the current face scanning session.
class CancelFaceScanSession extends FaceScanEvent {
  /// Session ID to cancel
  final String sessionId;
  
  /// Reason for cancellation (optional, for analytics)
  final String? reason;

  const CancelFaceScanSession({
    required this.sessionId,
    this.reason,
  });

  @override
  List<Object?> get props => [sessionId, reason];

  @override
  String toString() => 'CancelFaceScanSession(sessionId: $sessionId, reason: $reason)';
}

/// Retries the face scanning session after a failure.
class RetryFaceScanSession extends FaceScanEvent {
  /// Session ID to retry
  final String sessionId;

  const RetryFaceScanSession({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];

  @override
  String toString() => 'RetryFaceScanSession(sessionId: $sessionId)';
}

// ==================== Face Alignment Events ====================

/// Reports face detection results from the camera stream.
class FaceDetectionUpdated extends FaceScanEvent {
  /// Session ID for the detection update
  final String sessionId;
  
  /// Whether a face is currently detected
  final bool faceDetected;
  
  /// Face alignment state information
  final FaceAlignmentState alignmentState;

  const FaceDetectionUpdated({
    required this.sessionId,
    required this.faceDetected,
    required this.alignmentState,
  });

  @override
  List<Object?> get props => [sessionId, faceDetected, alignmentState];

  @override
  String toString() {
    return 'FaceDetectionUpdated('
        'sessionId: $sessionId, '
        'faceDetected: $faceDetected, '
        'alignmentState: $alignmentState'
        ')';
  }
}

/// Face alignment has been achieved and countdown should start.
class FaceAlignmentAchieved extends FaceScanEvent {
  /// Session ID for the alignment achievement
  final String sessionId;
  
  /// Alignment state when achieved
  final FaceAlignmentState alignmentState;

  const FaceAlignmentAchieved({
    required this.sessionId,
    required this.alignmentState,
  });

  @override
  List<Object?> get props => [sessionId, alignmentState];

  @override
  String toString() {
    return 'FaceAlignmentAchieved('
        'sessionId: $sessionId, '
        'alignmentState: $alignmentState'
        ')';
  }
}

/// Face alignment has been lost and countdown should stop.
class FaceAlignmentLost extends FaceScanEvent {
  /// Session ID for the alignment loss
  final String sessionId;
  
  /// New alignment state after loss
  final FaceAlignmentState alignmentState;

  const FaceAlignmentLost({
    required this.sessionId,
    required this.alignmentState,
  });

  @override
  List<Object?> get props => [sessionId, alignmentState];

  @override
  String toString() {
    return 'FaceAlignmentLost('
        'sessionId: $sessionId, '
        'alignmentState: $alignmentState'
        ')';
  }
}

/// Countdown timer tick during alignment countdown.
class CountdownTick extends FaceScanEvent {
  /// Session ID for the countdown
  final String sessionId;
  
  /// Current countdown value
  final int currentCount;
  
  /// Whether face is still aligned during this tick
  final bool faceStillAligned;

  const CountdownTick({
    required this.sessionId,
    required this.currentCount,
    required this.faceStillAligned,
  });

  @override
  List<Object?> get props => [sessionId, currentCount, faceStillAligned];

  @override
  String toString() {
    return 'CountdownTick('
        'sessionId: $sessionId, '
        'currentCount: $currentCount, '
        'faceStillAligned: $faceStillAligned'
        ')';
  }
}

// ==================== Image Capture Events ====================

/// Requests image capture when countdown reaches zero.
class CaptureImageRequested extends FaceScanEvent {
  /// Session ID for the capture request
  final String sessionId;
  
  /// Whether to force capture even if alignment is questionable
  final bool forceCapture;

  const CaptureImageRequested({
    required this.sessionId,
    this.forceCapture = false,
  });

  @override
  List<Object?> get props => [sessionId, forceCapture];

  @override
  String toString() {
    return 'CaptureImageRequested('
        'sessionId: $sessionId, '
        'forceCapture: $forceCapture'
        ')';
  }
}

/// Image capture has completed successfully.
class ImageCaptured extends FaceScanEvent {
  /// Session ID for the capture
  final String sessionId;
  
  /// Path to the captured image file
  final String imagePath;
  
  /// Image size in bytes
  final int imageSizeBytes;

  const ImageCaptured({
    required this.sessionId,
    required this.imagePath,
    required this.imageSizeBytes,
  });

  @override
  List<Object?> get props => [sessionId, imagePath, imageSizeBytes];

  @override
  String toString() {
    return 'ImageCaptured('
        'sessionId: $sessionId, '
        'imagePath: $imagePath, '
        'imageSizeBytes: $imageSizeBytes'
        ')';
  }
}

/// Image capture failed for some reason.
class ImageCaptureFailed extends FaceScanEvent {
  /// Session ID for the failed capture
  final String sessionId;
  
  /// Error message describing the failure
  final String errorMessage;
  
  /// Whether this failure is recoverable
  final bool isRecoverable;

  const ImageCaptureFailed({
    required this.sessionId,
    required this.errorMessage,
    this.isRecoverable = true,
  });

  @override
  List<Object?> get props => [sessionId, errorMessage, isRecoverable];

  @override
  String toString() {
    return 'ImageCaptureFailed('
        'sessionId: $sessionId, '
        'errorMessage: $errorMessage, '
        'isRecoverable: $isRecoverable'
        ')';
  }
}

// ==================== AI Analysis Events ====================

/// Starts AI analysis of the captured image.
class StartImageAnalysis extends FaceScanEvent {
  /// Session ID for the analysis
  final String sessionId;
  
  /// Path to the image to analyze
  final String imagePath;
  
  /// Whether to include annotated image in response
  final bool includeAnnotatedImage;

  const StartImageAnalysis({
    required this.sessionId,
    required this.imagePath,
    this.includeAnnotatedImage = true,
  });

  @override
  List<Object?> get props => [sessionId, imagePath, includeAnnotatedImage];

  @override
  String toString() {
    return 'StartImageAnalysis('
        'sessionId: $sessionId, '
        'imagePath: $imagePath, '
        'includeAnnotatedImage: $includeAnnotatedImage'
        ')';
  }
}

/// AI analysis has completed successfully.
class AnalysisCompleted extends FaceScanEvent {
  /// Session ID for the completed analysis
  final String sessionId;
  
  /// Raw analysis response data
  final Map<String, dynamic> analysisData;
  
  /// Processing time in milliseconds
  final int processingTimeMs;

  const AnalysisCompleted({
    required this.sessionId,
    required this.analysisData,
    required this.processingTimeMs,
  });

  @override
  List<Object?> get props => [sessionId, analysisData, processingTimeMs];

  @override
  String toString() {
    return 'AnalysisCompleted('
        'sessionId: $sessionId, '
        'analysisData keys: ${analysisData.keys.toList()}, '
        'processingTimeMs: $processingTimeMs'
        ')';
  }
}

/// AI analysis failed due to an error.
class AnalysisFailed extends FaceScanEvent {
  /// Session ID for the failed analysis
  final String sessionId;
  
  /// Error message from the analysis service
  final String errorMessage;
  
  /// HTTP status code if applicable
  final int? statusCode;
  
  /// Whether this failure is retryable
  final bool isRetryable;
  
  /// Additional error context
  final Map<String, dynamic> errorContext;

  const AnalysisFailed({
    required this.sessionId,
    required this.errorMessage,
    this.statusCode,
    this.isRetryable = true,
    this.errorContext = const {},
  });

  @override
  List<Object?> get props => [
    sessionId,
    errorMessage,
    statusCode,
    isRetryable,
    errorContext,
  ];

  @override
  String toString() {
    return 'AnalysisFailed('
        'sessionId: $sessionId, '
        'errorMessage: $errorMessage, '
        'statusCode: $statusCode, '
        'isRetryable: $isRetryable, '
        'errorContext: $errorContext'
        ')';
  }
}

// ==================== Retry and Recovery Events ====================

/// Retries the last failed operation.
class RetryLastOperation extends FaceScanEvent {
  /// Session ID to retry operation for
  final String sessionId;

  const RetryLastOperation({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];

  @override
  String toString() => 'RetryLastOperation(sessionId: $sessionId)';
}

/// Clears any current error state and returns to ready state.
class ClearError extends FaceScanEvent {
  /// Session ID to clear error for
  final String sessionId;

  const ClearError({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];

  @override
  String toString() => 'ClearError(sessionId: $sessionId)';
}

// ==================== Session Lifecycle Events ====================

/// Completes the face scanning session successfully.
class CompleteFaceScanSession extends FaceScanEvent {
  /// Session ID to complete
  final String sessionId;

  const CompleteFaceScanSession({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];

  @override
  String toString() => 'CompleteFaceScanSession(sessionId: $sessionId)';
}

/// Disposes of the face scanning session and cleans up resources.
class DisposeFaceScanSession extends FaceScanEvent {
  /// Session ID to dispose
  final String sessionId;

  const DisposeFaceScanSession({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];

  @override
  String toString() => 'DisposeFaceScanSession(sessionId: $sessionId)';
}