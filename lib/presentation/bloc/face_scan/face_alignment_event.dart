import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show Size;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../domain/face_scan/entities/camera_scan_session.dart';

/// Base class for all face alignment related events.
/// This BLoC focuses specifically on real-time face detection and alignment validation.
abstract class FaceAlignmentEvent extends Equatable {
  const FaceAlignmentEvent();
  
  @override
  List<Object?> get props => [];
}

// ==================== Alignment Detection Events ====================

/// Starts face alignment detection for a session.
class StartFaceAlignmentDetection extends FaceAlignmentEvent {
  /// Session ID to start alignment detection for
  final String sessionId;
  
  /// Alignment tolerance settings to use
  final FaceAlignmentTolerance toleranceSettings;

  const StartFaceAlignmentDetection({
    required this.sessionId,
    required this.toleranceSettings,
  });

  @override
  List<Object?> get props => [sessionId, toleranceSettings];

  @override
  String toString() {
    return 'StartFaceAlignmentDetection(sessionId: $sessionId, tolerance: $toleranceSettings)';
  }
}

/// Stops face alignment detection for a session.
class StopFaceAlignmentDetection extends FaceAlignmentEvent {
  /// Session ID to stop alignment detection for
  final String sessionId;

  const StopFaceAlignmentDetection({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];

  @override
  String toString() => 'StopFaceAlignmentDetection(sessionId: $sessionId)';
}

/// Reports new face detection results from camera frame processing.
class FaceDetectionResultReceived extends FaceAlignmentEvent {
  /// Session ID for the detection result
  final String sessionId;
  
  /// List of detected faces in the frame
  final List<Face> detectedFaces;
  
  /// Timestamp when the detection occurred
  final DateTime detectionTimestamp;
  
  /// Camera preview size for coordinate mapping
  final Size previewSize;

  const FaceDetectionResultReceived({
    required this.sessionId,
    required this.detectedFaces,
    required this.detectionTimestamp,
    required this.previewSize,
  });

  @override
  List<Object?> get props => [
    sessionId,
    detectedFaces,
    detectionTimestamp,
    previewSize,
  ];

  @override
  String toString() {
    return 'FaceDetectionResultReceived('
        'sessionId: $sessionId, '
        'faces: ${detectedFaces.length}, '
        'timestamp: $detectionTimestamp, '
        'previewSize: $previewSize'
        ')';
  }
}

/// Reports that no faces were detected in the current frame.
class NoFaceDetected extends FaceAlignmentEvent {
  /// Session ID for the detection result
  final String sessionId;
  
  /// Timestamp when no faces were detected
  final DateTime detectionTimestamp;

  const NoFaceDetected({
    required this.sessionId,
    required this.detectionTimestamp,
  });

  @override
  List<Object?> get props => [sessionId, detectionTimestamp];

  @override
  String toString() {
    return 'NoFaceDetected(sessionId: $sessionId, timestamp: $detectionTimestamp)';
  }
}

// ==================== Alignment State Events ====================

/// Face alignment has been achieved and is stable.
class FaceAlignmentAchieved extends FaceAlignmentEvent {
  /// Session ID for the alignment achievement
  final String sessionId;
  
  /// Face angles that achieved alignment
  final FaceAngles alignedAngles;
  
  /// Face position that achieved alignment
  final FacePosition alignedPosition;
  
  /// How long alignment has been maintained (in seconds)
  final double alignmentDuration;

  const FaceAlignmentAchieved({
    required this.sessionId,
    required this.alignedAngles,
    required this.alignedPosition,
    required this.alignmentDuration,
  });

  @override
  List<Object?> get props => [
    sessionId,
    alignedAngles,
    alignedPosition,
    alignmentDuration,
  ];

  @override
  String toString() {
    return 'FaceAlignmentAchieved('
        'sessionId: $sessionId, '
        'angles: $alignedAngles, '
        'position: $alignedPosition, '
        'duration: ${alignmentDuration.toStringAsFixed(1)}s'
        ')';
  }
}

/// Face alignment has been lost and needs to be re-achieved.
class FaceAlignmentLost extends FaceAlignmentEvent {
  /// Session ID for the alignment loss
  final String sessionId;
  
  /// Reason why alignment was lost
  final AlignmentLossReason lossReason;
  
  /// Current face angles (if face is still detected)
  final FaceAngles? currentAngles;
  
  /// Current face position (if face is still detected)
  final FacePosition? currentPosition;

