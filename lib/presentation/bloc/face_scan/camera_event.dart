import 'package:equatable/equatable.dart';
import 'package:camera/camera.dart';

/// Base class for all camera-related events.
/// This BLoC focuses specifically on camera hardware management and permissions.
abstract class CameraEvent extends Equatable {
  const CameraEvent();
  
  @override
  List<Object?> get props => [];
}

// ==================== Permission Events ====================

/// Requests camera permission from the system.
class CameraPermissionRequested extends CameraEvent {
  const CameraPermissionRequested();

  @override
  String toString() => 'CameraPermissionRequested()';
}

/// Reports the result of a camera permission request.
class CameraPermissionUpdated extends CameraEvent {
  /// Whether camera permission was granted
  final bool isGranted;
  
  /// Whether the permission is permanently denied
  final bool isPermanentlyDenied;

  const CameraPermissionUpdated({
    required this.isGranted,
    required this.isPermanentlyDenied,
  });

  @override
  List<Object?> get props => [isGranted, isPermanentlyDenied];

  @override
  String toString() {
    return 'CameraPermissionUpdated(isGranted: $isGranted, isPermanentlyDenied: $isPermanentlyDenied)';
  }
}

// ==================== Camera Discovery Events ====================

/// Requests discovery of available cameras on the device.
class CameraDiscoveryRequested extends CameraEvent {
  const CameraDiscoveryRequested();

  @override
  String toString() => 'CameraDiscoveryRequested()';
}

/// Reports the list of discovered cameras.
class CamerasDiscovered extends CameraEvent {
  /// List of available camera descriptions
  final List<CameraDescription> cameras;

  const CamerasDiscovered({required this.cameras});

  @override
  List<Object?> get props => [cameras];

  @override
  String toString() => 'CamerasDiscovered(count: ${cameras.length})';
}

/// Camera discovery failed due to an error.
class CameraDiscoveryFailed extends CameraEvent {
  /// Error message describing the failure
  final String errorMessage;

  const CameraDiscoveryFailed({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];

  @override
  String toString() => 'CameraDiscoveryFailed(errorMessage: $errorMessage)';
}

// ==================== Camera Initialization Events ====================

/// Initializes a specific camera with given settings.
class CameraInitializationRequested extends CameraEvent {
  /// Camera description to initialize
  final CameraDescription cameraDescription;
  
  /// Resolution preset for the camera
  final ResolutionPreset resolutionPreset;
  
  /// Whether to enable audio recording (usually false for face scanning)
  final bool enableAudio;
  
  /// Image format group for platform-specific optimization
  final ImageFormatGroup? imageFormatGroup;

  const CameraInitializationRequested({
    required this.cameraDescription,
    this.resolutionPreset = ResolutionPreset.medium,
    this.enableAudio = false,
    this.imageFormatGroup,
  });

  @override
  List<Object?> get props => [
    cameraDescription,
    resolutionPreset,
    enableAudio,
    imageFormatGroup,
  ];

  @override
  String toString() {
    return 'CameraInitializationRequested('
        'camera: ${cameraDescription.name}, '
        'resolution: $resolutionPreset, '
        'enableAudio: $enableAudio, '
        'imageFormatGroup: $imageFormatGroup'
        ')';
  }
}

/// Camera initialization completed successfully.
class CameraInitialized extends CameraEvent {
  /// Initialized camera controller
  final CameraController cameraController;
  
  /// Camera description that was initialized
  final CameraDescription cameraDescription;

  const CameraInitialized({
    required this.cameraController,
    required this.cameraDescription,
  });

  @override
  List<Object?> get props => [cameraController, cameraDescription];

  @override
  String toString() {
    return 'CameraInitialized('
        'camera: ${cameraDescription.name}, '
        'isInitialized: ${cameraController.value.isInitialized}'
        ')';
  }
}

/// Camera initialization failed due to an error.
class CameraInitializationFailed extends CameraEvent {
  /// Camera description that failed to initialize
  final CameraDescription cameraDescription;
  
  /// Error message describing the failure
  final String errorMessage;
  
  /// Whether this failure is recoverable
  final bool isRecoverable;

  const CameraInitializationFailed({
    required this.cameraDescription,
    required this.errorMessage,
    this.isRecoverable = true,
  });

  @override
  List<Object?> get props => [cameraDescription, errorMessage, isRecoverable];

  @override
  String toString() {
    return 'CameraInitializationFailed('
        'camera: ${cameraDescription.name}, '
        'errorMessage: $errorMessage, '
        'isRecoverable: $isRecoverable'
        ')';
  }
}

// ==================== Camera Stream Events ====================

/// Starts the camera image stream for real-time processing.
class CameraStreamStartRequested extends CameraEvent {
  const CameraStreamStartRequested();

