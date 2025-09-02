import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show Size;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../domain/face_scan/entities/camera_scan_session.dart';
import 'face_alignment_event.dart';

/// Base class for all face alignment states.
/// Represents the current state of face detection and alignment validation.
abstract class FaceAlignmentState extends Equatable {
  const FaceAlignmentState();
  
  @override
  List<Object?> get props => [];
}

// ==================== Initial State ====================

/// Initial state when face alignment detection is not active.
class FaceAlignmentInitial extends FaceAlignmentState {
  const FaceAlignmentInitial();

  @override
  String toString() => 'FaceAlignmentInitial()';
}

// ==================== Detection Active States ====================

/// Face alignment detection is active and monitoring for faces.
class FaceAlignmentDetectionActive extends FaceAlignmentState {
  /// Session ID being monitored
  final String sessionId;
  
  /// Tolerance settings being used for alignment validation
  final FaceAlignmentTolerance toleranceSettings;
  
  /// When detection started
  final DateTime detectionStartTime;
  
  /// Number of frames processed since detection started
  final int framesProcessed;

  const FaceAlignmentDetectionActive({
    required this.sessionId,
    required this.toleranceSettings,
    required this.detectionStartTime,
    this.framesProcessed = 0,
  });

  @override
  List<Object?> get props => [
    sessionId,
    toleranceSettings,
    detectionStartTime,
    framesProcessed,
  ];

  @override
  String toString() {
    return 'FaceAlignmentDetectionActive('
        'sessionId: $sessionId, '
        'tolerance: $toleranceSettings, '
        'framesProcessed: $framesProcessed'
        ')';
  }
}

/// No face is currently detected in the camera frame.
class FaceAlignmentNoFaceDetected extends FaceAlignmentState {
  /// Session ID being monitored
  final String sessionId;
  
  /// How long no face has been detected (in seconds)
  final double noFaceDuration;
  
  /// Last detection timestamp
  final DateTime lastCheckTime;
  
  /// Guidance message for user
  final String guidanceMessage;

  const FaceAlignmentNoFaceDetected({
    required this.sessionId,
    required this.noFaceDuration,
    required this.lastCheckTime,
    this.guidanceMessage = 'Position your face in front of the camera',
  });

  @override
  List<Object?> get props => [
    sessionId,
    noFaceDuration,
    lastCheckTime,
    guidanceMessage,
  ];

  @override
  String toString() {
    return 'FaceAlignmentNoFaceDetected('
        'sessionId: $sessionId, '
        'noFaceDuration: ${noFaceDuration.toStringAsFixed(1)}s, '
        'guidanceMessage: $guidanceMessage'
        ')';
  }
}

// ==================== Face Detected States ====================

/// Face detected but not properly aligned.
class FaceAlignmentDetectedButNotAligned extends FaceAlignmentState {
  /// Session ID being monitored
  final String sessionId;
  
  /// Currently detected face
  final Face detectedFace;
  
  /// Current face alignment state
  final FaceAlignmentState currentAlignmentState;
  
  /// Specific alignment issues preventing proper alignment
  final List<AlignmentIssue> alignmentIssues;
  
  /// Primary guidance message for the most critical issue
  final String primaryGuidanceMessage;
  
  /// All guidance messages for current issues
  final List<String> allGuidanceMessages;
  
  /// Last detection timestamp
  final DateTime detectionTime;

  const FaceAlignmentDetectedButNotAligned({
    required this.sessionId,
    required this.detectedFace,
    required this.currentAlignmentState,
    required this.alignmentIssues,
    required this.primaryGuidanceMessage,
    required this.allGuidanceMessages,
    required this.detectionTime,
  });

  @override
  List<Object?> get props => [
    sessionId,
    detectedFace,
    currentAlignmentState,
    alignmentIssues,
    primaryGuidanceMessage,
    allGuidanceMessages,
    detectionTime,
  ];

  @override
  String toString() {
    return 'FaceAlignmentDetectedButNotAligned('
        'sessionId: $sessionId, '
        'issues: ${alignmentIssues.length}, '
        'primaryGuidance: $primaryGuidanceMessage'
        ')';
  }
}

/// Face is detected and properly aligned.
class FaceAlignmentAligned extends FaceAlignmentState {
  /// Session ID being monitored
  final String sessionId;
  
  /// Properly aligned face
  final Face alignedFace;
  
  /// Current face alignment state with alignment data
  final FaceAlignmentState alignmentState;
  
  /// How long face has been aligned (in seconds)
  final double alignmentDuration;
  