  const FaceAlignmentLost({
    required this.sessionId,
    required this.lossReason,
    this.currentAngles,
    this.currentPosition,
  });

  @override
  List<Object?> get props => [
    sessionId,
    lossReason,
    currentAngles,
    currentPosition,
  ];

  @override
  String toString() {
    return 'FaceAlignmentLost('
        'sessionId: $sessionId, '
        'reason: $lossReason, '
        'currentAngles: $currentAngles, '
        'currentPosition: $currentPosition'
        ')';
  }
}

/// Face alignment validation is in progress.
class FaceAlignmentValidating extends FaceAlignmentEvent {
  /// Session ID for the validation
  final String sessionId;
  
  /// Current face being validated
  final Face detectedFace;
  
  /// Current alignment state during validation
  final FaceAlignmentState alignmentState;

  const FaceAlignmentValidating({
    required this.sessionId,
    required this.detectedFace,
    required this.alignmentState,
  });

  @override
  List<Object?> get props => [sessionId, detectedFace, alignmentState];

  @override
  String toString() {
    return 'FaceAlignmentValidating('
        'sessionId: $sessionId, '
        'alignmentState: $alignmentState'
        ')';
  }
}

// ==================== Alignment Guidance Events ====================

/// Provides guidance to help user achieve proper face alignment.
class AlignmentGuidanceRequested extends FaceAlignmentEvent {
  /// Session ID requesting guidance
  final String sessionId;
  
  /// Current face detection result (if any)
  final Face? currentFace;
  
  /// Current alignment issues to guide user on
  final List<AlignmentIssue> alignmentIssues;

  const AlignmentGuidanceRequested({
    required this.sessionId,
    this.currentFace,
    required this.alignmentIssues,
  });

  @override
  List<Object?> get props => [sessionId, currentFace, alignmentIssues];

  @override
  String toString() {
    return 'AlignmentGuidanceRequested('
        'sessionId: $sessionId, '
        'hasFace: ${currentFace != null}, '
        'issues: ${alignmentIssues.length}'
        ')';
  }
}

// ==================== Alignment Configuration Events ====================

/// Updates the tolerance settings for face alignment validation.
class UpdateAlignmentTolerance extends FaceAlignmentEvent {
  /// Session ID to update tolerance for
  final String sessionId;
  
  /// New tolerance settings to apply
  final FaceAlignmentTolerance newTolerance;

  const UpdateAlignmentTolerance({
    required this.sessionId,
    required this.newTolerance,
  });

  @override
  List<Object?> get props => [sessionId, newTolerance];

  @override
  String toString() {
    return 'UpdateAlignmentTolerance(sessionId: $sessionId, tolerance: $newTolerance)';
  }
}

/// Resets the alignment state for a session.
class ResetAlignmentState extends FaceAlignmentEvent {
  /// Session ID to reset alignment for
  final String sessionId;

  const ResetAlignmentState({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];

  @override
  String toString() => 'ResetAlignmentState(sessionId: $sessionId)';
}

// ==================== Frame Processing Events ====================

/// Requests processing of a new camera frame for face detection.
class ProcessCameraFrame extends FaceAlignmentEvent {
  /// Session ID for the frame processing
  final String sessionId;
  
  /// Camera image data to process
  final dynamic cameraImageData; // CameraImage from camera package
  
  /// Camera description for coordinate mapping
  final dynamic cameraDescription; // CameraDescription
  
  /// Preview size for coordinate conversion
  final Size previewSize;

  const ProcessCameraFrame({
    required this.sessionId,
    required this.cameraImageData,
    required this.cameraDescription,
    required this.previewSize,
  });

  @override
  List<Object?> get props => [
    sessionId,
    cameraImageData,
    cameraDescription,
    previewSize,
  ];

  @override
  String toString() {
    return 'ProcessCameraFrame(sessionId: $sessionId, previewSize: $previewSize)';
  }
}

// ==================== Error Events ====================

/// Face detection processing failed.
class FaceDetectionFailed extends FaceAlignmentEvent {
  /// Session ID where detection failed
  final String sessionId;
  
  /// Error message describing the failure
  final String errorMessage;
  
  /// Whether the error is recoverable
  final bool isRecoverable;

  const FaceDetectionFailed({
    required this.sessionId,
    required this.errorMessage,
    this.isRecoverable = true,
  });

  @override
  List<Object?> get props => [sessionId, errorMessage, isRecoverable];

