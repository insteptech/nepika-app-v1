import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';

import '../../../domain/face_scan/usecases/initialize_camera_session.dart';
import '../../../domain/face_scan/usecases/capture_face_image.dart';
import '../../../domain/face_scan/usecases/analyze_face_image.dart';
import '../../../domain/face_scan/entities/face_scan_result.dart';
import '../../../domain/face_scan/entities/camera_scan_session.dart';
import '../../../domain/face_scan/entities/skin_analysis.dart';
import '../../../domain/face_scan/entities/scan_image.dart';
import '../../../core/utils/either.dart';
import '../../../core/error/failures.dart';
import 'face_scan_event.dart';
import 'face_scan_state.dart';

/// Main orchestrator BLoC for the face scanning workflow.
/// 
/// This BLoC manages the complete face scanning process from initialization
/// to final results. It coordinates with domain use cases and maintains
/// clean separation of concerns while providing a simple API for the UI.
/// 
/// Key responsibilities:
/// - Session lifecycle management
/// - Camera coordination
/// - Face alignment validation
/// - Image capture orchestration
/// - AI analysis coordination
/// - Error handling and recovery
/// - State transitions and validation
class FaceScanBloc extends Bloc<FaceScanEvent, FaceScanState> {
  // Domain use cases
  final InitializeCameraSessionUseCase _initializeCameraSessionUseCase;
  final CaptureFaceImageUseCase _captureFaceImageUseCase;
  final AnalyzeFaceImageUseCase _analyzeFaceImageUseCase;

  // Internal state tracking
  String? _currentSessionId;
  Timer? _countdownTimer;
  Timer? _alignmentTimer;
  StreamSubscription? _cameraStreamSubscription;

  FaceScanBloc({
    required InitializeCameraSessionUseCase initializeCameraSessionUseCase,
    required CaptureFaceImageUseCase captureFaceImageUseCase,
    required AnalyzeFaceImageUseCase analyzeFaceImageUseCase,
  })  : _initializeCameraSessionUseCase = initializeCameraSessionUseCase,
        _captureFaceImageUseCase = captureFaceImageUseCase,
        _analyzeFaceImageUseCase = analyzeFaceImageUseCase,
        super(const FaceScanInitial()) {
    
    // Register event handlers
    on<InitializeFaceScanSession>(_onInitializeFaceScanSession);
    on<StartFaceAlignment>(_onStartFaceAlignment);
    on<FaceDetectionUpdated>(_onFaceDetectionUpdated);
    on<FaceAlignmentAchieved>(_onFaceAlignmentAchieved);
    on<FaceAlignmentLost>(_onFaceAlignmentLost);
    on<CountdownTick>(_onCountdownTick);
    on<CaptureImageRequested>(_onCaptureImageRequested);
    on<ImageCaptured>(_onImageCaptured);
    on<ImageCaptureFailed>(_onImageCaptureFailed);
    on<StartImageAnalysis>(_onStartImageAnalysis);
    on<AnalysisCompleted>(_onAnalysisCompleted);
    on<AnalysisFailed>(_onAnalysisFailed);
    on<RetryLastOperation>(_onRetryLastOperation);
    on<ClearError>(_onClearError);
    on<CancelFaceScanSession>(_onCancelFaceScanSession);
    on<RetryFaceScanSession>(_onRetryFaceScanSession);
    on<CompleteFaceScanSession>(_onCompleteFaceScanSession);
    on<DisposeFaceScanSession>(_onDisposeFaceScanSession);
  }

  // ==================== Session Initialization ====================

