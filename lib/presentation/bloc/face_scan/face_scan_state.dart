import 'package:equatable/equatable.dart';
import 'package:camera/camera.dart';
import '../../../domain/face_scan/entities/face_scan_result.dart';
import '../../../domain/face_scan/entities/camera_scan_session.dart';

/// Base class for all face scanning states.
/// Implements a clean state machine approach replacing the complex boolean logic
/// from the original implementation.
abstract class FaceScanState extends Equatable {
  const FaceScanState();
  
  @override
  List<Object?> get props => [];
}

// ==================== Initial and Loading States ====================

/// Initial state when face scan bloc is first created.
class FaceScanInitial extends FaceScanState {
  const FaceScanInitial();

  @override
  String toString() => 'FaceScanInitial()';
}

/// Loading state when initializing a face scan session.
class FaceScanInitializing extends FaceScanState {
  /// User ID for the session being initialized
  final String userId;
  
  /// Progress message for user feedback
  final String progressMessage;

  const FaceScanInitializing({
    required this.userId,
    this.progressMessage = 'Initializing camera...',
  });

  @override
  List<Object?> get props => [userId, progressMessage];

  @override
  String toString() {
    return 'FaceScanInitializing(userId: $userId, progressMessage: $progressMessage)';
  }
}

// ==================== Camera Ready States ====================

/// Camera is ready and user should align their face.
class FaceScanCameraReady extends FaceScanState {
  /// Active camera scan session
  final CameraScanSession session;
  
  /// Camera controller for preview
  final CameraController cameraController;
  
  /// Available cameras list
  final List<CameraDescription> availableCameras;

  const FaceScanCameraReady({
    required this.session,
    required this.cameraController,
    required this.availableCameras,
  });

  @override
  List<Object?> get props => [session, cameraController, availableCameras];

  @override
  String toString() {
    return 'FaceScanCameraReady('
        'session: ${session.sessionId}, '
        'cameraController: ${cameraController.description.name}, '
        'availableCameras: ${availableCameras.length}'
        ')';
  }
}

// ==================== Face Alignment States ====================

/// User is aligning their face within the target area.
class FaceScanAligning extends FaceScanState {
  /// Current session state
  final CameraScanSession session;
  
  /// Camera controller for preview
  final CameraController cameraController;
  
  /// Current face alignment information
  final FaceAlignmentState alignmentState;
  
  /// Guidance message for the user
  final String guidanceMessage;

  const FaceScanAligning({
    required this.session,
    required this.cameraController,
    required this.alignmentState,
    this.guidanceMessage = 'Align your face inside the oval and look straight',
  });

  @override
  List<Object?> get props => [
    session,
    cameraController,
    alignmentState,
    guidanceMessage,
  ];

  @override
  String toString() {
    return 'FaceScanAligning('
        'session: ${session.sessionId}, '
        'alignmentState: $alignmentState, '
        'guidanceMessage: $guidanceMessage'
        ')';
  }
}

/// Face is properly aligned and countdown is in progress.
class FaceScanCountdown extends FaceScanState {
  /// Current session state
  final CameraScanSession session;
  
  /// Camera controller for preview
  final CameraController cameraController;
  
  /// Current face alignment state
  final FaceAlignmentState alignmentState;
  
  /// Current countdown value
  final int countdownValue;

  const FaceScanCountdown({
    required this.session,
    required this.cameraController,
    required this.alignmentState,
    required this.countdownValue,
  });

  @override
  List<Object?> get props => [
    session,
    cameraController,
    alignmentState,
    countdownValue,
  ];

  @override
  String toString() {
    return 'FaceScanCountdown('
        'session: ${session.sessionId}, '
        'alignmentState: $alignmentState, '
        'countdownValue: $countdownValue'
        ')';
  }
}

// ==================== Capture States ====================

/// Image is being captured from the camera.
class FaceScanCapturing extends FaceScanState {
  /// Current session state
  final CameraScanSession session;
  
  /// Camera controller used for capture
  final CameraController cameraController;

  const FaceScanCapturing({
    required this.session,
    required this.cameraController,
  });

  @override
  List<Object?> get props => [session, cameraController];

  @override
  String toString() {
    return 'FaceScanCapturing(session: ${session.sessionId})';
  }
}

/// Image has been captured successfully.
class FaceScanImageCaptured extends FaceScanState {
  /// Current session state
  final CameraScanSession session;
  
  /// Path to the captured image
  final String imagePath;
  
  /// Size of captured image in bytes
  final int imageSizeBytes;

  const FaceScanImageCaptured({
    required this.session,
    required this.imagePath,
    required this.imageSizeBytes,
  });

  @override
  List<Object?> get props => [session, imagePath, imageSizeBytes];

  @override
  String toString() {
    return 'FaceScanImageCaptured('
        'session: ${session.sessionId}, '
        'imagePath: $imagePath, '
        'imageSizeBytes: $imageSizeBytes'
        ')';
  }
}

// ==================== Processing States ====================

/// AI analysis is in progress.
class FaceScanProcessing extends FaceScanState {
  /// Current session state
  final CameraScanSession session;
  
