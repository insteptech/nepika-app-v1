import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart' show Size;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../domain/face_scan/entities/camera_scan_session.dart';
import '../../../domain/face_scan/usecases/validate_face_alignment.dart';
import '../../../core/utils/either.dart';
import 'face_alignment_event.dart';
import 'face_alignment_state.dart';

/// Dedicated BLoC for real-time face alignment detection and validation.
/// 
/// This BLoC handles the complex task of continuous face detection and alignment
/// validation during the face scanning process. It works in conjunction with
/// the camera stream to provide real-time feedback on face positioning.
/// 
/// Key responsibilities:
/// - Real-time face detection from camera frames
/// - Face alignment validation against tolerance settings
/// - Alignment guidance generation for user feedback
/// - Face alignment state transitions and tracking
/// - Performance optimization for continuous processing
/// - Error handling for detection failures
/// 
/// The BLoC maintains sophisticated state management to track:
/// - Face detection status and results
/// - Alignment validation and duration tracking
/// - User guidance based on current alignment issues
/// - Performance metrics and frame processing rates
class FaceAlignmentBloc extends Bloc<FaceAlignmentEvent, FaceAlignmentState> {
  // Domain use case for alignment validation
  final ValidateFaceAlignmentUseCase _validateFaceAlignmentUseCase;

  // Internal state tracking
  final Map<String, _SessionTrackingData> _sessionTracking = {};
  Timer? _alignmentValidationTimer;
  Timer? _guidanceUpdateTimer;

  // Face detection setup
  FaceDetector? _faceDetector;
  bool _isProcessingFrame = false;

  FaceAlignmentBloc({
    required ValidateFaceAlignmentUseCase validateFaceAlignmentUseCase,
  })  : _validateFaceAlignmentUseCase = validateFaceAlignmentUseCase,
        super(const FaceAlignmentInitial()) {
    
    // Register event handlers
    on<StartFaceAlignmentDetection>(_onStartFaceAlignmentDetection);
    on<StopFaceAlignmentDetection>(_onStopFaceAlignmentDetection);
    on<FaceDetectionResultReceived>(_onFaceDetectionResultReceived);
    on<NoFaceDetected>(_onNoFaceDetected);
    on<FaceAlignmentAchieved>(_onFaceAlignmentAchieved);
    on<FaceAlignmentLost>(_onFaceAlignmentLost);
    on<FaceAlignmentValidating>(_onFaceAlignmentValidating);
    on<AlignmentGuidanceRequested>(_onAlignmentGuidanceRequested);
    on<UpdateAlignmentTolerance>(_onUpdateAlignmentTolerance);
    on<ResetAlignmentState>(_onResetAlignmentState);
    on<ProcessCameraFrame>(_onProcessCameraFrame);
    on<FaceDetectionFailed>(_onFaceDetectionFailed);
    on<AlignmentDetectionTimeout>(_onAlignmentDetectionTimeout);

    // Initialize face detector
    _initializeFaceDetector();
  }

  // ==================== Session Management ====================

  /// Starts face alignment detection for a session
  Future<void> _onStartFaceAlignmentDetection(
    StartFaceAlignmentDetection event,
    Emitter<FaceAlignmentState> emit,
  ) async {
    try {
      // Initialize session tracking
      _sessionTracking[event.sessionId] = _SessionTrackingData(
        sessionId: event.sessionId,
        toleranceSettings: event.toleranceSettings,
        detectionStartTime: DateTime.now(),
      );

      emit(FaceAlignmentDetectionActive(
        sessionId: event.sessionId,
        toleranceSettings: event.toleranceSettings,
        detectionStartTime: DateTime.now(),
      ));

      // Start periodic validation timer
      _startValidationTimer(event.sessionId);

    } catch (e) {
      add(FaceDetectionFailed(
        sessionId: event.sessionId,
        errorMessage: 'Failed to start alignment detection: $e',
      ));
    }
  }