  /// Handles face scan session initialization.
  /// Creates session, initializes camera, and sets up for face alignment.
  Future<void> _onInitializeFaceScanSession(
    InitializeFaceScanSession event,
    Emitter<FaceScanState> emit,
  ) async {
    try {
      // Generate unique session ID using timestamp and random
      _currentSessionId = 'scan_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
      
      emit(FaceScanInitializing(
        userId: event.userId,
        progressMessage: 'Initializing camera session...',
      ));

      // Initialize camera session using domain use case
      final result = await _initializeCameraSessionUseCase(
        InitializeCameraSessionParams(
          userId: event.userId,
          sessionConfig: event.sessionConfig,
        ),
      );

      if (result.isLeft) {
        final failure = result.left!;
        emit(FaceScanCameraInitializationFailed(
          userId: event.userId,
          errorMessage: _getReadableErrorMessage(failure),
          isRecoverable: _isRecoverableFailure(failure),
          errorDetails: {'failure': failure.toString()},
        ));
        return;
      }

      final session = result.right!;
      
      // Handle pre-initialized camera or create new controller
      CameraController cameraController;
      List<CameraDescription> availableCameras;

      if (event.preInitializedCamera != null && 
          event.preInitializedCamera!.value.isInitialized) {
        // Use pre-initialized camera
        cameraController = event.preInitializedCamera!;
        availableCameras = event.availableCameras ?? [];
      } else {
        // Initialize camera controller ourselves
        emit(FaceScanInitializing(
          userId: event.userId,
          progressMessage: 'Starting camera...',
        ));

        final cameraResult = await _initializeCameraController();
        if (cameraResult.isLeft) {
          emit(FaceScanCameraInitializationFailed(
            userId: event.userId,
            errorMessage: cameraResult.left!.message,
            isRecoverable: true,
          ));
          return;
        }

        final cameraData = cameraResult.right!;
        cameraController = cameraData['controller'] as CameraController;
        availableCameras = cameraData['cameras'] as List<CameraDescription>;
      }

      emit(FaceScanCameraReady(
        session: session,
        cameraController: cameraController,
        availableCameras: availableCameras,
      ));

    } catch (e) {
      emit(FaceScanCameraInitializationFailed(
        userId: event.userId,
        errorMessage: 'Unexpected error during initialization: $e',
        isRecoverable: true,
        errorDetails: {'exception': e.toString()},
      ));
    }
  }

