import '../../../domain/face_scan/entities/camera_scan_session.dart';

/// Data model for camera scanning session persistence.
/// Handles serialization of session state for local storage and recovery.
class CameraScanSessionModel {
  /// Unique session identifier
  final String sessionId;
  
  /// User ID who owns the session
  final String userId;
  
  /// Current session state
  final String state;
  
  /// Session configuration
  final Map<String, dynamic> config;
  
  /// Face alignment state
  final Map<String, dynamic> faceAlignment;
  
  /// Session timing information
  final Map<String, dynamic> timing;
  
  /// Error information if any
  final Map<String, dynamic>? error;
  
  /// Session metadata
  final Map<String, dynamic> metadata;
  
  /// Session creation timestamp
  final DateTime createdAt;
  
  /// Last update timestamp
  final DateTime updatedAt;

  const CameraScanSessionModel({
    required this.sessionId,
    required this.userId,
    required this.state,
    required this.config,
    required this.faceAlignment,
    required this.timing,
    this.error,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates from domain entity
  factory CameraScanSessionModel.fromEntity(CameraScanSession session) {
    return CameraScanSessionModel(
      sessionId: session.sessionId,
      userId: session.userId,
      state: session.state.name,
      config: _configToJson(session.config),
      faceAlignment: _faceAlignmentToJson(session.faceAlignment),
      timing: _timingToJson(session.timing),
      error: session.error != null ? _errorToJson(session.error!) : null,
      metadata: _metadataToJson(session.metadata),
      createdAt: session.timing.startTime,
      updatedAt: DateTime.now(),
    );
  }

  /// Creates from JSON for storage/retrieval
  factory CameraScanSessionModel.fromJson(Map<String, dynamic> json) {
    return CameraScanSessionModel(
      sessionId: json['session_id'] as String,
      userId: json['user_id'] as String,
      state: json['state'] as String,
      config: json['config'] as Map<String, dynamic>? ?? {},
      faceAlignment: json['face_alignment'] as Map<String, dynamic>? ?? {},
      timing: json['timing'] as Map<String, dynamic>? ?? {},
      error: json['error'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Converts to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'state': state,
      'config': config,
      'face_alignment': faceAlignment,
      'timing': timing,
      'error': error,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Converts to domain entity
  CameraScanSession toEntity() {
    return CameraScanSession(
      sessionId: sessionId,
      userId: userId,
      state: _parseSessionState(state),
      config: _configFromJson(config),
      faceAlignment: _faceAlignmentFromJson(faceAlignment),
      timing: _timingFromJson(timing),
      error: error != null ? _errorFromJson(error!) : null,
      metadata: _metadataFromJson(metadata),
    );
  }

  /// Updates the session state and timestamp
  CameraScanSessionModel updateState(String newState) {
    return copyWith(
      state: newState,
      updatedAt: DateTime.now(),
    );
  }

  /// Updates face alignment data
  CameraScanSessionModel updateFaceAlignment(Map<String, dynamic> alignment) {
    return copyWith(
      faceAlignment: alignment,
      updatedAt: DateTime.now(),
    );
  }

  /// Adds error information
  CameraScanSessionModel withError(Map<String, dynamic> errorInfo) {
    return copyWith(
      error: errorInfo,
      state: 'failed',
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a copy with updated fields
  CameraScanSessionModel copyWith({
    String? sessionId,
    String? userId,
    String? state,
    Map<String, dynamic>? config,
    Map<String, dynamic>? faceAlignment,
    Map<String, dynamic>? timing,
    Map<String, dynamic>? error,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CameraScanSessionModel(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      state: state ?? this.state,
      config: config ?? this.config,
      faceAlignment: faceAlignment ?? this.faceAlignment,
      timing: timing ?? this.timing,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods for serialization

  static Map<String, dynamic> _configToJson(CameraSessionConfig config) {
    return {
      'countdown_duration_seconds': config.countdownDurationSeconds,
      'include_annotated_image': config.includeAnnotatedImage,
      'max_session_duration_seconds': config.maxSessionDurationSeconds,
      'auto_retry_on_failure': config.autoRetryOnFailure,
      'max_retry_attempts': config.maxRetryAttempts,
    };
  }

  static CameraSessionConfig _configFromJson(Map<String, dynamic> json) {
    return CameraSessionConfig(
      countdownDurationSeconds: json['countdown_duration_seconds'] as int? ?? 5,
      includeAnnotatedImage: json['include_annotated_image'] as bool? ?? true,
      maxSessionDurationSeconds: json['max_session_duration_seconds'] as int? ?? 300,
      alignmentTolerance: FaceAlignmentTolerance.standard(),
      qualityRequirements: ImageQualityRequirements.standard(),
      autoRetryOnFailure: json['auto_retry_on_failure'] as bool? ?? true,
      maxRetryAttempts: json['max_retry_attempts'] as int? ?? 3,
    );
  }

  static Map<String, dynamic> _faceAlignmentToJson(FaceAlignmentState alignment) {
    return {
      'is_aligned': alignment.isAligned,
      'current_countdown': alignment.currentCountdown,
      'head_angles': {
        'yaw': alignment.headAngles.yaw,
        'pitch': alignment.headAngles.pitch,
        'roll': alignment.headAngles.roll,
      },
      'position': {
        'normalized_x': alignment.position.normalizedX,
        'normalized_y': alignment.position.normalizedY,
        'scale_factor': alignment.position.scaleFactor,
        'distance_from_center': alignment.position.distanceFromCenter,
      },
      'last_validation_time': alignment.lastValidationTime.toIso8601String(),
      'alignment_duration_seconds': alignment.alignmentDurationSeconds,
    };
  }

  static FaceAlignmentState _faceAlignmentFromJson(Map<String, dynamic> json) {
    final headAnglesData = json['head_angles'] as Map<String, dynamic>? ?? {};
    final positionData = json['position'] as Map<String, dynamic>? ?? {};
    
    return FaceAlignmentState(
      isAligned: json['is_aligned'] as bool? ?? false,
      currentCountdown: json['current_countdown'] as int? ?? 5,
      headAngles: FaceAngles(
        yaw: headAnglesData['yaw'] as double? ?? 0.0,
        pitch: headAnglesData['pitch'] as double? ?? 0.0,
        roll: headAnglesData['roll'] as double? ?? 0.0,
      ),
      position: FacePosition(
        normalizedX: positionData['normalized_x'] as double? ?? 0.0,
        normalizedY: positionData['normalized_y'] as double? ?? 0.0,
        scaleFactor: positionData['scale_factor'] as double? ?? 1.0,
        distanceFromCenter: positionData['distance_from_center'] as double? ?? 0.0,
      ),
      lastValidationTime: json['last_validation_time'] != null
          ? DateTime.parse(json['last_validation_time'] as String)
          : DateTime.now(),
      alignmentDurationSeconds: json['alignment_duration_seconds'] as double? ?? 0.0,
    );
  }

  static Map<String, dynamic> _timingToJson(SessionTiming timing) {
    return {
      'start_time': timing.startTime.toIso8601String(),
      'camera_ready_time': timing.cameraReadyTime?.toIso8601String(),
      'alignment_start_time': timing.alignmentStartTime?.toIso8601String(),
      'countdown_start_time': timing.countdownStartTime?.toIso8601String(),
      'capture_time': timing.captureTime?.toIso8601String(),
      'processing_start_time': timing.processingStartTime?.toIso8601String(),
      'completion_time': timing.completionTime?.toIso8601String(),
    };
  }

  static SessionTiming _timingFromJson(Map<String, dynamic> json) {
    return SessionTiming(
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : DateTime.now(),
      cameraReadyTime: json['camera_ready_time'] != null
          ? DateTime.parse(json['camera_ready_time'] as String)
          : null,
      alignmentStartTime: json['alignment_start_time'] != null
          ? DateTime.parse(json['alignment_start_time'] as String)
          : null,
      countdownStartTime: json['countdown_start_time'] != null
          ? DateTime.parse(json['countdown_start_time'] as String)
          : null,
      captureTime: json['capture_time'] != null
          ? DateTime.parse(json['capture_time'] as String)
          : null,
      processingStartTime: json['processing_start_time'] != null
          ? DateTime.parse(json['processing_start_time'] as String)
          : null,
      completionTime: json['completion_time'] != null
          ? DateTime.parse(json['completion_time'] as String)
          : null,
    );
  }

  static Map<String, dynamic>? _errorToJson(SessionError error) {
    return {
      'error_type': error.errorType.name,
      'message': error.message,
      'error_code': error.errorCode,
      'timestamp': error.timestamp.toIso8601String(),
      'is_recoverable': error.isRecoverable,
      'context': error.context,
    };
  }

  static SessionError _errorFromJson(Map<String, dynamic> json) {
    return SessionError(
      errorType: _parseErrorType(json['error_type'] as String? ?? 'unknown'),
      message: json['message'] as String? ?? 'Unknown error',
      errorCode: json['error_code'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isRecoverable: json['is_recoverable'] as bool? ?? true,
      context: json['context'] as Map<String, dynamic>? ?? {},
    );
  }

  static Map<String, dynamic> _metadataToJson(SessionMetadata metadata) {
    return {
      'created_at': metadata.createdAt.toIso8601String(),
      'device_info': metadata.deviceInfo,
      'app_version': metadata.appVersion,
      'tags': metadata.tags,
      'properties': metadata.properties,
    };
  }

  static SessionMetadata _metadataFromJson(Map<String, dynamic> json) {
    return SessionMetadata(
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      deviceInfo: Map<String, String>.from(json['device_info'] as Map? ?? {}),
      appVersion: json['app_version'] as String? ?? '1.0.0',
      tags: List<String>.from(json['tags'] as List? ?? []),
      properties: json['properties'] as Map<String, dynamic>? ?? {},
    );
  }

  static CameraSessionState _parseSessionState(String state) {
    switch (state.toLowerCase()) {
      case 'initializing':
        return CameraSessionState.initializing;
      case 'permissionrequired':
        return CameraSessionState.permissionRequired;
      case 'ready':
        return CameraSessionState.ready;
      case 'aligningface':
        return CameraSessionState.aligningFace;
      case 'countdown':
        return CameraSessionState.countdown;
      case 'capturing':
        return CameraSessionState.capturing;
      case 'capturecomplete':
        return CameraSessionState.captureComplete;
      case 'processing':
        return CameraSessionState.processing;
      case 'processingcomplete':
        return CameraSessionState.processingComplete;
      case 'failed':
        return CameraSessionState.failed;
      default:
        return CameraSessionState.initializing;
    }
  }

  static SessionErrorType _parseErrorType(String errorType) {
    switch (errorType.toLowerCase()) {
      case 'camerainitialization':
        return SessionErrorType.cameraInitialization;
      case 'permission':
        return SessionErrorType.permission;
      case 'capture':
        return SessionErrorType.capture;
      case 'processing':
        return SessionErrorType.processing;
      case 'network':
        return SessionErrorType.network;
      case 'timeout':
        return SessionErrorType.timeout;
      default:
        return SessionErrorType.unknown;
    }
  }

  @override
  String toString() {
    return 'CameraScanSessionModel('
        'sessionId: $sessionId, '
        'userId: $userId, '
        'state: $state, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CameraScanSessionModel &&
        other.sessionId == sessionId &&
        other.userId == userId &&
        other.state == state &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return sessionId.hashCode ^
        userId.hashCode ^
        state.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}