  /// Path to captured image being processed
  final String imagePath;
  
  /// Processing progress message
  final String progressMessage;
  
  /// Processing start time for elapsed time calculation
  final DateTime processingStartTime;

  const FaceScanProcessing({
    required this.session,
    required this.imagePath,
    this.progressMessage = 'Analyzing your skin...',
    required this.processingStartTime,
  });

  /// Gets elapsed processing time in milliseconds
  int get elapsedProcessingTimeMs {
    return DateTime.now().difference(processingStartTime).inMilliseconds;
  }

  @override
  List<Object?> get props => [
    session,
    imagePath,
    progressMessage,
    processingStartTime,
  ];

  @override
  String toString() {
    return 'FaceScanProcessing('
        'session: ${session.sessionId}, '
        'imagePath: $imagePath, '
        'progressMessage: $progressMessage, '
        'elapsedMs: $elapsedProcessingTimeMs'
        ')';
  }
}

// ==================== Success States ====================

/// Face scan has completed successfully with results.
class FaceScanCompleted extends FaceScanState {
  /// Final scan result with all analysis data
  final FaceScanResult scanResult;
  
  /// Original captured image path
  final String originalImagePath;
  
  /// Whether annotated image is available
  final bool hasAnnotatedImage;

  const FaceScanCompleted({
    required this.scanResult,
    required this.originalImagePath,
    required this.hasAnnotatedImage,
  });

  @override
  List<Object?> get props => [
    scanResult,
    originalImagePath,
    hasAnnotatedImage,
  ];

  @override
  String toString() {
    return 'FaceScanCompleted('
        'scanResult: ${scanResult.scanId}, '
        'originalImagePath: $originalImagePath, '
        'hasAnnotatedImage: $hasAnnotatedImage'
        ')';
  }
}

// ==================== Error States ====================

/// Base class for all error states with common error handling properties.
abstract class FaceScanErrorState extends FaceScanState {
  /// Human-readable error message
  final String errorMessage;
  
  /// Whether this error is recoverable via retry
  final bool isRecoverable;
  
  /// Technical error details for debugging
  final Map<String, dynamic> errorDetails;
  
  /// Session that encountered the error (may be null for initialization errors)
  final CameraScanSession? session;

  const FaceScanErrorState({
    required this.errorMessage,
    required this.isRecoverable,
    this.errorDetails = const {},
    this.session,
  });

  @override
  List<Object?> get props => [
    errorMessage,
    isRecoverable,
    errorDetails,
    session,
  ];
}

/// Camera initialization failed.
class FaceScanCameraInitializationFailed extends FaceScanErrorState {
  /// User ID that requested the session
  final String userId;

  const FaceScanCameraInitializationFailed({
    required this.userId,
    required super.errorMessage,
    super.isRecoverable = true,
    super.errorDetails = const {},
  });

  @override
  List<Object?> get props => [userId, ...super.props];

  @override
  String toString() {
    return 'FaceScanCameraInitializationFailed('
        'userId: $userId, '
        'errorMessage: $errorMessage, '
        'isRecoverable: $isRecoverable'
        ')';
  }
}

/// Camera permission was denied.
class FaceScanPermissionDenied extends FaceScanErrorState {
  /// Whether this is a permanent denial or temporary
  final bool isPermanent;

  const FaceScanPermissionDenied({
    required super.errorMessage,
    required this.isPermanent,
    super.isRecoverable = true,
  });

  @override
  List<Object?> get props => [isPermanent, ...super.props];

  @override
  String toString() {
    return 'FaceScanPermissionDenied('
        'errorMessage: $errorMessage, '
        'isPermanent: $isPermanent, '
        'isRecoverable: $isRecoverable'
        ')';
  }
}

/// Image capture failed.
class FaceScanCaptureFailed extends FaceScanErrorState {
  const FaceScanCaptureFailed({
    required super.session,
    required super.errorMessage,
    super.isRecoverable = true,
    super.errorDetails = const {},
  });

  @override
  String toString() {
    return 'FaceScanCaptureFailed('
        'session: ${session?.sessionId}, '
        'errorMessage: $errorMessage, '
        'isRecoverable: $isRecoverable'
        ')';
  }
}

/// AI analysis failed due to network, server, or processing issues.
class FaceScanAnalysisFailed extends FaceScanErrorState {
  /// HTTP status code if this was a network error
  final int? statusCode;
  
  /// Path to the image that failed analysis
  final String imagePath;
  
  /// Analysis processing time before failure
  final int processingTimeMs;

  const FaceScanAnalysisFailed({
    required super.session,
    required super.errorMessage,
    required this.imagePath,
    required this.processingTimeMs,
    this.statusCode,
    super.isRecoverable = true,
    super.errorDetails = const {},
  });

  @override
  List<Object?> get props => [
    statusCode,
    imagePath,
    processingTimeMs,
    ...super.props,
  ];

  @override
  String toString() {
    return 'FaceScanAnalysisFailed('
        'session: ${session?.sessionId}, '
        'errorMessage: $errorMessage, '
        'statusCode: $statusCode, '
        'imagePath: $imagePath, '
        'processingTimeMs: $processingTimeMs, '
        'isRecoverable: $isRecoverable'
        ')';
  }
}