  @override
  String toString() {
    return 'FaceDetectionFailed('
        'sessionId: $sessionId, '
        'error: $errorMessage, '
        'recoverable: $isRecoverable'
        ')';
  }
}

/// Face alignment detection has timed out.
class AlignmentDetectionTimeout extends FaceAlignmentEvent {
  /// Session ID that timed out
  final String sessionId;
  
  /// Timeout duration that was exceeded
  final Duration timeoutDuration;

  const AlignmentDetectionTimeout({
    required this.sessionId,
    required this.timeoutDuration,
  });

  @override
  List<Object?> get props => [sessionId, timeoutDuration];

  @override
  String toString() {
    return 'AlignmentDetectionTimeout(sessionId: $sessionId, timeout: $timeoutDuration)';
  }
}

// ==================== Helper Enums ====================

/// Reasons why face alignment was lost
enum AlignmentLossReason {
  faceNotDetected,
  headRotationExceeded,
  faceMovedOutOfBounds,
  multipleFacesDetected,
  faceObscured,
  lightingChanged,
  userMovedTooFar,
  userMovedTooClose;

  /// Gets user-friendly description of the loss reason
  String get description {
    switch (this) {
      case AlignmentLossReason.faceNotDetected:
        return 'Face not detected';
      case AlignmentLossReason.headRotationExceeded:
        return 'Please look straight at the camera';
      case AlignmentLossReason.faceMovedOutOfBounds:
        return 'Please center your face in the oval';
      case AlignmentLossReason.multipleFacesDetected:
        return 'Multiple faces detected - ensure only one person is visible';
      case AlignmentLossReason.faceObscured:
        return 'Face is partially obscured - remove obstructions';
      case AlignmentLossReason.lightingChanged:
        return 'Lighting changed - ensure good lighting conditions';
      case AlignmentLossReason.userMovedTooFar:
        return 'Please move closer to the camera';
      case AlignmentLossReason.userMovedTooClose:
        return 'Please move back from the camera';
    }
  }
}

/// Types of alignment issues that can occur
enum AlignmentIssue {
  noFaceDetected,
  multipleFaces,
  faceNotCentered,
  faceTooSmall,
  faceTooLarge,
  headTurnedLeft,
  headTurnedRight,
  headTiltedUp,
  headTiltedDown,
  headRolledLeft,
  headRolledRight,
  poorLighting,
  faceObscured;

  /// Gets user-friendly guidance message for this issue
  String get guidanceMessage {
    switch (this) {
      case AlignmentIssue.noFaceDetected:
        return 'Position your face in front of the camera';
      case AlignmentIssue.multipleFaces:
        return 'Ensure only one person is visible';
      case AlignmentIssue.faceNotCentered:
        return 'Center your face in the oval';
      case AlignmentIssue.faceTooSmall:
        return 'Move closer to the camera';
      case AlignmentIssue.faceTooLarge:
        return 'Move back from the camera';
      case AlignmentIssue.headTurnedLeft:
        return 'Turn your head slightly to the right';
      case AlignmentIssue.headTurnedRight:
        return 'Turn your head slightly to the left';
      case AlignmentIssue.headTiltedUp:
        return 'Look down slightly';
      case AlignmentIssue.headTiltedDown:
        return 'Look up slightly';
      case AlignmentIssue.headRolledLeft:
        return 'Straighten your head';
      case AlignmentIssue.headRolledRight:
        return 'Straighten your head';
      case AlignmentIssue.poorLighting:
        return 'Move to an area with better lighting';
      case AlignmentIssue.faceObscured:
        return 'Remove any obstructions from your face';
    }
  }
}

/// Priority levels for alignment issues
enum IssuesPriority {
  low,
  medium,
  high,
  critical;

  /// Gets the priority level for an alignment issue
  static IssuesPriority forIssue(AlignmentIssue issue) {
    switch (issue) {
      case AlignmentIssue.noFaceDetected:
      case AlignmentIssue.multipleFaces:
        return IssuesPriority.critical;
      case AlignmentIssue.faceObscured:
      case AlignmentIssue.poorLighting:
        return IssuesPriority.high;
      case AlignmentIssue.faceNotCentered:
      case AlignmentIssue.faceTooSmall:
      case AlignmentIssue.faceTooLarge:
        return IssuesPriority.medium;
      case AlignmentIssue.headTurnedLeft:
      case AlignmentIssue.headTurnedRight:
      case AlignmentIssue.headTiltedUp:
      case AlignmentIssue.headTiltedDown:
      case AlignmentIssue.headRolledLeft:
      case AlignmentIssue.headRolledRight:
        return IssuesPriority.low;
    }
  }
}