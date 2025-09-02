import 'dart:typed_data';
import 'package:equatable/equatable.dart';

import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../../../core/error/failures.dart';
import '../entities/face_scan_result.dart';
import '../repositories/face_scan_repository.dart';

/// Use case for analyzing a captured face image using AI models.
/// This encapsulates the core business logic for face scan analysis.
class AnalyzeFaceImageUseCase extends UseCase<FaceScanResult, AnalyzeFaceImageParams> {
  final FaceScanRepository repository;

  AnalyzeFaceImageUseCase(this.repository);

  @override
  Future<Result<FaceScanResult>> call(AnalyzeFaceImageParams params) async {
    try {
      // Validate input parameters
      final validationFailure = _validateParams(params);
      if (validationFailure != null) {
        return failure(validationFailure);
      }

      // Delegate to repository for actual analysis
      return await repository.analyzeFaceImage(
        imageBytes: params.imageBytes,
        userId: params.userId,
        sessionId: params.sessionId,
        includeAnnotatedImage: params.includeAnnotatedImage,
      );
    } catch (e) {
      return failure(
        FaceScanFailure(
          message: 'Unexpected error during face analysis: ${e.toString()}',
        ),
      );
    }
  }

  /// Validates the input parameters for face analysis
  FaceScanFailure? _validateParams(AnalyzeFaceImageParams params) {
    if (params.imageBytes.isEmpty) {
      return const FaceScanFailure(message: 'Image data cannot be empty');
    }

    if (params.userId.trim().isEmpty) {
      return const FaceScanFailure(message: 'User ID is required');
    }

    if (params.sessionId.trim().isEmpty) {
      return const FaceScanFailure(message: 'Session ID is required');
    }

    // Validate image size (e.g., not too large for API)
    const maxImageSize = 10 * 1024 * 1024; // 10MB
    if (params.imageBytes.length > maxImageSize) {
      return FaceScanFailure(
        message: 'Image size exceeds maximum limit of ${maxImageSize / (1024 * 1024)}MB',
      );
    }

    return null;
  }
}

/// Parameters for face image analysis
class AnalyzeFaceImageParams extends Equatable {
  /// Image data as bytes
  final Uint8List imageBytes;
  
  /// ID of the user requesting analysis
  final String userId;
  
  /// Unique session identifier
  final String sessionId;
  
  /// Whether to include annotated image in response
  final bool includeAnnotatedImage;
  
  /// Optional metadata about the image
  final Map<String, dynamic>? metadata;

  const AnalyzeFaceImageParams({
    required this.imageBytes,
    required this.userId,
    required this.sessionId,
    this.includeAnnotatedImage = true,
    this.metadata,
  });

  /// Creates a copy of this AnalyzeFaceImageParams with the given fields replaced with new values
  AnalyzeFaceImageParams copyWith({
    Uint8List? imageBytes,
    String? userId,
    String? sessionId,
    bool? includeAnnotatedImage,
    Map<String, dynamic>? metadata,
  }) {
    return AnalyzeFaceImageParams(
      imageBytes: imageBytes ?? this.imageBytes,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      includeAnnotatedImage: includeAnnotatedImage ?? this.includeAnnotatedImage,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [imageBytes, userId, sessionId, includeAnnotatedImage, metadata];

  @override
  String toString() {
    return 'AnalyzeFaceImageParams('
        'imageSize: ${imageBytes.length} bytes, '
        'userId: $userId, '
        'sessionId: $sessionId, '
        'includeAnnotatedImage: $includeAnnotatedImage, '
        'metadata: $metadata'
        ')';
  }
}

/// Face scan specific failure
class FaceScanFailure extends Failure {
  const FaceScanFailure({
    required super.message,
    super.code,
  });
}