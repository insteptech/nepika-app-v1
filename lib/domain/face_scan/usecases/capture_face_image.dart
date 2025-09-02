import 'dart:typed_data';
import 'package:equatable/equatable.dart';

import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../../../core/error/failures.dart';
import '../entities/scan_image.dart';
import '../repositories/face_scan_repository.dart';

/// Use case for capturing a face image during a scanning session.
/// This encapsulates the business logic for taking and validating face photos.
class CaptureFaceImageUseCase extends UseCase<ScanImage, CaptureFaceImageParams> {
  final FaceScanRepository repository;

  CaptureFaceImageUseCase(this.repository);

  @override
  Future<Result<ScanImage>> call(CaptureFaceImageParams params) async {
    try {
      // Validate input parameters
      final validationFailure = _validateParams(params);
      if (validationFailure != null) {
        return failure(validationFailure);
      }

      // Delegate to repository for image capture
      return await repository.captureFaceImage(
        sessionId: params.sessionId,
        userId: params.userId,
      );
    } catch (e) {
      return failure(
        ImageCaptureFailure(
          message: 'Failed to capture face image: $e',
        ),
      );
    }
  }

  /// Validates the input parameters
  ImageCaptureFailure? _validateParams(CaptureFaceImageParams params) {
    if (params.sessionId.trim().isEmpty) {
      return const ImageCaptureFailure(message: 'Session ID is required');
    }

    if (params.userId.trim().isEmpty) {
      return const ImageCaptureFailure(message: 'User ID is required');
    }

    return null;
  }
}

/// Parameters for face image capture
class CaptureFaceImageParams extends Equatable {
  /// Unique session identifier
  final String sessionId;
  
  /// ID of the user requesting capture
  final String userId;
  
  /// Optional capture quality settings
  final ImageQuality? qualitySettings;

  const CaptureFaceImageParams({
    required this.sessionId,
    required this.userId,
    this.qualitySettings,
  });

  @override
  List<Object?> get props => [sessionId, userId, qualitySettings];

  @override
  String toString() {
    return 'CaptureFaceImageParams('
        'sessionId: $sessionId, '
        'userId: $userId, '
        'qualitySettings: $qualitySettings'
        ')';
  }
}

/// Image capture specific failure
class ImageCaptureFailure extends Failure {
  const ImageCaptureFailure({
    required super.message,
    super.code,
  });
}