  /// Whether alignment is stable enough for capture
  final bool isStableForCapture;
  
  /// Confirmation message for user
  final String confirmationMessage;
  
  /// When alignment was first achieved
  final DateTime alignmentStartTime;
  
  /// Most recent alignment validation time
  final DateTime lastValidationTime;

  const FaceAlignmentAligned({
    required this.sessionId,
    required this.alignedFace,
    required this.alignmentState,
    required this.alignmentDuration,
    required this.isStableForCapture,
    this.confirmationMessage = 'Perfect! Hold still...',
    required this.alignmentStartTime,
    required this.lastValidationTime,
  });

  @override
  List<Object?> get props => [
    sessionId,
    alignedFace,
    alignmentState,
    alignmentDuration,
    isStableForCapture,
    confirmationMessage,
    alignmentStartTime,
    lastValidationTime,
  ];

  @override
  String toString() {
    return 'FaceAlignmentAligned('
        'sessionId: $sessionId, '
        'duration: ${alignmentDuration.toStringAsFixed(1)}s, '
        'stableForCapture: $isStableForCapture, '
        'message: $confirmationMessage'
        ')';
  }
}

/// Multiple faces detected - alignment not possible.
class FaceAlignmentMultipleFacesDetected extends FaceAlignmentState {
  /// Session ID being monitored
  final String sessionId;
  
  /// All detected faces
  final List<Face> detectedFaces;
  
  /// Detection timestamp
  final DateTime detectionTime;
  
  /// Guidance message for resolving multiple faces
  final String guidanceMessage;

  const FaceAlignmentMultipleFacesDetected({
    required this.sessionId,
    required this.detectedFaces,
    required this.detectionTime,
    this.guidanceMessage = 'Multiple faces detected - ensure only one person is visible',
  });

  @override
  List<Object?> get props => [
    sessionId,
    detectedFaces,
    detectionTime,
    guidanceMessage,
  ];

  @override
  String toString() {
    return 'FaceAlignmentMultipleFacesDetected('
        'sessionId: $sessionId, '
        'faceCount: ${detectedFaces.length}, '
        'guidanceMessage: $guidanceMessage'
        ')';
  }
}

// ==================== Processing States ====================

/// Face alignment validation is in progress.
class FaceAlignmentValidating extends FaceAlignmentState {
  /// Session ID being validated
  final String sessionId;
  
  /// Face being validated
  final Face faceBeingValidated;
  
  /// Progress message
  final String progressMessage;
  
  /// Validation start time
  final DateTime validationStartTime;

  const FaceAlignmentValidating({
    required this.sessionId,
    required this.faceBeingValidated,
    this.progressMessage = 'Validating face alignment...',
    required this.validationStartTime,
  });

  @override
  List<Object?> get props => [
    sessionId,
    faceBeingValidated,
    progressMessage,
    validationStartTime,
  ];

  @override
  String toString() {
    return 'FaceAlignmentValidating('
        'sessionId: $sessionId, '
        'progressMessage: $progressMessage'
        ')';
  }
}

/// Frame processing is in progress.
class FaceAlignmentProcessingFrame extends FaceAlignmentState {
  /// Session ID being processed
  final String sessionId;
  
  /// Processing start time
  final DateTime processingStartTime;
  
  /// Frame number being processed
  final int frameNumber;

  const FaceAlignmentProcessingFrame({
    required this.sessionId,
    required this.processingStartTime,
    required this.frameNumber,
  });

  @override
  List<Object?> get props => [sessionId, processingStartTime, frameNumber];

  @override
  String toString() {
    return 'FaceAlignmentProcessingFrame(sessionId: $sessionId, frame: $frameNumber)';
  }
}

// ==================== Error States ====================

/// Face detection processing failed.
class FaceAlignmentDetectionFailed extends FaceAlignmentState {
  /// Session ID where detection failed
  final String sessionId;
  
  /// Error message
  final String errorMessage;
  
  /// Whether the error is recoverable
  final bool isRecoverable;
  
  /// Error occurrence time
  final DateTime errorTime;
  
  /// Additional error context
  final Map<String, dynamic> errorContext;

  const FaceAlignmentDetectionFailed({
    required this.sessionId,
    required this.errorMessage,
    this.isRecoverable = true,
    required this.errorTime,
    this.errorContext = const {},
  });

  @override
  List<Object?> get props => [
    sessionId,
    errorMessage,
    isRecoverable,
    errorTime,
    errorContext,
  ];

