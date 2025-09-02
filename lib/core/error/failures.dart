import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

// Server failures
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
  });
}

// Network failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
  });
}

// Cache failures
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
  });
}

// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
  });
}

// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
  });
}

// Unknown failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code,
  });
}

// Routine specific failures
class RoutineFailure extends Failure {
  const RoutineFailure({
    required super.message,
    super.code,
  });
}

class RoutineNotFoundFailure extends RoutineFailure {
  const RoutineNotFoundFailure({
    required super.message,
    super.code,
  });
}

class RoutinePermissionFailure extends RoutineFailure {
  const RoutinePermissionFailure({
    required super.message,
    super.code,
  });
}

// Face scan specific failures
class FaceScanFailure extends Failure {
  const FaceScanFailure({
    required super.message,
    super.code,
  });
}

class CameraInitializationFailure extends FaceScanFailure {
  const CameraInitializationFailure({
    required super.message,
    super.code,
  });
}

class CameraPermissionFailure extends FaceScanFailure {
  const CameraPermissionFailure({
    required super.message,
    super.code,
  });
}

class ImageCaptureFailure extends FaceScanFailure {
  const ImageCaptureFailure({
    required super.message,
    super.code,
  });
}

class FaceAnalysisFailure extends FaceScanFailure {
  const FaceAnalysisFailure({
    required super.message,
    super.code,
  });
}

class SessionFailure extends FaceScanFailure {
  const SessionFailure({
    required super.message,
    super.code,
  });
}

class ImageValidationFailure extends FaceScanFailure {
  const ImageValidationFailure({
    required super.message,
    super.code,
  });
}