  /// Stops face alignment detection for a session
  Future<void> _onStopFaceAlignmentDetection(
    StopFaceAlignmentDetection event,
    Emitter<FaceAlignmentState> emit,
  ) async {
    _stopValidationTimer();
    _sessionTracking.remove(event.sessionId);

    emit(FaceAlignmentDetectionStopped(
      sessionId: event.sessionId,
      stopTime: DateTime.now(),
      finalAlignmentState: state,
    ));
  }

  // ==================== Face Detection Processing ====================

  /// Processes camera frame for face detection
  Future<void> _onProcessCameraFrame(
    ProcessCameraFrame event,
    Emitter<FaceAlignmentState> emit,
  ) async {
    if (_isProcessingFrame || _faceDetector == null) return;

    final sessionData = _sessionTracking[event.sessionId];
    if (sessionData == null) return;

    _isProcessingFrame = true;

    try {
      emit(FaceAlignmentProcessingFrame(
        sessionId: event.sessionId,
        processingStartTime: DateTime.now(),
        frameNumber: sessionData.frameNumber,
      ));

      // Convert camera image to ML Kit input format
      final inputImage = _convertCameraImageToInputImage(
        event.cameraImageData,
        event.cameraDescription,
      );

      if (inputImage != null) {
        // Perform face detection
        final faces = await _faceDetector!.processImage(inputImage);
        
        // Update session tracking
        sessionData.incrementFrameCount();
        sessionData.updateLastProcessTime();

        // Process detection results
        if (faces.isEmpty) {
          add(NoFaceDetected(
            sessionId: event.sessionId,
            detectionTimestamp: DateTime.now(),
          ));
        } else {
          add(FaceDetectionResultReceived(
            sessionId: event.sessionId,
            detectedFaces: faces,
            detectionTimestamp: DateTime.now(),
            previewSize: event.previewSize,
          ));
        }
      }

    } catch (e) {
      add(FaceDetectionFailed(
        sessionId: event.sessionId,
        errorMessage: 'Frame processing failed: $e',
      ));
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Handles face detection results
  Future<void> _onFaceDetectionResultReceived(
    FaceDetectionResultReceived event,
    Emitter<FaceAlignmentState> emit,
  ) async {
    final sessionData = _sessionTracking[event.sessionId];
    if (sessionData == null) return;

    sessionData.updateLastDetectionTime(event.detectionTimestamp);

    // Check for multiple faces
    if (event.detectedFaces.length > 1) {
      emit(FaceAlignmentMultipleFacesDetected(
        sessionId: event.sessionId,
        detectedFaces: event.detectedFaces,
        detectionTime: event.detectionTimestamp,
      ));
      return;
    }

    final face = event.detectedFaces.first;
    
    // Validate face alignment using domain use case
    await _validateFaceAlignment(
      event.sessionId,
      face,
      event.previewSize,
      sessionData,
      emit,
    );
  }

  /// Handles no face detected
  Future<void> _onNoFaceDetected(
    NoFaceDetected event,
    Emitter<FaceAlignmentState> emit,
  ) async {
    final sessionData = _sessionTracking[event.sessionId];
    if (sessionData == null) return;

    sessionData.updateNoFaceDetection();
    
    emit(FaceAlignmentNoFaceDetected(
      sessionId: event.sessionId,
      noFaceDuration: sessionData.getNoFaceDuration(),
      lastCheckTime: event.detectionTimestamp,
    ));
  }

  // ==================== Alignment Validation ====================

  /// Validates face alignment using domain logic
  Future<void> _validateFaceAlignment(
    String sessionId,
    Face face,
    Size previewSize,
    _SessionTrackingData sessionData,
    Emitter<FaceAlignmentState> emit,
  ) async {
    try {
      emit(FaceAlignmentValidating(
        sessionId: sessionId,
        faceBeingValidated: face,
        validationStartTime: DateTime.now(),
      ));

      // Create face alignment state from detection
      final faceAlignmentState = _createFaceAlignmentStateFromFace(
        face,
        previewSize,
        sessionData.toleranceSettings,
      );

      // Use domain use case for validation
      final result = await _validateFaceAlignmentUseCase(
        ValidateFaceAlignmentParams(
          faceAlignmentState: faceAlignmentState,
          toleranceSettings: sessionData.toleranceSettings,
        ),
      );

      if (result.isLeft) {
        add(FaceDetectionFailed(
          sessionId: sessionId,
          errorMessage: result.left!.message,
        ));
        return;
      }

      final validationResult = result.right!;
      
      if (validationResult.isAligned) {
        // Face is aligned
        sessionData.updateAlignmentAchieved(DateTime.now());
        
        add(FaceAlignmentAchieved(
          sessionId: sessionId,
          alignedAngles: faceAlignmentState.headAngles,
          alignedPosition: faceAlignmentState.position,
          alignmentDuration: sessionData.getAlignmentDuration(),
        ));
      } else {
        // Face is not aligned
        sessionData.resetAlignment();
        
        final issues = _identifyAlignmentIssues(face, previewSize, sessionData.toleranceSettings);
        
        emit(FaceAlignmentDetectedButNotAligned(
          sessionId: sessionId,
          detectedFace: face,
          currentAlignmentState: faceAlignmentState,
          alignmentIssues: issues,
          primaryGuidanceMessage: _getPrimaryGuidanceMessage(issues),
          allGuidanceMessages: issues.map((issue) => issue.guidanceMessage).toList(),
          detectionTime: DateTime.now(),
        ));
      }

    } catch (e) {
      add(FaceDetectionFailed(
        sessionId: sessionId,
        errorMessage: 'Alignment validation failed: $e',
      ));
    }
  }

  /// Handles face alignment achieved
  Future<void> _onFaceAlignmentAchieved(
    FaceAlignmentAchieved event,
    Emitter<FaceAlignmentState> emit,
  ) async {
    final sessionData = _sessionTracking[event.sessionId];
    if (sessionData == null) return;

    final alignmentDuration = event.alignmentDuration;
    final isStable = alignmentDuration >= 1.0; // Require 1 second of stable alignment

    emit(FaceAlignmentAligned(
      sessionId: event.sessionId,
      alignedFace: Face(boundingBox: const Rect.fromLTRB(0, 0, 100, 100)), // Placeholder
      alignmentState: FaceAlignmentState(
        isAligned: true,
        currentCountdown: 5,
        headAngles: event.alignedAngles,
        position: event.alignedPosition,
        lastValidationTime: DateTime.now(),
        alignmentDurationSeconds: alignmentDuration,
      ),
      alignmentDuration: alignmentDuration,
      isStableForCapture: isStable,
      confirmationMessage: isStable ? 'Perfect! Hold still...' : 'Keep holding...',
      alignmentStartTime: sessionData.alignmentStartTime ?? DateTime.now(),
      lastValidationTime: DateTime.now(),
    ));
  }

  /// Handles face alignment lost
  Future<void> _onFaceAlignmentLost(
    FaceAlignmentLost event,
    Emitter<FaceAlignmentState> emit,
  ) async {
    final sessionData = _sessionTracking[event.sessionId];
    if (sessionData == null) return;

    sessionData.resetAlignment();

    if (event.currentAngles != null && event.currentPosition != null) {
      // Face still detected but not aligned
      final issues = _identifyAlignmentIssuesFromLossReason(event.lossReason);
      
      emit(FaceAlignmentDetectedButNotAligned(
        sessionId: event.sessionId,
        detectedFace: Face(boundingBox: const Rect.fromLTRB(0, 0, 100, 100)), // Placeholder
        currentAlignmentState: FaceAlignmentState(
          isAligned: false,
          currentCountdown: 5,
          headAngles: event.currentAngles!,
          position: event.currentPosition!,
          lastValidationTime: DateTime.now(),
          alignmentDurationSeconds: 0.0,
        ),
        alignmentIssues: issues,
        primaryGuidanceMessage: event.lossReason.description,
        allGuidanceMessages: [event.lossReason.description],
        detectionTime: DateTime.now(),
      ));
    } else {
      // Face no longer detected
      emit(FaceAlignmentNoFaceDetected(
        sessionId: event.sessionId,
        noFaceDuration: 0.0,
        lastCheckTime: DateTime.now(),
        guidanceMessage: event.lossReason.description,
      ));
    }
  }

  // ==================== Configuration Management ====================

  /// Updates alignment tolerance settings
  Future<void> _onUpdateAlignmentTolerance(
    UpdateAlignmentTolerance event,
    Emitter<FaceAlignmentState> emit,
  ) async {
    final sessionData = _sessionTracking[event.sessionId];
    if (sessionData == null) return;

    final previousTolerance = sessionData.toleranceSettings;
    sessionData.updateTolerance(event.newTolerance);

    emit(FaceAlignmentToleranceUpdated(
      sessionId: event.sessionId,
      previousTolerance: previousTolerance,
      newTolerance: event.newTolerance,
      updateTime: DateTime.now(),
    ));
  }

  /// Resets alignment state for a session
  Future<void> _onResetAlignmentState(
    ResetAlignmentState event,
    Emitter<FaceAlignmentState> emit,
  ) async {
    final sessionData = _sessionTracking[event.sessionId];
    if (sessionData != null) {
      sessionData.resetAlignment();
    }

    emit(FaceAlignmentDetectionActive(
      sessionId: event.sessionId,
      toleranceSettings: sessionData?.toleranceSettings ?? FaceAlignmentTolerance.standard(),
      detectionStartTime: DateTime.now(),
    ));
  }

  // ==================== Error Handling ====================

  /// Handles face detection validation event (internal event)
  Future<void> _onFaceAlignmentValidating(
    FaceAlignmentValidating event,
    Emitter<FaceAlignmentState> emit,
  ) async {
    // This is handled by the validation logic above
  }

  /// Handles alignment guidance requests
  Future<void> _onAlignmentGuidanceRequested(
    AlignmentGuidanceRequested event,
    Emitter<FaceAlignmentState> emit,
  ) async {
    // Generate updated guidance based on current issues
    final guidanceMessages = event.alignmentIssues
        .map((issue) => issue.guidanceMessage)
        .toList();

    // Emit current state with updated guidance
    // This would typically update an existing aligned/misaligned state
  }

  /// Handles face detection failures
  Future<void> _onFaceDetectionFailed(
    FaceDetectionFailed event,
    Emitter<FaceAlignmentState> emit,
  ) async {
    emit(FaceAlignmentDetectionFailed(
      sessionId: event.sessionId,
      errorMessage: event.errorMessage,
      isRecoverable: event.isRecoverable,
      errorTime: DateTime.now(),
    ));
  }

  /// Handles alignment detection timeouts
  Future<void> _onAlignmentDetectionTimeout(
    AlignmentDetectionTimeout event,
    Emitter<FaceAlignmentState> emit,
  ) async {
    emit(FaceAlignmentTimeout(
      sessionId: event.sessionId,
      timeoutDuration: event.timeoutDuration,
      timeoutTime: DateTime.now(),
    ));
  }

  // ==================== Helper Methods ====================

  /// Initializes the face detector
  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: const FaceDetectorOptions(
        enableLandmarks: true,
        enableContours: true,
        enableClassification: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
  }

  /// Starts periodic validation timer for a session
  void _startValidationTimer(String sessionId) {
    _stopValidationTimer();
    
    _alignmentValidationTimer = Timer.periodic(
      const Duration(milliseconds: 100), // 10 FPS validation
      (timer) {
        final sessionData = _sessionTracking[sessionId];
        if (sessionData == null) {
          timer.cancel();
          return;
        }
        
        // Check for timeout
        if (sessionData.hasTimedOut()) {
          add(AlignmentDetectionTimeout(
            sessionId: sessionId,
            timeoutDuration: sessionData.getTimeoutDuration(),
          ));
          timer.cancel();
        }
      },
    );
  }

  /// Stops the validation timer
  void _stopValidationTimer() {
    _alignmentValidationTimer?.cancel();
    _alignmentValidationTimer = null;
  }

  /// Converts camera image to ML Kit input image
  dynamic _convertCameraImageToInputImage(
    dynamic cameraImage,
    dynamic cameraDescription,
  ) {
    // This would convert platform-specific camera image to ML Kit format
    // Implementation depends on camera package integration
    // Returning null for now as this is a complex platform-specific operation
    return null;
  }

  /// Creates face alignment state from detected face
  FaceAlignmentState _createFaceAlignmentStateFromFace(
    Face face,
    Size previewSize,
    FaceAlignmentTolerance tolerance,
  ) {
    // Extract face angles
    final headAngles = FaceAngles(
      yaw: face.headEulerAngleY ?? 0.0,
      pitch: face.headEulerAngleX ?? 0.0,
      roll: face.headEulerAngleZ ?? 0.0,
    );

    // Calculate face position relative to center
    final boundingBox = face.boundingBox;
    final centerX = boundingBox.center.dx;
    final centerY = boundingBox.center.dy;
    final previewCenterX = previewSize.width / 2;
    final previewCenterY = previewSize.height / 2;

    final normalizedX = (centerX - previewCenterX) / (previewSize.width / 2);
    final normalizedY = (centerY - previewCenterY) / (previewSize.height / 2);
    
    final scaleFactor = math.min(
      boundingBox.width / (previewSize.width * 0.6),
      boundingBox.height / (previewSize.height * 0.6),
    );

    final distanceFromCenter = math.sqrt(
      normalizedX * normalizedX + normalizedY * normalizedY
    );

    final position = FacePosition(
      normalizedX: normalizedX,
      normalizedY: normalizedY,
      scaleFactor: scaleFactor,
      distanceFromCenter: distanceFromCenter,
    );

    return FaceAlignmentState(
      isAligned: _isAlignmentValid(headAngles, position, tolerance),
      currentCountdown: 5,
      headAngles: headAngles,
      position: position,
      lastValidationTime: DateTime.now(),
      alignmentDurationSeconds: 0.0,
    );
  }

  /// Checks if alignment is valid based on tolerance
  bool _isAlignmentValid(
    FaceAngles angles,
    FacePosition position,
    FaceAlignmentTolerance tolerance,
  ) {
    return angles.isWithinTolerance(tolerance) &&
           position.isWithinTolerance(tolerance);
  }

  /// Identifies alignment issues from face and preview data
  List<AlignmentIssue> _identifyAlignmentIssues(
    Face face,
    Size previewSize,
    FaceAlignmentTolerance tolerance,
  ) {
    final issues = <AlignmentIssue>[];
    
    final headAngles = FaceAngles(
      yaw: face.headEulerAngleY ?? 0.0,
      pitch: face.headEulerAngleX ?? 0.0,
      roll: face.headEulerAngleZ ?? 0.0,
    );

    // Check head rotation issues
    if (headAngles.yaw.abs() > tolerance.maxYawDegrees) {
      issues.add(headAngles.yaw > 0 
          ? AlignmentIssue.headTurnedRight 
          : AlignmentIssue.headTurnedLeft);
    }

    if (headAngles.pitch.abs() > tolerance.maxPitchDegrees) {
      issues.add(headAngles.pitch > 0 
          ? AlignmentIssue.headTiltedUp 
          : AlignmentIssue.headTiltedDown);
    }

    if (headAngles.roll.abs() > tolerance.maxRollDegrees) {
      issues.add(headAngles.roll > 0 
          ? AlignmentIssue.headRolledRight 
          : AlignmentIssue.headRolledLeft);
    }

    // Check position issues
    final boundingBox = face.boundingBox;
    final faceArea = boundingBox.width * boundingBox.height;
    final previewArea = previewSize.width * previewSize.height;
    final faceToPreviewRatio = faceArea / previewArea;

    if (faceToPreviewRatio < 0.05) {
      issues.add(AlignmentIssue.faceTooSmall);
    } else if (faceToPreviewRatio > 0.4) {
      issues.add(AlignmentIssue.faceTooLarge);
    }

    // Check centering
    final centerX = boundingBox.center.dx;
    final centerY = boundingBox.center.dy;
    final previewCenterX = previewSize.width / 2;
    final previewCenterY = previewSize.height / 2;

    final normalizedDistanceX = (centerX - previewCenterX).abs() / (previewSize.width / 2);
    final normalizedDistanceY = (centerY - previewCenterY).abs() / (previewSize.height / 2);

    if (normalizedDistanceX > 0.3 || normalizedDistanceY > 0.3) {
      issues.add(AlignmentIssue.faceNotCentered);
    }

    return issues;
  }

  /// Identifies alignment issues from loss reason
  List<AlignmentIssue> _identifyAlignmentIssuesFromLossReason(
    AlignmentLossReason lossReason,
  ) {
    switch (lossReason) {
      case AlignmentLossReason.faceNotDetected:
        return [AlignmentIssue.noFaceDetected];
      case AlignmentLossReason.headRotationExceeded:
        return [AlignmentIssue.headTurnedLeft]; // Generic head turn issue
      case AlignmentLossReason.faceMovedOutOfBounds:
        return [AlignmentIssue.faceNotCentered];
      case AlignmentLossReason.multipleFacesDetected:
        return [AlignmentIssue.multipleFaces];
      case AlignmentLossReason.faceObscured:
        return [AlignmentIssue.faceObscured];
      case AlignmentLossReason.lightingChanged:
        return [AlignmentIssue.poorLighting];
      case AlignmentLossReason.userMovedTooFar:
        return [AlignmentIssue.faceTooSmall];
      case AlignmentLossReason.userMovedTooClose:
        return [AlignmentIssue.faceTooLarge];
    }
  }

  /// Gets primary guidance message from list of issues
  String _getPrimaryGuidanceMessage(List<AlignmentIssue> issues) {
    if (issues.isEmpty) return 'Position your face properly';
    
    // Sort by priority and return message for highest priority issue
    issues.sort((a, b) => 
        IssuesPriority.forIssue(b).index.compareTo(IssuesPriority.forIssue(a).index));
    
    return issues.first.guidanceMessage;
  }

  @override
  Future<void> close() async {
    _stopValidationTimer();
    _faceDetector?.close();
    return super.close();
  }
}

/// Internal class for tracking session data
class _SessionTrackingData {
  final String sessionId;
  final DateTime detectionStartTime;
  FaceAlignmentTolerance toleranceSettings;

  DateTime? alignmentStartTime;
  DateTime? lastDetectionTime;
  DateTime? lastProcessTime;
  DateTime? lastNoFaceTime;
  int frameNumber = 0;

  _SessionTrackingData({
    required this.sessionId,
    required this.toleranceSettings,
    required this.detectionStartTime,
  });

  void incrementFrameCount() => frameNumber++;
  
  void updateLastProcessTime() => lastProcessTime = DateTime.now();
  
  void updateLastDetectionTime(DateTime time) => lastDetectionTime = time;
  
  void updateNoFaceDetection() => lastNoFaceTime = DateTime.now();
  
  void updateAlignmentAchieved(DateTime time) => alignmentStartTime ??= time;
  
  void resetAlignment() => alignmentStartTime = null;
  
  void updateTolerance(FaceAlignmentTolerance newTolerance) => 
      toleranceSettings = newTolerance;

  double getAlignmentDuration() {
    if (alignmentStartTime == null) return 0.0;
    return DateTime.now().difference(alignmentStartTime!).inMilliseconds / 1000.0;
  }

  double getNoFaceDuration() {
    if (lastNoFaceTime == null) return 0.0;
    return DateTime.now().difference(lastNoFaceTime!).inMilliseconds / 1000.0;
  }

  bool hasTimedOut({Duration timeout = const Duration(minutes: 5)}) {
    return DateTime.now().difference(detectionStartTime) > timeout;
  }

  Duration getTimeoutDuration() {
    return DateTime.now().difference(detectionStartTime);
  }
}