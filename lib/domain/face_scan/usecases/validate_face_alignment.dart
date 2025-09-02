import 'package:equatable/equatable.dart';

import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../../../core/error/failures.dart';
import '../entities/camera_scan_session.dart';

/// Use case for validating face alignment during scanning.
/// This encapsulates the business logic for determining if a face is properly positioned.
class ValidateFaceAlignmentUseCase extends UseCase<FaceAlignmentValidationResult, ValidateFaceAlignmentParams> {
  ValidateFaceAlignmentUseCase();

  @override
  Future<Result<FaceAlignmentValidationResult>> call(ValidateFaceAlignmentParams params) async {
    try {
      // Validate input parameters
      final validationFailure = _validateParams(params);
      if (validationFailure != null) {
        return failure(validationFailure);
      }

      // Perform face alignment validation
      final result = _validateAlignment(params);
      return success(result);
    } catch (e) {
      return failure(
        FaceAlignmentFailure(
          message: 'Failed to validate face alignment: $e',
        ),
      );
    }
  }

  /// Validates the input parameters
  FaceAlignmentFailure? _validateParams(ValidateFaceAlignmentParams params) {
    if (params.headAngles.yaw.isNaN || 
        params.headAngles.pitch.isNaN || 
        params.headAngles.roll.isNaN) {
      return const FaceAlignmentFailure(message: 'Invalid face angle data');
    }

    if (params.facePosition.normalizedX.isNaN || 
        params.facePosition.normalizedY.isNaN) {
      return const FaceAlignmentFailure(message: 'Invalid face position data');
    }

    return null;
  }

  /// Performs the actual face alignment validation
  FaceAlignmentValidationResult _validateAlignment(ValidateFaceAlignmentParams params) {
    // Check if face angles are within tolerance
    final anglesValid = params.headAngles.isWithinTolerance(params.tolerance);
    
    // Check if face position is within tolerance
    final positionValid = params.facePosition.isWithinTolerance(params.tolerance);
    
    // Determine overall alignment status
    final isAligned = anglesValid && positionValid;
    
    // Calculate alignment confidence (0-1)
    final angleScore = _calculateAngleScore(params.headAngles, params.tolerance);
    final positionScore = _calculatePositionScore(params.facePosition, params.tolerance);
    final alignmentConfidence = (angleScore + positionScore) / 2.0;
    
    // Generate feedback for user guidance
    final feedback = _generateAlignmentFeedback(
      params.headAngles,
      params.facePosition,
      params.tolerance,
    );
    
    return FaceAlignmentValidationResult(
      isAligned: isAligned,
      alignmentConfidence: alignmentConfidence,
      anglesValid: anglesValid,
      positionValid: positionValid,
      feedback: feedback,
      validatedAt: DateTime.now(),
    );
  }

  /// Calculates a score (0-1) for how well angles meet tolerance requirements
  double _calculateAngleScore(FaceAngles angles, FaceAlignmentTolerance tolerance) {
    final yawScore = 1.0 - (angles.yaw.abs() / tolerance.maxYawDegrees).clamp(0.0, 1.0);
    final pitchScore = 1.0 - (angles.pitch.abs() / tolerance.maxPitchDegrees).clamp(0.0, 1.0);
    final rollScore = 1.0 - (angles.roll.abs() / tolerance.maxRollDegrees).clamp(0.0, 1.0);
    
    return (yawScore + pitchScore + rollScore) / 3.0;
  }

  /// Calculates a score (0-1) for how well position meets tolerance requirements
  double _calculatePositionScore(FacePosition position, FaceAlignmentTolerance tolerance) {
    final distanceScore = 1.0 - (position.distanceFromCenter / tolerance.maxDistanceFromCenter).clamp(0.0, 1.0);
    
    double scaleScore = 1.0;
    if (position.scaleFactor < tolerance.minScaleFactor) {
      scaleScore = position.scaleFactor / tolerance.minScaleFactor;
    } else if (position.scaleFactor > tolerance.maxScaleFactor) {
      scaleScore = tolerance.maxScaleFactor / position.scaleFactor;
    }
    
    return (distanceScore + scaleScore) / 2.0;
  }