  @override
  String toString() {
    return 'FaceAlignmentDetectionFailed('
        'sessionId: $sessionId, '
        'error: $errorMessage, '
        'recoverable: $isRecoverable'
        ')';
  }
}

/// Detection timeout occurred.
class FaceAlignmentTimeout extends FaceAlignmentState {
  /// Session ID that timed out
  final String sessionId;
  
  /// Timeout duration that was exceeded
  final Duration timeoutDuration;
  
  /// When timeout occurred
  final DateTime timeoutTime;
  
  /// What phase timed out
  final String timeoutPhase;

  const FaceAlignmentTimeout({
    required this.sessionId,
    required this.timeoutDuration,
    required this.timeoutTime,
    this.timeoutPhase = 'alignment_detection',
  });

  @override
  List<Object?> get props => [
    sessionId,
    timeoutDuration,
    timeoutTime,
    timeoutPhase,
  ];

  @override
  String toString() {
    return 'FaceAlignmentTimeout('
        'sessionId: $sessionId, '
        'timeout: $timeoutDuration, '
        'phase: $timeoutPhase'
        ')';
  }
}

// ==================== Completed States ====================

/// Face alignment detection stopped.
class FaceAlignmentDetectionStopped extends FaceAlignmentState {
  /// Session ID that was stopped
  final String sessionId;
  
  /// Reason for stopping
  final String stopReason;
  
  /// When detection stopped
  final DateTime stopTime;
  
  /// Final alignment state when stopped
  final FaceAlignmentState? finalAlignmentState;

  const FaceAlignmentDetectionStopped({
    required this.sessionId,
    this.stopReason = 'Detection stopped by request',
    required this.stopTime,
    this.finalAlignmentState,
  });

  @override
  List<Object?> get props => [
    sessionId,
    stopReason,
    stopTime,
    finalAlignmentState,
  ];

  @override
  String toString() {
    return 'FaceAlignmentDetectionStopped('
        'sessionId: $sessionId, '
        'reason: $stopReason'
        ')';
  }
}

// ==================== Configuration States ====================

/// Alignment tolerance settings updated.
class FaceAlignmentToleranceUpdated extends FaceAlignmentState {
  /// Session ID that was updated
  final String sessionId;
  
  /// Previous tolerance settings
  final FaceAlignmentTolerance previousTolerance;
  
  /// New tolerance settings
  final FaceAlignmentTolerance newTolerance;
  
  /// When tolerance was updated
  final DateTime updateTime;

  const FaceAlignmentToleranceUpdated({
    required this.sessionId,
    required this.previousTolerance,
    required this.newTolerance,
    required this.updateTime,
  });

  @override
  List<Object?> get props => [
    sessionId,
    previousTolerance,
    newTolerance,
    updateTime,
  ];

  @override
  String toString() {
    return 'FaceAlignmentToleranceUpdated('
        'sessionId: $sessionId, '
        'newTolerance: $newTolerance'
        ')';
  }
}

// ==================== State Extension Helpers ====================

extension FaceAlignmentStateExtensions on FaceAlignmentState {
  /// Whether face alignment detection is currently active
  bool get isDetectionActive {
    return this is FaceAlignmentDetectionActive ||
           this is FaceAlignmentNoFaceDetected ||
           this is FaceAlignmentDetectedButNotAligned ||
           this is FaceAlignmentAligned ||
           this is FaceAlignmentMultipleFacesDetected ||
           this is FaceAlignmentValidating ||
           this is FaceAlignmentProcessingFrame;
  }

  /// Whether a face is currently detected
  bool get isFaceDetected {
    return this is FaceAlignmentDetectedButNotAligned ||
           this is FaceAlignmentAligned ||
           this is FaceAlignmentMultipleFacesDetected ||
           this is FaceAlignmentValidating;
  }

  /// Whether face is currently aligned
  bool get isAligned => this is FaceAlignmentAligned;

  /// Whether face is stable enough for capture
  bool get isStableForCapture {
    if (this is FaceAlignmentAligned) {
      return (this as FaceAlignmentAligned).isStableForCapture;
    }
    return false;
  }

  /// Whether an error has occurred
  bool get hasError {
    return this is FaceAlignmentDetectionFailed ||
           this is FaceAlignmentTimeout;
  }

  /// Whether the current error (if any) is recoverable
  bool get canRetry {
    if (this is FaceAlignmentDetectionFailed) {
      return (this as FaceAlignmentDetectionFailed).isRecoverable;
    }
    if (this is FaceAlignmentTimeout) {
      return true; // Timeouts are generally recoverable
    }
    return false;
  }