/// Session timed out during any phase.
class FaceScanTimeout extends FaceScanErrorState {
  /// Phase where timeout occurred
  final String timeoutPhase;
  
  /// Timeout duration in milliseconds
  final int timeoutDurationMs;

  const FaceScanTimeout({
    required super.session,
    required this.timeoutPhase,
    required this.timeoutDurationMs,
    super.errorMessage = 'Operation timed out',
    super.isRecoverable = true,
  });

  @override
  List<Object?> get props => [
    timeoutPhase,
    timeoutDurationMs,
    ...super.props,
  ];

  @override
  String toString() {
    return 'FaceScanTimeout('
        'session: ${session?.sessionId}, '
        'timeoutPhase: $timeoutPhase, '
        'timeoutDurationMs: $timeoutDurationMs, '
        'errorMessage: $errorMessage'
        ')';
  }
}

/// Face scan session was cancelled by user.
class FaceScanCancelled extends FaceScanState {
  /// Session that was cancelled
  final CameraScanSession? session;
  
  /// Reason for cancellation
  final String? reason;

  const FaceScanCancelled({
    this.session,
    this.reason,
  });

  @override
  List<Object?> get props => [session, reason];

  @override
  String toString() {
    return 'FaceScanCancelled('
        'session: ${session?.sessionId}, '
        'reason: $reason'
        ')';
  }
}

// ==================== State Helper Extensions ====================

/// Extension methods for easier state checking and transitions
extension FaceScanStateExtensions on FaceScanState {
  /// Whether the current state represents an active camera session
  bool get hasActiveCamera {
    return this is FaceScanCameraReady ||
           this is FaceScanAligning ||
           this is FaceScanCountdown ||
           this is FaceScanCapturing;
  }

  /// Whether the current state represents an error condition
  bool get isError => this is FaceScanErrorState;

  /// Whether the current state allows retry operations
  bool get canRetry {
    if (this is FaceScanErrorState) {
      return (this as FaceScanErrorState).isRecoverable;
    }
    return false;
  }

  /// Whether the current state represents active processing
  bool get isProcessing {
    return this is FaceScanInitializing ||
           this is FaceScanProcessing ||
           this is FaceScanCapturing;
  }

  /// Whether the current state represents successful completion
  bool get isCompleted => this is FaceScanCompleted;

  /// Whether the current state was cancelled
  bool get isCancelled => this is FaceScanCancelled;

  /// Gets the session from states that have one
  CameraScanSession? get session {
    if (this is FaceScanCameraReady) {
      return (this as FaceScanCameraReady).session;
    } else if (this is FaceScanAligning) {
      return (this as FaceScanAligning).session;
    } else if (this is FaceScanCountdown) {
      return (this as FaceScanCountdown).session;
    } else if (this is FaceScanCapturing) {
      return (this as FaceScanCapturing).session;
    } else if (this is FaceScanImageCaptured) {
      return (this as FaceScanImageCaptured).session;
    } else if (this is FaceScanProcessing) {
      return (this as FaceScanProcessing).session;
    } else if (this is FaceScanErrorState) {
      return (this as FaceScanErrorState).session;
    } else if (this is FaceScanCancelled) {
      return (this as FaceScanCancelled).session;
    }
    return null;
  }

  /// Gets the camera controller from states that have one
  CameraController? get cameraController {
    if (this is FaceScanCameraReady) {
      return (this as FaceScanCameraReady).cameraController;
    } else if (this is FaceScanAligning) {
      return (this as FaceScanAligning).cameraController;
    } else if (this is FaceScanCountdown) {
      return (this as FaceScanCountdown).cameraController;
    } else if (this is FaceScanCapturing) {
      return (this as FaceScanCapturing).cameraController;
    }
    return null;
  }

  /// Gets user-friendly status message for the current state
  String get statusMessage {
    if (this is FaceScanInitial) {
      return 'Ready to scan';
    } else if (this is FaceScanInitializing) {
      return (this as FaceScanInitializing).progressMessage;
    } else if (this is FaceScanCameraReady) {
      return 'Camera ready';
    } else if (this is FaceScanAligning) {
      return (this as FaceScanAligning).guidanceMessage;
    } else if (this is FaceScanCountdown) {
      final countdown = (this as FaceScanCountdown).countdownValue;
      return countdown > 0 ? '$countdown' : 'Capturing...';
    } else if (this is FaceScanCapturing) {
      return 'Capturing image...';
    } else if (this is FaceScanImageCaptured) {
      return 'Image captured';
    } else if (this is FaceScanProcessing) {
      return (this as FaceScanProcessing).progressMessage;
    } else if (this is FaceScanCompleted) {
      return 'Analysis complete';
    } else if (this is FaceScanErrorState) {
      return (this as FaceScanErrorState).errorMessage;
    } else if (this is FaceScanCancelled) {
      return 'Scan cancelled';
    }
    return 'Unknown state';
  }
}