  @override
  String toString() => 'CameraStreamStartRequested()';
}

/// Camera image stream started successfully.
class CameraStreamStarted extends CameraEvent {
  const CameraStreamStarted();

  @override
  String toString() => 'CameraStreamStarted()';
}

/// Failed to start camera image stream.
class CameraStreamStartFailed extends CameraEvent {
  /// Error message describing the failure
  final String errorMessage;

  const CameraStreamStartFailed({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];

  @override
  String toString() => 'CameraStreamStartFailed(errorMessage: $errorMessage)';
}

/// Stops the camera image stream.
class CameraStreamStopRequested extends CameraEvent {
  const CameraStreamStopRequested();

  @override
  String toString() => 'CameraStreamStopRequested()';
}

/// Camera image stream stopped successfully.
class CameraStreamStopped extends CameraEvent {
  const CameraStreamStopped();

  @override
  String toString() => 'CameraStreamStopped()';
}

// ==================== Camera Switching Events ====================

/// Switches to a different camera (front/back).
class CameraSwitchRequested extends CameraEvent {
  /// Target camera description to switch to
  final CameraDescription targetCamera;

  const CameraSwitchRequested({required this.targetCamera});

  @override
  List<Object?> get props => [targetCamera];

  @override
  String toString() => 'CameraSwitchRequested(targetCamera: ${targetCamera.name})';
}

/// Camera switch completed successfully.
class CameraSwitched extends CameraEvent {
  /// New camera controller after switching
  final CameraController newCameraController;
  
  /// Camera description that is now active
  final CameraDescription activeCameraDescription;

  const CameraSwitched({
    required this.newCameraController,
    required this.activeCameraDescription,
  });

  @override
  List<Object?> get props => [newCameraController, activeCameraDescription];

  @override
  String toString() {
    return 'CameraSwitched(activeCamera: ${activeCameraDescription.name})';
  }
}

/// Camera switch failed due to an error.
class CameraSwitchFailed extends CameraEvent {
  /// Target camera that failed to switch to
  final CameraDescription targetCamera;
  
  /// Error message describing the failure
  final String errorMessage;

  const CameraSwitchFailed({
    required this.targetCamera,
    required this.errorMessage,
  });

  @override
  List<Object?> get props => [targetCamera, errorMessage];

  @override
  String toString() {
    return 'CameraSwitchFailed('
        'targetCamera: ${targetCamera.name}, '
        'errorMessage: $errorMessage'
        ')';
  }
}

// ==================== Camera Settings Events ====================

/// Updates camera settings like exposure, focus, etc.
class CameraSettingsUpdateRequested extends CameraEvent {
  /// Optional exposure offset to set
  final double? exposureOffset;
  
  /// Optional zoom level to set
  final double? zoomLevel;
  
  /// Optional flash mode to set
  final FlashMode? flashMode;
  
  /// Optional focus mode to set
  final FocusMode? focusMode;

  const CameraSettingsUpdateRequested({
    this.exposureOffset,
    this.zoomLevel,
    this.flashMode,
    this.focusMode,
  });

  @override
  List<Object?> get props => [exposureOffset, zoomLevel, flashMode, focusMode];

  @override
  String toString() {
    return 'CameraSettingsUpdateRequested('
        'exposureOffset: $exposureOffset, '
        'zoomLevel: $zoomLevel, '
        'flashMode: $flashMode, '
        'focusMode: $focusMode'
        ')';
  }
}

/// Camera settings updated successfully.
class CameraSettingsUpdated extends CameraEvent {
  /// Current camera settings after update
  final Map<String, dynamic> currentSettings;

  const CameraSettingsUpdated({required this.currentSettings});

  @override
  List<Object?> get props => [currentSettings];

  @override
  String toString() => 'CameraSettingsUpdated(settings: $currentSettings)';
}

// ==================== Camera Disposal Events ====================

/// Disposes of the current camera controller and cleans up resources.
class CameraDisposalRequested extends CameraEvent {
  const CameraDisposalRequested();

  @override
  String toString() => 'CameraDisposalRequested()';
}

/// Camera controller disposed successfully.
class CameraDisposed extends CameraEvent {
  const CameraDisposed();

  @override
  String toString() => 'CameraDisposed()';
}

// ==================== Error Recovery Events ====================

/// Retries the last failed camera operation.
class CameraRetryRequested extends CameraEvent {
  const CameraRetryRequested();

  @override
  String toString() => 'CameraRetryRequested()';
}

/// Resets camera state to initial condition.
class CameraResetRequested extends CameraEvent {
  const CameraResetRequested();

  @override
  String toString() => 'CameraResetRequested()';
}