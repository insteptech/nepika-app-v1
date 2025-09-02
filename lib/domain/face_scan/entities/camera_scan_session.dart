import 'package:equatable/equatable.dart';

/// Entity representing the state and configuration of a camera scanning session.
/// This encapsulates all the business logic related to camera session management.
class CameraScanSession extends Equatable {
  /// Unique identifier for this scanning session
  final String sessionId;
  
  /// User ID who owns this session
  final String userId;
  
  /// Current state of the camera session
  final CameraSessionState state;
  
  /// Configuration settings for this session
  final CameraSessionConfig config;
  
  /// Face alignment state and metrics
  final FaceAlignmentState faceAlignment;
  
  /// Session timing information
  final SessionTiming timing;
  
  /// Any error that occurred during the session
  final SessionError? error;
  
  /// Session metadata and tracking information
  final SessionMetadata metadata;

  const CameraScanSession({
    required this.sessionId,
    required this.userId,
    required this.state,
    required this.config,
    required this.faceAlignment,
    required this.timing,
    this.error,
    required this.metadata,
  });

  /// Creates a copy of this CameraScanSession with the given fields replaced with new values
  CameraScanSession copyWith({
    String? sessionId,
    String? userId,
    CameraSessionState? state,
    CameraSessionConfig? config,
    FaceAlignmentState? faceAlignment,
    SessionTiming? timing,
    SessionError? error,
    SessionMetadata? metadata,
  }) {
    return CameraScanSession(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      state: state ?? this.state,
      config: config ?? this.config,
      faceAlignment: faceAlignment ?? this.faceAlignment,
      timing: timing ?? this.timing,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Creates a new camera scan session in initializing state
  factory CameraScanSession.initialize({
    required String sessionId,
    required String userId,
    CameraSessionConfig? config,
  }) {
    return CameraScanSession(
      sessionId: sessionId,
      userId: userId,
      state: CameraSessionState.initializing,
      config: config ?? CameraSessionConfig.defaultConfig(),
      faceAlignment: FaceAlignmentState.initial(),
      timing: SessionTiming.start(),
      metadata: SessionMetadata.create(),
    );
  }

  /// Creates a failed session with error information
  factory CameraScanSession.failed({
    required String sessionId,
    required String userId,
    required SessionError error,
    CameraSessionConfig? config,
  }) {
    return CameraScanSession(
      sessionId: sessionId,
      userId: userId,
      state: CameraSessionState.failed,
      config: config ?? CameraSessionConfig.defaultConfig(),
      faceAlignment: FaceAlignmentState.initial(),
      timing: SessionTiming.start(),
      error: error,
      metadata: SessionMetadata.create(),
    );
  }

  /// Updates the session state
  CameraScanSession updateState(CameraSessionState newState) {
    return copyWith(
      state: newState,
      timing: timing.updateForState(newState),
    );
  }

  /// Updates face alignment state
  CameraScanSession updateFaceAlignment(FaceAlignmentState alignment) {
    return copyWith(faceAlignment: alignment);
  }

  /// Adds an error to the session
  CameraScanSession withError(SessionError sessionError) {
    return copyWith(
      error: sessionError,
      state: CameraSessionState.failed,
    );
  }

  /// Clears any existing error
  CameraScanSession clearError() {
    return copyWith(error: null);
  }

  /// Checks if the session is in a ready state for capture
  bool get isReadyForCapture {
    return state == CameraSessionState.ready && 
           faceAlignment.isAligned && 
           error == null;
  }

  /// Checks if the session has completed successfully
  bool get isCompleted {
    return state == CameraSessionState.captureComplete || 
           state == CameraSessionState.processingComplete;
  }

  /// Gets the total session duration in milliseconds
  int get totalDurationMs => timing.getTotalDuration();

  @override
  List<Object?> get props => [
        sessionId,
        userId,
        state,
        config,
        faceAlignment,
        timing,
        error,
        metadata,
      ];

  @override
  String toString() {
    return 'CameraScanSession('
        'sessionId: $sessionId, '
        'userId: $userId, '
        'state: $state, '
        'config: $config, '
        'faceAlignment: $faceAlignment, '
        'timing: $timing, '
        'error: $error, '
        'metadata: $metadata'
        ')';
  }
}

/// Enumeration of possible camera session states
enum CameraSessionState {
  initializing,
  permissionRequired,
  ready,
  aligningFace,
  countdown,
  capturing,
  captureComplete,
  processing,
  processingComplete,
  failed;

  /// Gets a human-readable description of the state
  String get description {
    switch (this) {
      case CameraSessionState.initializing:
        return 'Initializing Camera';
      case CameraSessionState.permissionRequired:
        return 'Camera Permission Required';
      case CameraSessionState.ready:
        return 'Ready to Scan';
      case CameraSessionState.aligningFace:
        return 'Align Your Face';
      case CameraSessionState.countdown:
        return 'Get Ready';
      case CameraSessionState.capturing:
        return 'Capturing Image';
      case CameraSessionState.captureComplete:
        return 'Image Captured';
      case CameraSessionState.processing:
        return 'Analyzing Image';
      case CameraSessionState.processingComplete:
        return 'Analysis Complete';
      case CameraSessionState.failed:
        return 'Session Failed';
    }
  }

  /// Checks if the state represents an active scanning process
  bool get isActive {
    return this == CameraSessionState.ready ||
           this == CameraSessionState.aligningFace ||
           this == CameraSessionState.countdown ||
           this == CameraSessionState.capturing;
  }
}

/// Configuration settings for a camera scanning session
class CameraSessionConfig extends Equatable {
  /// Countdown duration in seconds before capture
  final int countdownDurationSeconds;
  
  /// Whether to include annotated image in results
  final bool includeAnnotatedImage;
  
  /// Maximum session duration in seconds
  final int maxSessionDurationSeconds;
  
  /// Face alignment tolerance settings
  final FaceAlignmentTolerance alignmentTolerance;
  
  /// Image quality requirements
  final ImageQualityRequirements qualityRequirements;
  
  /// Whether to automatically retry on failure
  final bool autoRetryOnFailure;
  
  /// Maximum number of retry attempts
  final int maxRetryAttempts;

  const CameraSessionConfig({
    required this.countdownDurationSeconds,
    required this.includeAnnotatedImage,
    required this.maxSessionDurationSeconds,
    required this.alignmentTolerance,
    required this.qualityRequirements,
    required this.autoRetryOnFailure,
    required this.maxRetryAttempts,
  });

  /// Creates default configuration settings
  factory CameraSessionConfig.defaultConfig() {
    return CameraSessionConfig(
      countdownDurationSeconds: 5,
      includeAnnotatedImage: true,
      maxSessionDurationSeconds: 300, // 5 minutes
      alignmentTolerance: FaceAlignmentTolerance.standard(),
      qualityRequirements: ImageQualityRequirements.standard(),
      autoRetryOnFailure: true,
      maxRetryAttempts: 3,
    );
  }

  /// Creates a copy of this CameraSessionConfig with the given fields replaced with new values
  CameraSessionConfig copyWith({
    int? countdownDurationSeconds,
    bool? includeAnnotatedImage,
    int? maxSessionDurationSeconds,
    FaceAlignmentTolerance? alignmentTolerance,
    ImageQualityRequirements? qualityRequirements,
    bool? autoRetryOnFailure,
    int? maxRetryAttempts,
  }) {
    return CameraSessionConfig(
      countdownDurationSeconds: countdownDurationSeconds ?? this.countdownDurationSeconds,
      includeAnnotatedImage: includeAnnotatedImage ?? this.includeAnnotatedImage,
      maxSessionDurationSeconds: maxSessionDurationSeconds ?? this.maxSessionDurationSeconds,
      alignmentTolerance: alignmentTolerance ?? this.alignmentTolerance,
      qualityRequirements: qualityRequirements ?? this.qualityRequirements,
      autoRetryOnFailure: autoRetryOnFailure ?? this.autoRetryOnFailure,
      maxRetryAttempts: maxRetryAttempts ?? this.maxRetryAttempts,
    );
  }

  @override
  List<Object?> get props => [
        countdownDurationSeconds,
        includeAnnotatedImage,
        maxSessionDurationSeconds,
        alignmentTolerance,
        qualityRequirements,
        autoRetryOnFailure,
        maxRetryAttempts,
      ];

  @override
  String toString() {
    return 'CameraSessionConfig('
        'countdownDurationSeconds: $countdownDurationSeconds, '
        'includeAnnotatedImage: $includeAnnotatedImage, '
        'maxSessionDurationSeconds: $maxSessionDurationSeconds, '
        'alignmentTolerance: $alignmentTolerance, '
        'qualityRequirements: $qualityRequirements, '
        'autoRetryOnFailure: $autoRetryOnFailure, '
        'maxRetryAttempts: $maxRetryAttempts'
        ')';
  }
}

/// Face alignment state and validation
class FaceAlignmentState extends Equatable {
  /// Whether the face is currently aligned
  final bool isAligned;
  
  /// Current countdown value (0 means capture ready)
  final int currentCountdown;
  
  /// Head rotation angles
  final FaceAngles headAngles;
  
  /// Face position relative to the target area
  final FacePosition position;
  
  /// Timestamp when alignment was last validated
  final DateTime lastValidationTime;
  
  /// How long the face has been aligned continuously (in seconds)
  final double alignmentDurationSeconds;

  const FaceAlignmentState({
    required this.isAligned,
    required this.currentCountdown,
    required this.headAngles,
    required this.position,
    required this.lastValidationTime,
    required this.alignmentDurationSeconds,
  });

  /// Creates initial alignment state
  factory FaceAlignmentState.initial() {
    return FaceAlignmentState(
      isAligned: false,
      currentCountdown: 5,
      headAngles: FaceAngles.neutral(),
      position: FacePosition.center(),
      lastValidationTime: DateTime.now(),
      alignmentDurationSeconds: 0.0,
    );
  }

  /// Creates a copy of this FaceAlignmentState with the given fields replaced with new values
  FaceAlignmentState copyWith({
    bool? isAligned,
    int? currentCountdown,
    FaceAngles? headAngles,
    FacePosition? position,
    DateTime? lastValidationTime,
    double? alignmentDurationSeconds,
  }) {
    return FaceAlignmentState(
      isAligned: isAligned ?? this.isAligned,
      currentCountdown: currentCountdown ?? this.currentCountdown,
      headAngles: headAngles ?? this.headAngles,
      position: position ?? this.position,
      lastValidationTime: lastValidationTime ?? this.lastValidationTime,
      alignmentDurationSeconds: alignmentDurationSeconds ?? this.alignmentDurationSeconds,
    );
  }

  /// Updates alignment state with new validation results
  FaceAlignmentState updateAlignment({
    required bool aligned,
    required FaceAngles angles,
    required FacePosition facePosition,
  }) {
    final now = DateTime.now();
    final duration = aligned && isAligned 
        ? alignmentDurationSeconds + now.difference(lastValidationTime).inMilliseconds / 1000.0
        : 0.0;

    return copyWith(
      isAligned: aligned,
      headAngles: angles,
      position: facePosition,
      lastValidationTime: now,
      alignmentDurationSeconds: duration,
    );
  }

  /// Decrements the countdown
  FaceAlignmentState decrementCountdown() {
    return copyWith(currentCountdown: (currentCountdown - 1).clamp(0, 10));
  }

  /// Resets the countdown
  FaceAlignmentState resetCountdown(int initialValue) {
    return copyWith(currentCountdown: initialValue);
  }

  @override
  List<Object?> get props => [
        isAligned,
        currentCountdown,
        headAngles,
        position,
        lastValidationTime,
        alignmentDurationSeconds,
      ];

  @override
  String toString() {
    return 'FaceAlignmentState('
        'isAligned: $isAligned, '
        'currentCountdown: $currentCountdown, '
        'headAngles: $headAngles, '
        'position: $position, '
        'lastValidationTime: $lastValidationTime, '
        'alignmentDurationSeconds: $alignmentDurationSeconds'
        ')';
  }
}

/// Face angle measurements
class FaceAngles extends Equatable {
  /// Rotation around Y axis (left-right head turn)
  final double yaw;
  
  /// Rotation around X axis (up-down head tilt)
  final double pitch;
  
  /// Rotation around Z axis (head roll/tilt)
  final double roll;

  const FaceAngles({
    required this.yaw,
    required this.pitch,
    required this.roll,
  });

  /// Creates neutral face angles (looking straight ahead)
  factory FaceAngles.neutral() {
    return const FaceAngles(yaw: 0.0, pitch: 0.0, roll: 0.0);
  }

  /// Checks if angles are within acceptable range for scanning
  bool isWithinTolerance(FaceAlignmentTolerance tolerance) {
    return yaw.abs() <= tolerance.maxYawDegrees &&
           pitch.abs() <= tolerance.maxPitchDegrees &&
           roll.abs() <= tolerance.maxRollDegrees;
  }

  /// Creates a copy of this FaceAngles with the given fields replaced with new values
  FaceAngles copyWith({
    double? yaw,
    double? pitch,
    double? roll,
  }) {
    return FaceAngles(
      yaw: yaw ?? this.yaw,
      pitch: pitch ?? this.pitch,
      roll: roll ?? this.roll,
    );
  }

  @override
  List<Object?> get props => [yaw, pitch, roll];

  @override
  String toString() {
    return 'FaceAngles(yaw: $yaw, pitch: $pitch, roll: $roll)';
  }
}

/// Face position relative to target area
class FacePosition extends Equatable {
  /// Normalized X position (-1 to 1, 0 = center)
  final double normalizedX;
  
  /// Normalized Y position (-1 to 1, 0 = center)
  final double normalizedY;
  
  /// Scale factor of face relative to ideal size (1.0 = ideal)
  final double scaleFactor;
  
  /// Distance from center of target area
  final double distanceFromCenter;

  const FacePosition({
    required this.normalizedX,
    required this.normalizedY,
    required this.scaleFactor,
    required this.distanceFromCenter,
  });

  /// Creates centered face position
  factory FacePosition.center() {
    return const FacePosition(
      normalizedX: 0.0,
      normalizedY: 0.0,
      scaleFactor: 1.0,
      distanceFromCenter: 0.0,
    );
  }

  /// Checks if position is within acceptable range
  bool isWithinTolerance(FaceAlignmentTolerance tolerance) {
    return distanceFromCenter <= tolerance.maxDistanceFromCenter &&
           scaleFactor >= tolerance.minScaleFactor &&
           scaleFactor <= tolerance.maxScaleFactor;
  }

  /// Creates a copy of this FacePosition with the given fields replaced with new values
  FacePosition copyWith({
    double? normalizedX,
    double? normalizedY,
    double? scaleFactor,
    double? distanceFromCenter,
  }) {
    return FacePosition(
      normalizedX: normalizedX ?? this.normalizedX,
      normalizedY: normalizedY ?? this.normalizedY,
      scaleFactor: scaleFactor ?? this.scaleFactor,
      distanceFromCenter: distanceFromCenter ?? this.distanceFromCenter,
    );
  }

  @override
  List<Object?> get props => [
        normalizedX,
        normalizedY,
        scaleFactor,
        distanceFromCenter,
      ];

  @override
  String toString() {
    return 'FacePosition('
        'normalizedX: $normalizedX, '
        'normalizedY: $normalizedY, '
        'scaleFactor: $scaleFactor, '
        'distanceFromCenter: $distanceFromCenter'
        ')';
  }
}

/// Tolerance settings for face alignment validation
class FaceAlignmentTolerance extends Equatable {
  /// Maximum acceptable yaw angle in degrees
  final double maxYawDegrees;
  
  /// Maximum acceptable pitch angle in degrees
  final double maxPitchDegrees;
  
  /// Maximum acceptable roll angle in degrees
  final double maxRollDegrees;
  
  /// Maximum distance from center (0-1)
  final double maxDistanceFromCenter;
  
  /// Minimum acceptable scale factor
  final double minScaleFactor;
  
  /// Maximum acceptable scale factor
  final double maxScaleFactor;

  const FaceAlignmentTolerance({
    required this.maxYawDegrees,
    required this.maxPitchDegrees,
    required this.maxRollDegrees,
    required this.maxDistanceFromCenter,
    required this.minScaleFactor,
    required this.maxScaleFactor,
  });

  /// Creates standard tolerance settings
  factory FaceAlignmentTolerance.standard() {
    return const FaceAlignmentTolerance(
      maxYawDegrees: 10.0,
      maxPitchDegrees: 15.0,
      maxRollDegrees: 10.0,
      maxDistanceFromCenter: 0.3,
      minScaleFactor: 0.8,
      maxScaleFactor: 1.2,
    );
  }

  /// Creates strict tolerance settings for high-quality scans
  factory FaceAlignmentTolerance.strict() {
    return const FaceAlignmentTolerance(
      maxYawDegrees: 5.0,
      maxPitchDegrees: 8.0,
      maxRollDegrees: 5.0,
      maxDistanceFromCenter: 0.2,
      minScaleFactor: 0.9,
      maxScaleFactor: 1.1,
    );
  }

  /// Creates a copy of this FaceAlignmentTolerance with the given fields replaced with new values
  FaceAlignmentTolerance copyWith({
    double? maxYawDegrees,
    double? maxPitchDegrees,
    double? maxRollDegrees,
    double? maxDistanceFromCenter,
    double? minScaleFactor,
    double? maxScaleFactor,
  }) {
    return FaceAlignmentTolerance(
      maxYawDegrees: maxYawDegrees ?? this.maxYawDegrees,
      maxPitchDegrees: maxPitchDegrees ?? this.maxPitchDegrees,
      maxRollDegrees: maxRollDegrees ?? this.maxRollDegrees,
      maxDistanceFromCenter: maxDistanceFromCenter ?? this.maxDistanceFromCenter,
      minScaleFactor: minScaleFactor ?? this.minScaleFactor,
      maxScaleFactor: maxScaleFactor ?? this.maxScaleFactor,
    );
  }

  @override
  List<Object?> get props => [
        maxYawDegrees,
        maxPitchDegrees,
        maxRollDegrees,
        maxDistanceFromCenter,
        minScaleFactor,
        maxScaleFactor,
      ];

  @override
  String toString() {
    return 'FaceAlignmentTolerance('
        'maxYawDegrees: $maxYawDegrees, '
        'maxPitchDegrees: $maxPitchDegrees, '
        'maxRollDegrees: $maxRollDegrees, '
        'maxDistanceFromCenter: $maxDistanceFromCenter, '
        'minScaleFactor: $minScaleFactor, '
        'maxScaleFactor: $maxScaleFactor'
        ')';
  }
}

/// Image quality requirements for valid scans
class ImageQualityRequirements extends Equatable {
  /// Minimum brightness level (0-100)
  final int minBrightness;
  
  /// Maximum brightness level (0-100)
  final int maxBrightness;
  
  /// Minimum sharpness level (0-100)
  final int minSharpness;
  
  /// Minimum clarity level (0-100)
  final int minClarity;
  
  /// Minimum overall quality score (0-100)
  final int minQualityScore;

  const ImageQualityRequirements({
    required this.minBrightness,
    required this.maxBrightness,
    required this.minSharpness,
    required this.minClarity,
    required this.minQualityScore,
  });

  /// Creates standard quality requirements
  factory ImageQualityRequirements.standard() {
    return const ImageQualityRequirements(
      minBrightness: 30,
      maxBrightness: 90,
      minSharpness: 60,
      minClarity: 70,
      minQualityScore: 60,
    );
  }

  /// Creates a copy of this ImageQualityRequirements with the given fields replaced with new values
  ImageQualityRequirements copyWith({
    int? minBrightness,
    int? maxBrightness,
    int? minSharpness,
    int? minClarity,
    int? minQualityScore,
  }) {
    return ImageQualityRequirements(
      minBrightness: minBrightness ?? this.minBrightness,
      maxBrightness: maxBrightness ?? this.maxBrightness,
      minSharpness: minSharpness ?? this.minSharpness,
      minClarity: minClarity ?? this.minClarity,
      minQualityScore: minQualityScore ?? this.minQualityScore,
    );
  }

  @override
  List<Object?> get props => [
        minBrightness,
        maxBrightness,
        minSharpness,
        minClarity,
        minQualityScore,
      ];

  @override
  String toString() {
    return 'ImageQualityRequirements('
        'minBrightness: $minBrightness, '
        'maxBrightness: $maxBrightness, '
        'minSharpness: $minSharpness, '
        'minClarity: $minClarity, '
        'minQualityScore: $minQualityScore'
        ')';
  }
}

/// Session timing information
class SessionTiming extends Equatable {
  /// When the session was started
  final DateTime startTime;
  
  /// When camera initialization completed
  final DateTime? cameraReadyTime;
  
  /// When face alignment was first achieved
  final DateTime? alignmentStartTime;
  
  /// When countdown began
  final DateTime? countdownStartTime;
  
  /// When image capture occurred
  final DateTime? captureTime;
  
  /// When processing began
  final DateTime? processingStartTime;
  
  /// When session completed
  final DateTime? completionTime;

  const SessionTiming({
    required this.startTime,
    this.cameraReadyTime,
    this.alignmentStartTime,
    this.countdownStartTime,
    this.captureTime,
    this.processingStartTime,
    this.completionTime,
  });

  /// Creates initial timing with start time
  factory SessionTiming.start() {
    return SessionTiming(startTime: DateTime.now());
  }

  /// Updates timing for a specific state
  SessionTiming updateForState(CameraSessionState state) {
    final now = DateTime.now();
    
    switch (state) {
      case CameraSessionState.ready:
        return copyWith(cameraReadyTime: now);
      case CameraSessionState.aligningFace:
        return copyWith(alignmentStartTime: alignmentStartTime ?? now);
      case CameraSessionState.countdown:
        return copyWith(countdownStartTime: countdownStartTime ?? now);
      case CameraSessionState.capturing:
        return copyWith(captureTime: now);
      case CameraSessionState.processing:
        return copyWith(processingStartTime: now);
      case CameraSessionState.processingComplete:
      case CameraSessionState.failed:
        return copyWith(completionTime: now);
      default:
        return this;
    }
  }

  /// Gets total session duration in milliseconds
  int getTotalDuration() {
    final endTime = completionTime ?? DateTime.now();
    return endTime.difference(startTime).inMilliseconds;
  }

  /// Gets time to complete camera initialization
  int? getCameraInitializationTime() {
    return cameraReadyTime?.difference(startTime).inMilliseconds;
  }

  /// Gets time spent aligning face
  int? getFaceAlignmentTime() {
    if (alignmentStartTime == null || countdownStartTime == null) return null;
    return countdownStartTime!.difference(alignmentStartTime!).inMilliseconds;
  }

  /// Gets processing time
  int? getProcessingTime() {
    if (processingStartTime == null || completionTime == null) return null;
    return completionTime!.difference(processingStartTime!).inMilliseconds;
  }

  /// Creates a copy of this SessionTiming with the given fields replaced with new values
  SessionTiming copyWith({
    DateTime? startTime,
    DateTime? cameraReadyTime,
    DateTime? alignmentStartTime,
    DateTime? countdownStartTime,
    DateTime? captureTime,
    DateTime? processingStartTime,
    DateTime? completionTime,
  }) {
    return SessionTiming(
      startTime: startTime ?? this.startTime,
      cameraReadyTime: cameraReadyTime ?? this.cameraReadyTime,
      alignmentStartTime: alignmentStartTime ?? this.alignmentStartTime,
      countdownStartTime: countdownStartTime ?? this.countdownStartTime,
      captureTime: captureTime ?? this.captureTime,
      processingStartTime: processingStartTime ?? this.processingStartTime,
      completionTime: completionTime ?? this.completionTime,
    );
  }

  @override
  List<Object?> get props => [
        startTime,
        cameraReadyTime,
        alignmentStartTime,
        countdownStartTime,
        captureTime,
        processingStartTime,
        completionTime,
      ];

  @override
  String toString() {
    return 'SessionTiming('
        'startTime: $startTime, '
        'cameraReadyTime: $cameraReadyTime, '
        'alignmentStartTime: $alignmentStartTime, '
        'countdownStartTime: $countdownStartTime, '
        'captureTime: $captureTime, '
        'processingStartTime: $processingStartTime, '
        'completionTime: $completionTime'
        ')';
  }
}

/// Session error information
class SessionError extends Equatable {
  /// Type of error that occurred
  final SessionErrorType errorType;
  
  /// Human-readable error message
  final String message;
  
  /// Technical error code
  final String? errorCode;
  
  /// When the error occurred
  final DateTime timestamp;
  
  /// Whether this error is recoverable
  final bool isRecoverable;
  
  /// Additional context about the error
  final Map<String, dynamic> context;

  const SessionError({
    required this.errorType,
    required this.message,
    this.errorCode,
    required this.timestamp,
    required this.isRecoverable,
    required this.context,
  });

  /// Creates a camera initialization error
  factory SessionError.cameraInitialization(String message, {String? code}) {
    return SessionError(
      errorType: SessionErrorType.cameraInitialization,
      message: message,
      errorCode: code,
      timestamp: DateTime.now(),
      isRecoverable: true,
      context: {},
    );
  }

  /// Creates a permission error
  factory SessionError.permission(String message) {
    return SessionError(
      errorType: SessionErrorType.permission,
      message: message,
      timestamp: DateTime.now(),
      isRecoverable: true,
      context: {},
    );
  }

  /// Creates a capture error
  factory SessionError.capture(String message, {String? code}) {
    return SessionError(
      errorType: SessionErrorType.capture,
      message: message,
      errorCode: code,
      timestamp: DateTime.now(),
      isRecoverable: true,
      context: {},
    );
  }

  /// Creates a processing error
  factory SessionError.processing(String message, {String? code, Map<String, dynamic>? additionalContext}) {
    return SessionError(
      errorType: SessionErrorType.processing,
      message: message,
      errorCode: code,
      timestamp: DateTime.now(),
      isRecoverable: true,
      context: additionalContext ?? {},
    );
  }

  /// Creates a network error
  factory SessionError.network(String message, {String? code}) {
    return SessionError(
      errorType: SessionErrorType.network,
      message: message,
      errorCode: code,
      timestamp: DateTime.now(),
      isRecoverable: true,
      context: {},
    );
  }

  /// Creates a timeout error
  factory SessionError.timeout(String message) {
    return SessionError(
      errorType: SessionErrorType.timeout,
      message: message,
      timestamp: DateTime.now(),
      isRecoverable: true,
      context: {},
    );
  }

  /// Creates a copy of this SessionError with the given fields replaced with new values
  SessionError copyWith({
    SessionErrorType? errorType,
    String? message,
    String? errorCode,
    DateTime? timestamp,
    bool? isRecoverable,
    Map<String, dynamic>? context,
  }) {
    return SessionError(
      errorType: errorType ?? this.errorType,
      message: message ?? this.message,
      errorCode: errorCode ?? this.errorCode,
      timestamp: timestamp ?? this.timestamp,
      isRecoverable: isRecoverable ?? this.isRecoverable,
      context: context ?? this.context,
    );
  }

  @override
  List<Object?> get props => [
        errorType,
        message,
        errorCode,
        timestamp,
        isRecoverable,
        context,
      ];

  @override
  String toString() {
    return 'SessionError('
        'errorType: $errorType, '
        'message: $message, '
        'errorCode: $errorCode, '
        'timestamp: $timestamp, '
        'isRecoverable: $isRecoverable, '
        'context: $context'
        ')';
  }
}

/// Types of session errors
enum SessionErrorType {
  cameraInitialization,
  permission,
  capture,
  processing,
  network,
  timeout,
  unknown;

  /// Gets a user-friendly description of the error type
  String get description {
    switch (this) {
      case SessionErrorType.cameraInitialization:
        return 'Camera Initialization Error';
      case SessionErrorType.permission:
        return 'Permission Error';
      case SessionErrorType.capture:
        return 'Image Capture Error';
      case SessionErrorType.processing:
        return 'Processing Error';
      case SessionErrorType.network:
        return 'Network Error';
      case SessionErrorType.timeout:
        return 'Timeout Error';
      case SessionErrorType.unknown:
        return 'Unknown Error';
    }
  }
}

/// Session metadata for tracking and analytics
class SessionMetadata extends Equatable {
  /// Session creation timestamp
  final DateTime createdAt;
  
  /// Device information
  final Map<String, String> deviceInfo;
  
  /// App version
  final String appVersion;
  
  /// Session tags for categorization
  final List<String> tags;
  
  /// Custom properties for analytics
  final Map<String, dynamic> properties;

  const SessionMetadata({
    required this.createdAt,
    required this.deviceInfo,
    required this.appVersion,
    required this.tags,
    required this.properties,
  });

  /// Creates initial metadata
  factory SessionMetadata.create({
    Map<String, String>? deviceInfo,
    String appVersion = '1.0.0',
    List<String>? tags,
    Map<String, dynamic>? properties,
  }) {
    return SessionMetadata(
      createdAt: DateTime.now(),
      deviceInfo: deviceInfo ?? {},
      appVersion: appVersion,
      tags: tags ?? [],
      properties: properties ?? {},
    );
  }

  /// Creates a copy of this SessionMetadata with the given fields replaced with new values
  SessionMetadata copyWith({
    DateTime? createdAt,
    Map<String, String>? deviceInfo,
    String? appVersion,
    List<String>? tags,
    Map<String, dynamic>? properties,
  }) {
    return SessionMetadata(
      createdAt: createdAt ?? this.createdAt,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      appVersion: appVersion ?? this.appVersion,
      tags: tags ?? this.tags,
      properties: properties ?? this.properties,
    );
  }

  @override
  List<Object?> get props => [
        createdAt,
        deviceInfo,
        appVersion,
        tags,
        properties,
      ];

  @override
  String toString() {
    return 'SessionMetadata('
        'createdAt: $createdAt, '
        'deviceInfo: $deviceInfo, '
        'appVersion: $appVersion, '
        'tags: $tags, '
        'properties: $properties'
        ')';
  }
}