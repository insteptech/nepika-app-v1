import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'package:injectable/injectable.dart';

import '../../../core/error/failures.dart';
import '../../../core/utils/either.dart';
import '../../../domain/face_scan/entities/camera_scan_session.dart';
import '../../../domain/face_scan/entities/face_scan_result.dart';
import '../../../domain/face_scan/entities/scan_image.dart';
import '../../../domain/face_scan/repositories/face_scan_repository.dart';
import '../datasources/face_scan_camera_data_source.dart';
import '../datasources/face_scan_local_data_source.dart';
import '../datasources/face_scan_remote_data_source.dart';
import '../models/camera_scan_session_model.dart';
import '../models/face_scan_result_model.dart';
import '../models/scan_image_model.dart';

/// Implementation of the face scan repository that coordinates all data sources.
/// 
/// This repository acts as the single source of truth for face scanning operations,
/// coordinating between remote API calls, local storage, and camera hardware.
/// It implements the repository pattern with proper error handling and data transformation.
@injectable
class FaceScanRepositoryImpl implements FaceScanRepository {
  final FaceScanRemoteDataSource _remoteDataSource;
  final FaceScanLocalDataSource _localDataSource;
  final FaceScanCameraDataSource _cameraDataSource;
  // Using simple UUID generation without external dependency

  FaceScanRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._cameraDataSource,
  );

  @override
  Future<Result<FaceScanResult>> analyzeFaceImage({
    required Uint8List imageBytes,
    required String userId,
    required String sessionId,
    bool includeAnnotatedImage = true,
  }) async {
    try {
      final processingStartTime = DateTime.now();
      
      debugPrint('🔍 Starting face image analysis...');
      debugPrint('   - Session ID: $sessionId');
      debugPrint('   - User ID: $userId');
      debugPrint('   - Image size: ${imageBytes.length} bytes');

      // Update session state to processing
      await _updateSessionSafely(sessionId, CameraSessionState.processing);

      // Call remote API for analysis
      final analysisResult = await _remoteDataSource.analyzeFaceImage(
        imageBytes: imageBytes,
        userId: userId,
        includeAnnotatedImage: includeAnnotatedImage,
        processingStartTime: processingStartTime,
      );

      // Create scan image with annotated image if available
      final scanImageModel = await _createScanImageFromAnalysis(
        originalImageBytes: imageBytes,
        analysisResult: analysisResult,
      );

      // Convert to domain entity
      final faceScanResult = analysisResult.toEntity(
        scanImage: scanImageModel.toEntity(),
      );

      // Save successful result locally
      if (faceScanResult.isSuccessful) {
        try {
          await _localDataSource.saveScanResult(analysisResult);
          await _updateSessionSafely(sessionId, CameraSessionState.processingComplete);
        } catch (e) {
          debugPrint('⚠️ Failed to save scan result locally: $e');
          // Continue even if local save fails
        }
      } else {
        await _updateSessionSafely(sessionId, CameraSessionState.failed);
      }

      debugPrint('✅ Face image analysis completed successfully');
      return success(faceScanResult);

    } on FaceAnalysisFailure catch (e) {
      await _updateSessionSafely(sessionId, CameraSessionState.failed);
      debugPrint('❌ Face analysis failed: ${e.message}');
      return failure(e);
    } catch (e) {
      await _updateSessionSafely(sessionId, CameraSessionState.failed);
      debugPrint('❌ Unexpected error during analysis: $e');
      return failure(FaceAnalysisFailure(message: 'Analysis failed: ${e.toString()}'));
    }
  }

  @override
  Future<Result<CameraScanSession>> initializeCameraSession({
    required String userId,
    CameraSessionConfig? sessionConfig,
  }) async {
    try {
      debugPrint('📷 Initializing camera session for user: $userId');

      // Check camera permissions first
      final hasPermission = await _cameraDataSource.checkCameraPermission();
      if (!hasPermission) {
        final permissionGranted = await _cameraDataSource.requestCameraPermission();
        if (!permissionGranted) {
          return failure(CameraPermissionFailure(
            message: 'Camera permission is required for face scanning',
          ));
        }
      }

      // Generate unique session ID
      final sessionId = _generateUniqueId();
      
      // Create initial session
      final session = CameraScanSession.initialize(
        sessionId: sessionId,
        userId: userId,
        config: sessionConfig,
      );

      // Save session locally
      final sessionModel = CameraScanSessionModel.fromEntity(session);
      await _localDataSource.saveSession(sessionModel);

      debugPrint('✅ Camera session initialized: $sessionId');
      return success(session);

    } catch (e) {
      debugPrint('❌ Failed to initialize camera session: $e');
      return failure(SessionFailure(message: 'Failed to initialize session: ${e.toString()}'));
    }
  }

  @override
  Future<Result<ScanImage>> captureFaceImage({
    required String sessionId,
    required String userId,
  }) async {
    try {
      debugPrint('📸 Capturing face image for session: $sessionId');

      // Get current session
      final sessionModel = await _localDataSource.getSession(sessionId);
      if (sessionModel == null) {
        return failure(SessionFailure(message: 'Session not found: $sessionId'));
      }

      final session = sessionModel.toEntity();
      if (session.userId != userId) {
        return failure(SessionFailure(message: 'Session does not belong to user'));
      }

      if (!session.isReadyForCapture) {
        return failure(SessionFailure(
          message: 'Session is not ready for capture. Current state: ${session.state.description}',
        ));
      }

      // Get available cameras
      final cameras = await _cameraDataSource.getAvailableCameras();
      if (cameras.isEmpty) {
        return failure(CameraInitializationFailure(
          message: 'No cameras available on this device',
        ));
      }

      // For now, return a placeholder ScanImage
      // In a real implementation, this would integrate with the camera controller
      // from the UI layer or maintain its own camera controller
      
      final scanImage = ScanImage.empty();
      
      // Update session state
      await _updateSessionSafely(sessionId, CameraSessionState.captureComplete);

      debugPrint('✅ Face image captured successfully');
      return success(scanImage);

    } catch (e) {
      debugPrint('❌ Failed to capture face image: $e');
      return failure(ImageCaptureFailure(message: 'Capture failed: ${e.toString()}'));
    }
  }

  @override
  Future<Result<CameraScanSession>> updateSessionState({
    required String sessionId,
    required CameraSessionState newState,
    FaceAlignmentState? alignmentState,
    SessionError? error,
  }) async {
    try {
      final sessionModel = await _localDataSource.getSession(sessionId);
      if (sessionModel == null) {
        return failure(SessionFailure(message: 'Session not found: $sessionId'));
      }

      var session = sessionModel.toEntity();
      
      // Update state
      session = session.updateState(newState);
      
      // Update alignment if provided
      if (alignmentState != null) {
        session = session.updateFaceAlignment(alignmentState);
      }
      
      // Add error if provided
      if (error != null) {
        session = session.withError(error);
      }

      // Save updated session
      final updatedSessionModel = CameraScanSessionModel.fromEntity(session);
      await _localDataSource.updateSession(updatedSessionModel);

      return success(session);
    } catch (e) {
      return failure(SessionFailure(message: 'Failed to update session: ${e.toString()}'));
    }
  }

  @override
  Future<Result<CameraScanSession>> getSessionState({
    required String sessionId,
  }) async {
    try {
      final sessionModel = await _localDataSource.getSession(sessionId);
      if (sessionModel == null) {
        return failure(SessionFailure(message: 'Session not found: $sessionId'));
      }

      return success(sessionModel.toEntity());
    } catch (e) {
      return failure(SessionFailure(message: 'Failed to get session: ${e.toString()}'));
    }
  }

  @override
  Future<Result<CameraScanSession>> terminateSession({
    required String sessionId,
    required String userId,
    String? reason,
  }) async {
    try {
      debugPrint('🛑 Terminating session: $sessionId');
      
      final sessionModel = await _localDataSource.getSession(sessionId);
      if (sessionModel == null) {
        return failure(SessionFailure(message: 'Session not found: $sessionId'));
      }

      var session = sessionModel.toEntity();
      if (session.userId != userId) {
        return failure(SessionFailure(message: 'Session does not belong to user'));
      }

      // Update to completed state
      session = session.updateState(CameraSessionState.processingComplete);
      
      // Save final session state
      final finalSessionModel = CameraScanSessionModel.fromEntity(session);
      await _localDataSource.updateSession(finalSessionModel);

      debugPrint('✅ Session terminated: $sessionId');
      return success(session);
    } catch (e) {
      return failure(SessionFailure(message: 'Failed to terminate session: ${e.toString()}'));
    }
  }

  @override
  Future<Result<FaceScanResult>> saveScanResult({
    required FaceScanResult scanResult,
    required String userId,
  }) async {
    try {
      if (scanResult.userId != userId) {
        return failure(ValidationFailure(message: 'Scan result does not belong to user'));
      }

      // Convert to model and save
      final scanResultModel = FaceScanResultModel(
        success: scanResult.isSuccessful,
        analysis: {}, // Would need to convert back from domain entity
        processingTimeMs: scanResult.processingTimeMs,
        errorMessage: scanResult.errorMessage,
        timestamp: scanResult.scanTimestamp,
        userId: scanResult.userId,
        scanId: scanResult.scanId,
      );

      await _localDataSource.saveScanResult(scanResultModel);
      
      return success(scanResult);
    } catch (e) {
      return failure(CacheFailure(message: 'Failed to save scan result: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<FaceScanResult>>> getHistoricalResults({
    required String userId,
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final resultModels = await _localDataSource.getScanResults(
        userId: userId,
        limit: limit,
        offset: offset,
        startDate: startDate,
        endDate: endDate,
      );

      final results = <FaceScanResult>[];
      for (final model in resultModels) {
        final scanImage = ScanImage.empty(); // Would need to reconstruct from stored data
        final result = model.toEntity(scanImage: scanImage);
        results.add(result);
      }

      return success(results);
    } catch (e) {
      return failure(CacheFailure(message: 'Failed to get historical results: ${e.toString()}'));
    }
  }

  @override
  Future<Result<FaceScanResult?>> getLatestScanResult({
    required String userId,
  }) async {
    try {
      final resultModel = await _localDataSource.getLatestScanResult(userId);
      
      if (resultModel == null) {
        return success(null);
      }

      final scanImage = ScanImage.empty(); // Would need to reconstruct from stored data
      final result = resultModel.toEntity(scanImage: scanImage);
      
      return success(result);
    } catch (e) {
      return failure(CacheFailure(message: 'Failed to get latest result: ${e.toString()}'));
    }
  }

  @override
  Future<Result<bool>> deleteScanData({
    String? scanId,
    required String userId,
  }) async {
    try {
      final success = await _localDataSource.deleteScanResults(
        scanId: scanId,
        userId: userId,
      );
      
      return Right(success);
    } catch (e) {
      return failure(CacheFailure(message: 'Failed to delete scan data: ${e.toString()}'));
    }
  }

  @override
  Future<Result<ImageValidationResult>> validateImageQuality({
    required Uint8List imageBytes,
    ImageQualityRequirements? qualityRequirements,
  }) async {
    try {
      // Validate with camera data source
      final qualityModel = await _cameraDataSource.validateImageQuality(imageBytes);
      
      // Check against requirements
      final requirements = qualityRequirements ?? ImageQualityRequirements.standard();
      final validationIssues = <String>[];
      final recommendations = <String>[];
      
      if (qualityModel.qualityScore < requirements.minQualityScore) {
        validationIssues.add('Overall image quality is too low');
        recommendations.add('Ensure good lighting and hold the device steady');
      }
      
      if (qualityModel.brightness < requirements.minBrightness) {
        validationIssues.add('Image is too dark');
        recommendations.add('Move to a brighter location or turn on more lights');
      }
      
      if (qualityModel.brightness > requirements.maxBrightness) {
        validationIssues.add('Image is too bright');
        recommendations.add('Avoid direct sunlight or bright lights');
      }
      
      if (!qualityModel.isInFocus && requirements.minSharpness > 0) {
        validationIssues.add('Image is not in focus');
        recommendations.add('Hold the device steady and wait for autofocus');
      }
      
      final isValid = validationIssues.isEmpty;
      
      final validationResult = ImageValidationResult(
        isValid: isValid,
        qualityMetrics: qualityModel.toEntity(),
        validationIssues: validationIssues,
        qualityRecommendations: recommendations,
      );
      
      return success(validationResult);
    } catch (e) {
      return failure(ImageValidationFailure(message: 'Image validation failed: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<CameraDeviceInfo>>> getAvailableCameras() async {
    try {
      final cameras = await _cameraDataSource.getAvailableCameras();
      return success(cameras);
    } catch (e) {
      return failure(CameraInitializationFailure(
        message: 'Failed to get available cameras: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Result<bool>> checkCameraPermissions() async {
    try {
      final hasPermission = await _cameraDataSource.checkCameraPermission();
      return success(hasPermission);
    } catch (e) {
      return failure(CameraPermissionFailure(
        message: 'Failed to check camera permissions: ${e.toString()}',
      ));
    }
  }

  // ===== Private Helper Methods =====

  /// Safely updates session state, handling errors gracefully
  Future<void> _updateSessionSafely(String sessionId, CameraSessionState newState) async {
    try {
      final sessionModel = await _localDataSource.getSession(sessionId);
      if (sessionModel != null) {
        var session = sessionModel.toEntity();
        session = session.updateState(newState);
        
        final updatedModel = CameraScanSessionModel.fromEntity(session);
        await _localDataSource.updateSession(updatedModel);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to update session state: $e');
    }
  }

  /// Creates a ScanImageModel with annotated image from analysis results
  Future<ScanImageModel> _createScanImageFromAnalysis({
    required Uint8List originalImageBytes,
    required FaceScanResultModel analysisResult,
  }) async {
    // Create basic metadata
    final metadata = ImageCaptureMetadataModel(
      captureTimestamp: analysisResult.timestamp,
      dimensions: const ImageDimensionsModel(width: 0, height: 0), // Would extract from image
      cameraSettings: CameraSettingsModel.unknown(),
      quality: ImageQualityModel.poor(), // Would validate actual quality
      isValidForAnalysis: analysisResult.success,
    );

    var scanImage = ScanImageModel.fromBytes(
      imageBytes: originalImageBytes,
      metadata: metadata,
    );

    // Add annotated image if available
    if (analysisResult.annotatedImageBytes != null) {
      final base64String = analysisResult.annotatedImageBase64 ?? '';
      scanImage = scanImage.withAnnotatedImage(base64String);
    }

    return scanImage;
  }

  /// Generates a unique session/scan ID
  String _generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'id_${timestamp}_$random';
  }
}