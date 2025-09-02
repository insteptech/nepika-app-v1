import 'package:equatable/equatable.dart';

import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../../../core/error/failures.dart';
import '../entities/camera_scan_session.dart';
import '../repositories/face_scan_repository.dart';

/// Use case for initializing a new camera scanning session.
/// This encapsulates the business logic for setting up camera resources and session state.
class InitializeCameraSessionUseCase extends UseCase<CameraScanSession, InitializeCameraSessionParams> {
  final FaceScanRepository repository;

  InitializeCameraSessionUseCase(this.repository);

  @override
  Future<Result<CameraScanSession>> call(InitializeCameraSessionParams params) async {
    try {
      // Validate input parameters
      final validationFailure = _validateParams(params);
      if (validationFailure != null) {
        return failure(validationFailure);
      }

      // Delegate to repository for camera initialization
      return await repository.initializeCameraSession(
        userId: params.userId,
        sessionConfig: params.sessionConfig,
      );
    } catch (e) {
      return failure(
        CameraSessionFailure(
          message: 'Failed to initialize camera session: $e',
        ),
      );
    }
  }

  /// Validates the input parameters
  CameraSessionFailure? _validateParams(InitializeCameraSessionParams params) {
    if (params.userId.trim().isEmpty) {
      return const CameraSessionFailure(message: 'User ID is required');
    }

    return null;
  }
}

/// Parameters for camera session initialization
class InitializeCameraSessionParams extends Equatable {
  /// ID of the user requesting the session
  final String userId;
  
  /// Optional session configuration (uses default if not provided)
  final CameraSessionConfig? sessionConfig;

  const InitializeCameraSessionParams({
    required this.userId,
    this.sessionConfig,
  });

  @override
  List<Object?> get props => [userId, sessionConfig];

  @override
  String toString() {
    return 'InitializeCameraSessionParams('
        'userId: $userId, '
        'sessionConfig: $sessionConfig'
        ')';
  }
}

/// Camera session specific failure
class CameraSessionFailure extends Failure {
  const CameraSessionFailure({
    required super.message,
    super.code,
  });
}