  /// Initializes camera controller when not pre-provided
  Future<Result<Map<String, dynamic>>> _initializeCameraController() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return failure(CameraSessionFailure(message: 'No cameras available'));
      }

      // Select front camera or first available
      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Create and initialize controller
      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();

      return success({
        'controller': controller,
        'cameras': cameras,
      });

    } catch (e) {
      return failure(CameraSessionFailure(
        message: 'Failed to initialize camera: $e',
      ));
    }
  }

  // ==================== Face Alignment Handling ====================

  /// Starts face alignment process
  Future<void> _onStartFaceAlignment(
    StartFaceAlignment event,
    Emitter<FaceScanState> emit,
  ) async {
    if (state is! FaceScanCameraReady) return;

    final currentState = state as FaceScanCameraReady;
    
    emit(FaceScanAligning(
      session: currentState.session,
      cameraController: currentState.cameraController,
      alignmentState: FaceAlignmentState.initial(),
    ));
  }

  /// Handles face detection updates from camera stream
  Future<void> _onFaceDetectionUpdated(
    FaceDetectionUpdated event,
    Emitter<FaceScanState> emit,
  ) async {
    if (state is FaceScanAligning) {
      final currentState = state as FaceScanAligning;
      
      emit(FaceScanAligning(
        session: currentState.session,
        cameraController: currentState.cameraController,
        alignmentState: event.alignmentState,
        guidanceMessage: _getAlignmentGuidanceMessage(event.alignmentState),
      ));
    }
  }

  /// Handles face alignment achievement
  Future<void> _onFaceAlignmentAchieved(
    FaceAlignmentAchieved event,
    Emitter<FaceScanState> emit,
  ) async {
    if (state is FaceScanAligning) {
      final currentState = state as FaceScanAligning;
      
      // Start countdown
      _startCountdown(event.sessionId, event.alignmentState.currentCountdown);
      
      emit(FaceScanCountdown(
        session: currentState.session,
        cameraController: currentState.cameraController,
        alignmentState: event.alignmentState,
        countdownValue: event.alignmentState.currentCountdown,
      ));
    }
  }

  /// Handles face alignment loss
  Future<void> _onFaceAlignmentLost(
    FaceAlignmentLost event,
    Emitter<FaceScanState> emit,
  ) async {
    if (state is FaceScanCountdown) {
      final currentState = state as FaceScanCountdown;
      
      // Stop countdown and return to aligning
      _stopCountdown();
      
      emit(FaceScanAligning(
        session: currentState.session,
        cameraController: currentState.cameraController,
        alignmentState: event.alignmentState,
        guidanceMessage: _getAlignmentGuidanceMessage(event.alignmentState),
      ));
    }
  }

  /// Handles countdown ticks
  Future<void> _onCountdownTick(
    CountdownTick event,
    Emitter<FaceScanState> emit,
  ) async {
    if (state is FaceScanCountdown) {
      final currentState = state as FaceScanCountdown;
      
      if (!event.faceStillAligned) {
        // Face alignment lost during countdown
        add(FaceAlignmentLost(
          sessionId: event.sessionId,
          alignmentState: currentState.alignmentState.copyWith(isAligned: false),
        ));
        return;
      }

      if (event.currentCount == 0) {
        // Countdown finished, trigger capture
        add(CaptureImageRequested(sessionId: event.sessionId));
      } else {
        // Update countdown display
        emit(FaceScanCountdown(
          session: currentState.session,
          cameraController: currentState.cameraController,
          alignmentState: currentState.alignmentState,
          countdownValue: event.currentCount,
        ));
      }
    }
  }

  // ==================== Image Capture Handling ====================

  /// Handles image capture request
  Future<void> _onCaptureImageRequested(
    CaptureImageRequested event,
    Emitter<FaceScanState> emit,
  ) async {
    if (state is! FaceScanCountdown) return;

    final currentState = state as FaceScanCountdown;
    _stopCountdown();

    emit(FaceScanCapturing(
      session: currentState.session,
      cameraController: currentState.cameraController,
    ));

    try {
      // Use domain use case for capture
      final result = await _captureFaceImageUseCase(
        CaptureFaceImageParams(
          sessionId: event.sessionId,
          userId: currentState.session.userId,
        ),
      );

      if (result.isLeft) {
        add(ImageCaptureFailed(
          sessionId: event.sessionId,
          errorMessage: result.left!.message,
          isRecoverable: true,
        ));
        return;
      }

      final scanImage = result.right!;
      add(ImageCaptured(
        sessionId: event.sessionId,
        imagePath: scanImage.originalImagePath ?? '',
        imageSizeBytes: scanImage.originalImageSize,
      ));

    } catch (e) {
      add(ImageCaptureFailed(
        sessionId: event.sessionId,
        errorMessage: 'Capture failed: $e',
        isRecoverable: true,
      ));
    }
  }

  /// Handles successful image capture
  Future<void> _onImageCaptured(
    ImageCaptured event,
    Emitter<FaceScanState> emit,
  ) async {
    if (state is! FaceScanCapturing) return;

    final currentState = state as FaceScanCapturing;
    
    emit(FaceScanImageCaptured(
      session: currentState.session,
      imagePath: event.imagePath,
      imageSizeBytes: event.imageSizeBytes,
    ));

    // Automatically start analysis
    add(StartImageAnalysis(
      sessionId: event.sessionId,
      imagePath: event.imagePath,
      includeAnnotatedImage: true,
    ));
  }

  /// Handles image capture failure
  Future<void> _onImageCaptureFailed(
    ImageCaptureFailed event,
    Emitter<FaceScanState> emit,
  ) async {
    if (state.session == null) return;

    emit(FaceScanCaptureFailed(
      session: state.session!,
      errorMessage: event.errorMessage,
      isRecoverable: event.isRecoverable,
    ));
  }

  // ==================== AI Analysis Handling ====================

  /// Starts AI analysis of captured image
  Future<void> _onStartImageAnalysis(
    StartImageAnalysis event,
    Emitter<FaceScanState> emit,
  ) async {
    if (state is! FaceScanImageCaptured) return;

    final currentState = state as FaceScanImageCaptured;
    
    emit(FaceScanProcessing(
      session: currentState.session,
      imagePath: event.imagePath,
      progressMessage: 'Analyzing your skin...',
      processingStartTime: DateTime.now(),
    ));

    try {
      // Read image file
      final imageFile = File(event.imagePath);
      final imageBytes = await imageFile.readAsBytes();

      // Use domain use case for analysis
      final result = await _analyzeFaceImageUseCase(
        AnalyzeFaceImageParams(
          imageBytes: imageBytes,
          userId: currentState.session.userId,
          sessionId: event.sessionId,
          includeAnnotatedImage: event.includeAnnotatedImage,
        ),
      );

      if (result.isLeft) {
        add(AnalysisFailed(
          sessionId: event.sessionId,
          errorMessage: result.left!.message,
          isRetryable: _isRecoverableFailure(result.left!),
        ));
        return;
      }

      final scanResult = result.right!;
      add(AnalysisCompleted(
        sessionId: event.sessionId,
        analysisData: _convertScanResultToMap(scanResult),
        processingTimeMs: scanResult.processingTimeMs,
      ));

    } catch (e) {
      add(AnalysisFailed(
        sessionId: event.sessionId,
        errorMessage: 'Analysis failed: $e',
        isRetryable: true,
      ));
    }
  }

  /// Handles successful analysis completion
  Future<void> _onAnalysisCompleted(
    AnalysisCompleted event,
    Emitter<FaceScanState> emit,
  ) async {
    if (state is! FaceScanProcessing) return;

    final currentState = state as FaceScanProcessing;
    
    // Convert analysis data back to FaceScanResult
    final scanResult = _convertMapToScanResult(
      event.analysisData,
      currentState.session.userId,
      event.sessionId,
    );

    emit(FaceScanCompleted(
      scanResult: scanResult,
      originalImagePath: currentState.imagePath,
      hasAnnotatedImage: scanResult.scanImage.hasAnnotatedImage,
    ));
  }

  /// Handles analysis failure
  Future<void> _onAnalysisFailed(
    AnalysisFailed event,
    Emitter<FaceScanState> emit,
  ) async {
    if (state is! FaceScanProcessing) return;

    final currentState = state as FaceScanProcessing;
    
    emit(FaceScanAnalysisFailed(
      session: currentState.session,
      errorMessage: event.errorMessage,
      imagePath: currentState.imagePath,
      processingTimeMs: currentState.elapsedProcessingTimeMs,
      statusCode: event.statusCode,
      isRecoverable: event.isRetryable,
      errorDetails: event.errorContext,
    ));
  }

  // ==================== Error Handling and Recovery ====================

  /// Retries the last failed operation
  Future<void> _onRetryLastOperation(
    RetryLastOperation event,
    Emitter<FaceScanState> emit,
  ) async {
    if (state is FaceScanCaptureFailed) {
      add(CaptureImageRequested(sessionId: event.sessionId));
    } else if (state is FaceScanAnalysisFailed) {
      final errorState = state as FaceScanAnalysisFailed;
      add(StartImageAnalysis(
        sessionId: event.sessionId,
        imagePath: errorState.imagePath,
        includeAnnotatedImage: true,
      ));
    }
  }

  /// Clears error state and returns to appropriate previous state
  Future<void> _onClearError(
    ClearError event,
    Emitter<FaceScanState> emit,
  ) async {
    if (state is FaceScanErrorState) {
      final errorState = state as FaceScanErrorState;
      if (errorState.session != null) {
        // Return to aligning state if we have a session
        emit(FaceScanAligning(
          session: errorState.session!,
          cameraController: state.cameraController!,
          alignmentState: FaceAlignmentState.initial(),
        ));
      } else {
        // Return to initial state if no session
        emit(const FaceScanInitial());
      }
    }
  }

  // ==================== Session Lifecycle ====================

  /// Cancels the current scanning session
  Future<void> _onCancelFaceScanSession(
    CancelFaceScanSession event,
    Emitter<FaceScanState> emit,
  ) async {
    _cleanupResources();
    emit(FaceScanCancelled(
      session: state.session,
      reason: event.reason,
    ));
  }

  /// Retries the entire face scan session
  Future<void> _onRetryFaceScanSession(
    RetryFaceScanSession event,
    Emitter<FaceScanState> emit,
  ) async {
    _cleanupResources();
    
    if (state.session != null) {
      add(InitializeFaceScanSession(
        userId: state.session!.userId,
        sessionConfig: state.session!.config,
      ));
    } else {
      emit(const FaceScanInitial());
    }
  }

  /// Completes the face scan session
  Future<void> _onCompleteFaceScanSession(
    CompleteFaceScanSession event,
    Emitter<FaceScanState> emit,
  ) async {
    _cleanupResources();
    // State should already be FaceScanCompleted, just ensure cleanup
  }

  /// Disposes the face scan session and cleans up all resources
  Future<void> _onDisposeFaceScanSession(
    DisposeFaceScanSession event,
    Emitter<FaceScanState> emit,
  ) async {
    _cleanupResources();
    emit(const FaceScanInitial());
  }

  // ==================== Helper Methods ====================

  /// Starts the alignment countdown timer
  void _startCountdown(String sessionId, int initialCount) {
    _stopCountdown();
    
    int currentCount = initialCount;
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        add(CountdownTick(
          sessionId: sessionId,
          currentCount: currentCount,
          faceStillAligned: true, // This should come from face detection
        ));
        
        currentCount--;
        if (currentCount < 0) {
          timer.cancel();
        }
      },
    );
  }

  /// Stops the countdown timer
  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  /// Gets user-friendly alignment guidance message
  String _getAlignmentGuidanceMessage(FaceAlignmentState alignmentState) {
    if (!alignmentState.isAligned) {
      if (alignmentState.position.distanceFromCenter > 0.3) {
        return 'Move your face closer to the center';
      } else if (!alignmentState.headAngles.isWithinTolerance(
          FaceAlignmentTolerance.standard())) {
        return 'Look straight at the camera';
      } else {
        return 'Align your face inside the oval';
      }
    }
    return 'Hold still...';
  }

  /// Converts failure to user-readable error message
  String _getReadableErrorMessage(Failure failure) {
    if (failure.message.contains('permission')) {
      return 'Camera permission is required. Please grant permission in Settings.';
    } else if (failure.message.contains('timeout')) {
      return 'Camera is taking too long to respond. Please try again.';
    } else if (failure.message.contains('No cameras')) {
      return 'No cameras found on this device.';
    } else if (failure.message.contains('in use')) {
      return 'Camera is being used by another app. Please close other camera apps.';
    }
    return 'Failed to initialize camera. Please try again.';
  }

  /// Checks if a failure is recoverable
  bool _isRecoverableFailure(Failure failure) {
    // Most camera and network failures are recoverable
    return !failure.message.contains('No cameras') &&
           !failure.message.contains('permission permanently denied');
  }

  /// Converts FaceScanResult to Map for event transport
  Map<String, dynamic> _convertScanResultToMap(FaceScanResult scanResult) {
    // This would convert the domain object to a serializable map
    // Implementation depends on your specific serialization needs
    return {
      'scanId': scanResult.scanId,
      'userId': scanResult.userId,
      'scanTimestamp': scanResult.scanTimestamp.toIso8601String(),
      'isSuccessful': scanResult.isSuccessful,
      'processingTimeMs': scanResult.processingTimeMs,
      // Add other fields as needed
    };
  }

  /// Converts Map back to FaceScanResult from event data
  FaceScanResult _convertMapToScanResult(
    Map<String, dynamic> data,
    String userId,
    String sessionId,
  ) {
    // This would reconstruct the domain object from the map
    // Implementation depends on your specific deserialization needs
    return FaceScanResult(
      scanId: data['scanId'] ?? sessionId,
      userId: userId,
      scanTimestamp: DateTime.parse(data['scanTimestamp'] ?? DateTime.now().toIso8601String()),
      skinAnalysis: SkinAnalysis.empty(), // Parse from data
      scanImage: ScanImage.empty(), // Parse from data
      isSuccessful: data['isSuccessful'] ?? true,
      processingTimeMs: data['processingTimeMs'] ?? 0,
    );
  }

  /// Cleans up all resources (timers, streams, etc.)
  void _cleanupResources() {
    _stopCountdown();
    _alignmentTimer?.cancel();
    _alignmentTimer = null;
    _cameraStreamSubscription?.cancel();
    _cameraStreamSubscription = null;
  }

  @override
  Future<void> close() {
    _cleanupResources();
    return super.close();
  }
}