  /// Gets the session ID if available
  String? get sessionId {
    if (this is FaceAlignmentDetectionActive) {
      return (this as FaceAlignmentDetectionActive).sessionId;
    } else if (this is FaceAlignmentNoFaceDetected) {
      return (this as FaceAlignmentNoFaceDetected).sessionId;
    } else if (this is FaceAlignmentDetectedButNotAligned) {
      return (this as FaceAlignmentDetectedButNotAligned).sessionId;
    } else if (this is FaceAlignmentAligned) {
      return (this as FaceAlignmentAligned).sessionId;
    } else if (this is FaceAlignmentMultipleFacesDetected) {
      return (this as FaceAlignmentMultipleFacesDetected).sessionId;
    } else if (this is FaceAlignmentValidating) {
      return (this as FaceAlignmentValidating).sessionId;
    } else if (this is FaceAlignmentProcessingFrame) {
      return (this as FaceAlignmentProcessingFrame).sessionId;
    } else if (this is FaceAlignmentDetectionFailed) {
      return (this as FaceAlignmentDetectionFailed).sessionId;
    } else if (this is FaceAlignmentTimeout) {
      return (this as FaceAlignmentTimeout).sessionId;
    } else if (this is FaceAlignmentDetectionStopped) {
      return (this as FaceAlignmentDetectionStopped).sessionId;
    }
    return null;
  }

  /// Gets the primary guidance message for the current state
  String get guidanceMessage {
    if (this is FaceAlignmentNoFaceDetected) {
      return (this as FaceAlignmentNoFaceDetected).guidanceMessage;
    } else if (this is FaceAlignmentDetectedButNotAligned) {
      return (this as FaceAlignmentDetectedButNotAligned).primaryGuidanceMessage;
    } else if (this is FaceAlignmentAligned) {
      return (this as FaceAlignmentAligned).confirmationMessage;
    } else if (this is FaceAlignmentMultipleFacesDetected) {
      return (this as FaceAlignmentMultipleFacesDetected).guidanceMessage;
    } else if (this is FaceAlignmentValidating) {
      return (this as FaceAlignmentValidating).progressMessage;
    } else if (this is FaceAlignmentDetectionFailed) {
      return (this as FaceAlignmentDetectionFailed).errorMessage;
    } else if (this is FaceAlignmentTimeout) {
      return 'Detection timed out. Please try again.';
    } else if (this is FaceAlignmentDetectionActive) {
      return 'Position your face in the camera view';
    }
    return 'Initializing face detection...';
  }

  /// Gets the detected face if available
  Face? get detectedFace {
    if (this is FaceAlignmentDetectedButNotAligned) {
      return (this as FaceAlignmentDetectedButNotAligned).detectedFace;
    } else if (this is FaceAlignmentAligned) {
      return (this as FaceAlignmentAligned).alignedFace;
    } else if (this is FaceAlignmentValidating) {
      return (this as FaceAlignmentValidating).faceBeingValidated;
    } else if (this is FaceAlignmentMultipleFacesDetected) {
      final faces = (this as FaceAlignmentMultipleFacesDetected).detectedFaces;
      return faces.isNotEmpty ? faces.first : null;
    }
    return null;
  }

  /// Gets alignment issues if available
  List<AlignmentIssue> get alignmentIssues {
    if (this is FaceAlignmentDetectedButNotAligned) {
      return (this as FaceAlignmentDetectedButNotAligned).alignmentIssues;
    } else if (this is FaceAlignmentNoFaceDetected) {
      return [AlignmentIssue.noFaceDetected];
    } else if (this is FaceAlignmentMultipleFacesDetected) {
      return [AlignmentIssue.multipleFaces];
    }
    return [];
  }

  /// Gets alignment duration if available
  double get alignmentDuration {
    if (this is FaceAlignmentAligned) {
      return (this as FaceAlignmentAligned).alignmentDuration;
    } else if (this is FaceAlignmentNoFaceDetected) {
      return (this as FaceAlignmentNoFaceDetected).noFaceDuration;
    }
    return 0.0;
  }

  /// Gets status message for current state
  String get statusMessage {
    if (isAligned) {
      return 'Face aligned - ready for capture';
    } else if (isFaceDetected) {
      return 'Face detected - align properly';
    } else if (isDetectionActive) {
      return 'Looking for face...';
    } else if (hasError) {
      return 'Detection error occurred';
    } else {
      return 'Face detection not active';
    }
  }
}