  /// Generates user-friendly feedback for alignment guidance
  List<String> _generateAlignmentFeedback(
    FaceAngles angles,
    FacePosition position,
    FaceAlignmentTolerance tolerance,
  ) {
    final feedback = <String>[];

    // Angle-based feedback
    if (angles.yaw.abs() > tolerance.maxYawDegrees) {
      if (angles.yaw > 0) {
        feedback.add('Turn your head slightly to the left');
      } else {
        feedback.add('Turn your head slightly to the right');
      }
    }

    if (angles.pitch.abs() > tolerance.maxPitchDegrees) {
      if (angles.pitch > 0) {
        feedback.add('Lower your chin slightly');
      } else {
        feedback.add('Raise your chin slightly');
      }
    }

    if (angles.roll.abs() > tolerance.maxRollDegrees) {
      if (angles.roll > 0) {
        feedback.add('Straighten your head (tilted right)');
      } else {
        feedback.add('Straighten your head (tilted left)');
      }
    }

    // Position-based feedback
    if (position.distanceFromCenter > tolerance.maxDistanceFromCenter) {
      if (position.normalizedX.abs() > position.normalizedY.abs()) {
        if (position.normalizedX > 0) {
          feedback.add('Move your face to the left');
        } else {
          feedback.add('Move your face to the right');
        }
      } else {
        if (position.normalizedY > 0) {
          feedback.add('Move your face up');
        } else {
          feedback.add('Move your face down');
        }
      }
    }

    // Scale-based feedback
    if (position.scaleFactor < tolerance.minScaleFactor) {
      feedback.add('Move closer to the camera');
    } else if (position.scaleFactor > tolerance.maxScaleFactor) {
      feedback.add('Move away from the camera');
    }

    // Default feedback if aligned
    if (feedback.isEmpty) {
      feedback.add('Face is properly aligned');
    }

    return feedback;
  }
}

/// Parameters for face alignment validation
class ValidateFaceAlignmentParams extends Equatable {
  /// Current head rotation angles
  final FaceAngles headAngles;
  
  /// Current face position
  final FacePosition facePosition;
  
  /// Tolerance settings for validation
  final FaceAlignmentTolerance tolerance;

  const ValidateFaceAlignmentParams({
    required this.headAngles,
    required this.facePosition,
    required this.tolerance,
  });

  @override
  List<Object?> get props => [headAngles, facePosition, tolerance];

  @override
  String toString() {
    return 'ValidateFaceAlignmentParams('
        'headAngles: $headAngles, '
        'facePosition: $facePosition, '
        'tolerance: $tolerance'
        ')';
  }
}

/// Result of face alignment validation
class FaceAlignmentValidationResult extends Equatable {
  /// Whether the face is currently aligned
  final bool isAligned;
  
  /// Confidence score for alignment (0-1)
  final double alignmentConfidence;
  
  /// Whether face angles are within tolerance
  final bool anglesValid;
  
  /// Whether face position is within tolerance
  final bool positionValid;
  
  /// User-friendly feedback for improving alignment
  final List<String> feedback;
  
  /// When this validation was performed
  final DateTime validatedAt;

  const FaceAlignmentValidationResult({
    required this.isAligned,
    required this.alignmentConfidence,
    required this.anglesValid,
    required this.positionValid,
    required this.feedback,
    required this.validatedAt,
  });

  /// Creates a copy of this result with updated values
  FaceAlignmentValidationResult copyWith({
    bool? isAligned,
    double? alignmentConfidence,
    bool? anglesValid,
    bool? positionValid,
    List<String>? feedback,
    DateTime? validatedAt,
  }) {
    return FaceAlignmentValidationResult(
      isAligned: isAligned ?? this.isAligned,
      alignmentConfidence: alignmentConfidence ?? this.alignmentConfidence,
      anglesValid: anglesValid ?? this.anglesValid,
      positionValid: positionValid ?? this.positionValid,
      feedback: feedback ?? this.feedback,
      validatedAt: validatedAt ?? this.validatedAt,
    );
  }

  @override
  List<Object?> get props => [
        isAligned,
        alignmentConfidence,
        anglesValid,
        positionValid,
        feedback,
        validatedAt,
      ];

  @override
  String toString() {
    return 'FaceAlignmentValidationResult('
        'isAligned: $isAligned, '
        'alignmentConfidence: $alignmentConfidence, '
        'anglesValid: $anglesValid, '
        'positionValid: $positionValid, '
        'feedback: $feedback, '
        'validatedAt: $validatedAt'
        ')';
  }
}

/// Face alignment specific failure
class FaceAlignmentFailure extends Failure {
  const FaceAlignmentFailure({
    required super.message,
    super.code,
  });
}