import 'package:equatable/equatable.dart';
import 'package:camera/camera.dart';

/// Base class for all camera states.
/// Represents the complete state of camera hardware management.
abstract class CameraState extends Equatable {
  const CameraState();
  
  @override
  List<Object?> get props => [];
}

// ==================== Initial State ====================

/// Initial camera state when the BLoC is first created.
class CameraInitial extends CameraState {
  const CameraInitial();

  @override
  String toString() => 'CameraInitial()';
}

// ==================== Permission States ====================

/// Camera permission is being requested.
class CameraPermissionRequesting extends CameraState {
  const CameraPermissionRequesting();

  @override
  String toString() => 'CameraPermissionRequesting()';
}

/// Camera permission has been granted.
class CameraPermissionGranted extends CameraState {
  const CameraPermissionGranted();

  @override
  String toString() => 'CameraPermissionGranted()';
}

/// Camera permission has been denied.
class CameraPermissionDenied extends CameraState {
  /// Whether the permission is permanently denied
  final bool isPermanent;
  
  /// Message explaining the permission denial
  final String message;

  const CameraPermissionDenied({
    required this.isPermanent,
    required this.message,
  });

  @override
  List<Object?> get props => [isPermanent, message];

  @override
  String toString() {
    return 'CameraPermissionDenied(isPermanent: $isPermanent, message: $message)';
  }
}

// ==================== Discovery States ====================

/// Cameras are being discovered on the device.
class CameraDiscovering extends CameraState {
  const CameraDiscovering();

  @override
  String toString() => 'CameraDiscovering()';
}

/// Cameras have been discovered successfully.
class CamerasDiscovered extends CameraState {
  /// List of available camera descriptions
  final List<CameraDescription> availableCameras;
  
  /// Preferred front camera (if available)
  final CameraDescription? frontCamera;
  
  /// Preferred back camera (if available)
  final CameraDescription? backCamera;

  const CamerasDiscovered({
    required this.availableCameras,
    this.frontCamera,
    this.backCamera,
  });

  @override
  List<Object?> get props => [availableCameras, frontCamera, backCamera];

  @override
  String toString() {
    return 'CamerasDiscovered('
        'total: ${availableCameras.length}, '
        'hasFront: ${frontCamera != null}, '
        'hasBack: ${backCamera != null}'
        ')';
  }
}

/// Camera discovery failed.
class CameraDiscoveryFailed extends CameraState {
  /// Error message describing the failure
  final String errorMessage;
  
  /// Whether discovery can be retried
  final bool canRetry;

  const CameraDiscoveryFailed({
    required this.errorMessage,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [errorMessage, canRetry];

  @override
  String toString() {
    return 'CameraDiscoveryFailed(errorMessage: $errorMessage, canRetry: $canRetry)';
  }
}

// ==================== Initialization States ====================

/// Camera is being initialized.
class CameraInitializing extends CameraState {
  /// Camera description being initialized
  final CameraDescription cameraDescription;
  
  /// Progress message for user feedback
  final String progressMessage;

  const CameraInitializing({
    required this.cameraDescription,
    this.progressMessage = 'Initializing camera...',
  });

  @override
  List<Object?> get props => [cameraDescription, progressMessage];

  @override
  String toString() {
    return 'CameraInitializing('
        'camera: ${cameraDescription.name}, '
        'message: $progressMessage'
        ')';
  }
}

/// Camera has been initialized and is ready to use.
class CameraReady extends CameraState {
  /// Active camera controller
  final CameraController cameraController;
  
  /// Camera description that is active
  final CameraDescription activeCameraDescription;
  
  /// List of all available cameras
  final List<CameraDescription> availableCameras;
  
  /// Current camera settings
  final CameraCapabilities capabilities;
  
  /// Whether the image stream is active
  final bool isStreamingImages;

  const CameraReady({
    required this.cameraController,
    required this.activeCameraDescription,
    required this.availableCameras,
    required this.capabilities,
    this.isStreamingImages = false,
  });

  @override
  List<Object?> get props => [
    cameraController,
    activeCameraDescription,
    availableCameras,
    capabilities,
    isStreamingImages,
  ];

  @override
  String toString() {
    return 'CameraReady('
        'activeCamera: ${activeCameraDescription.name}, '
        'isStreaming: $isStreamingImages, '
        'availableCameras: ${availableCameras.length}'
        ')';
  }
}

/// Camera initialization failed.
class CameraInitializationFailed extends CameraState {
  /// Camera that failed to initialize
  final CameraDescription failedCamera;
  
  /// Error message describing the failure
  final String errorMessage;
  
  /// Whether initialization can be retried
  final bool canRetry;
  
  /// List of available cameras for potential fallback
  final List<CameraDescription> availableCameras;

  const CameraInitializationFailed({
    required this.failedCamera,
    required this.errorMessage,
    this.canRetry = true,
    this.availableCameras = const [],
  });

  @override
  List<Object?> get props => [
    failedCamera,
    errorMessage,
    canRetry,
    availableCameras,
  ];

  @override
  String toString() {
    return 'CameraInitializationFailed('
        'failedCamera: ${failedCamera.name}, '
        'errorMessage: $errorMessage, '
        'canRetry: $canRetry'
        ')';
  }
}

// ==================== Stream States ====================

/// Camera image stream is starting.
class CameraStreamStarting extends CameraState {
  /// Camera controller starting the stream
  final CameraController cameraController;
  
  /// Camera description for the stream
  final CameraDescription cameraDescription;

  const CameraStreamStarting({
    required this.cameraController,
    required this.cameraDescription,
  });

  @override
  List<Object?> get props => [cameraController, cameraDescription];

  @override
  String toString() {
    return 'CameraStreamStarting(camera: ${cameraDescription.name})';
  }
}

/// Camera image stream is active and streaming.
class CameraStreamActive extends CameraState {
  /// Camera controller with active stream
  final CameraController cameraController;
  
  /// Camera description for the active stream
  final CameraDescription activeCameraDescription;
  
  /// List of all available cameras
  final List<CameraDescription> availableCameras;
  
  /// Camera capabilities and settings
  final CameraCapabilities capabilities;

  const CameraStreamActive({
    required this.cameraController,
    required this.activeCameraDescription,
    required this.availableCameras,
    required this.capabilities,
  });

  @override
  List<Object?> get props => [
    cameraController,
    activeCameraDescription,
    availableCameras,
    capabilities,
  ];

  @override
  String toString() {
    return 'CameraStreamActive(camera: ${activeCameraDescription.name})';
  }
}

/// Camera image stream failed to start.
class CameraStreamStartFailed extends CameraState {
  /// Camera controller that failed to start streaming
  final CameraController cameraController;
  
  /// Camera description where stream failed
  final CameraDescription cameraDescription;
  
  /// Error message describing the failure
  final String errorMessage;
  
  /// Whether stream start can be retried
  final bool canRetry;

  const CameraStreamStartFailed({
    required this.cameraController,
    required this.cameraDescription,
    required this.errorMessage,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [
    cameraController,
    cameraDescription,
    errorMessage,
    canRetry,
  ];

  @override
  String toString() {
    return 'CameraStreamStartFailed('
        'camera: ${cameraDescription.name}, '
        'errorMessage: $errorMessage'
        ')';
  }
}

// ==================== Camera Switching States ====================

/// Camera is being switched (front/back toggle).
class CameraSwitching extends CameraState {
  /// Current camera being switched from
  final CameraDescription fromCamera;
  
  /// Target camera being switched to
  final CameraDescription toCamera;
  
  /// Current controller (will be disposed)
  final CameraController currentController;

  const CameraSwitching({
    required this.fromCamera,
    required this.toCamera,
    required this.currentController,
  });

  @override
  List<Object?> get props => [fromCamera, toCamera, currentController];

  @override
  String toString() {
    return 'CameraSwitching(from: ${fromCamera.name}, to: ${toCamera.name})';
  }
}

/// Camera switch failed.
class CameraSwitchFailed extends CameraState {
  /// Camera that was being switched from
  final CameraDescription fromCamera;
  
  /// Camera that failed to switch to
  final CameraDescription failedToCamera;
  
  /// Error message describing the failure
  final String errorMessage;
  
  /// Original controller (may still be usable)
  final CameraController? originalController;
  
  /// List of available cameras
  final List<CameraDescription> availableCameras;

  const CameraSwitchFailed({
    required this.fromCamera,
    required this.failedToCamera,
    required this.errorMessage,
    this.originalController,
    this.availableCameras = const [],
  });

  @override
  List<Object?> get props => [
    fromCamera,
    failedToCamera,
    errorMessage,
    originalController,
    availableCameras,
  ];

  @override
  String toString() {
    return 'CameraSwitchFailed('
        'from: ${fromCamera.name}, '
        'failedTo: ${failedToCamera.name}, '
        'errorMessage: $errorMessage'
        ')';
  }
}

// ==================== Error States ====================

/// Generic camera error state for unexpected failures.
class CameraError extends CameraState {
  /// Error message describing what went wrong
  final String errorMessage;
  
  /// Error code for categorizing the error
  final String? errorCode;
  
  /// Whether the error is recoverable
  final bool isRecoverable;
  
  /// Additional context about the error
  final Map<String, dynamic> errorContext;

  const CameraError({
    required this.errorMessage,
    this.errorCode,
    this.isRecoverable = true,
    this.errorContext = const {},
  });

  @override
  List<Object?> get props => [
    errorMessage,
    errorCode,
    isRecoverable,
    errorContext,
  ];

  @override
  String toString() {
    return 'CameraError('
        'message: $errorMessage, '
        'code: $errorCode, '
        'recoverable: $isRecoverable'
        ')';
  }
}

// ==================== Disposed State ====================

/// Camera resources have been disposed and cleaned up.
class CameraDisposed extends CameraState {
  const CameraDisposed();

  @override
  String toString() => 'CameraDisposed()';
}

// ==================== Helper Classes ====================

/// Represents the capabilities and current settings of a camera.
class CameraCapabilities extends Equatable {
  /// Available resolution presets
  final List<ResolutionPreset> availableResolutions;
  
  /// Current resolution preset
  final ResolutionPreset currentResolution;
  
  /// Whether camera supports flash
  final bool hasFlash;
  
  /// Available flash modes
  final List<FlashMode> availableFlashModes;
  
  /// Current flash mode
  final FlashMode currentFlashMode;
  
  /// Whether camera supports auto focus
  final bool hasAutoFocus;
  
  /// Available focus modes
  final List<FocusMode> availableFocusModes;
  
  /// Current focus mode
  final FocusMode currentFocusMode;
  
  /// Whether camera supports exposure control
  final bool hasExposureControl;
  
  /// Minimum exposure offset
  final double minExposureOffset;
  
  /// Maximum exposure offset
  final double maxExposureOffset;
  
  /// Current exposure offset
  final double currentExposureOffset;
  
  /// Whether camera supports zoom
  final bool hasZoom;
  
  /// Maximum zoom level
  final double maxZoomLevel;
  
  /// Current zoom level
  final double currentZoomLevel;

  const CameraCapabilities({
    required this.availableResolutions,
    required this.currentResolution,
    required this.hasFlash,
    required this.availableFlashModes,
    required this.currentFlashMode,
    required this.hasAutoFocus,
    required this.availableFocusModes,
    required this.currentFocusMode,
    required this.hasExposureControl,
    required this.minExposureOffset,
    required this.maxExposureOffset,
    required this.currentExposureOffset,
    required this.hasZoom,
    required this.maxZoomLevel,
    required this.currentZoomLevel,
  });

  /// Creates basic capabilities for a simple camera setup
  factory CameraCapabilities.basic({
    ResolutionPreset resolution = ResolutionPreset.medium,
  }) {
    return CameraCapabilities(
      availableResolutions: [ResolutionPreset.low, ResolutionPreset.medium, ResolutionPreset.high],
      currentResolution: resolution,
      hasFlash: false,
      availableFlashModes: [FlashMode.off],
      currentFlashMode: FlashMode.off,
      hasAutoFocus: true,
      availableFocusModes: [FocusMode.auto],
      currentFocusMode: FocusMode.auto,
      hasExposureControl: false,
      minExposureOffset: 0.0,
      maxExposureOffset: 0.0,
      currentExposureOffset: 0.0,
      hasZoom: false,
      maxZoomLevel: 1.0,
      currentZoomLevel: 1.0,
    );
  }

  /// Creates a copy with updated settings
  CameraCapabilities copyWith({
    List<ResolutionPreset>? availableResolutions,
    ResolutionPreset? currentResolution,
    bool? hasFlash,
    List<FlashMode>? availableFlashModes,
    FlashMode? currentFlashMode,
    bool? hasAutoFocus,
    List<FocusMode>? availableFocusModes,
    FocusMode? currentFocusMode,
    bool? hasExposureControl,
    double? minExposureOffset,
    double? maxExposureOffset,
    double? currentExposureOffset,
    bool? hasZoom,
    double? maxZoomLevel,
    double? currentZoomLevel,
  }) {
    return CameraCapabilities(
      availableResolutions: availableResolutions ?? this.availableResolutions,
      currentResolution: currentResolution ?? this.currentResolution,
      hasFlash: hasFlash ?? this.hasFlash,
      availableFlashModes: availableFlashModes ?? this.availableFlashModes,
      currentFlashMode: currentFlashMode ?? this.currentFlashMode,
      hasAutoFocus: hasAutoFocus ?? this.hasAutoFocus,
      availableFocusModes: availableFocusModes ?? this.availableFocusModes,
      currentFocusMode: currentFocusMode ?? this.currentFocusMode,
      hasExposureControl: hasExposureControl ?? this.hasExposureControl,
      minExposureOffset: minExposureOffset ?? this.minExposureOffset,
      maxExposureOffset: maxExposureOffset ?? this.maxExposureOffset,
      currentExposureOffset: currentExposureOffset ?? this.currentExposureOffset,
      hasZoom: hasZoom ?? this.hasZoom,
      maxZoomLevel: maxZoomLevel ?? this.maxZoomLevel,
      currentZoomLevel: currentZoomLevel ?? this.currentZoomLevel,
    );
  }

  @override
  List<Object?> get props => [
    availableResolutions,
    currentResolution,
    hasFlash,
    availableFlashModes,
    currentFlashMode,
    hasAutoFocus,
    availableFocusModes,
    currentFocusMode,
    hasExposureControl,
    minExposureOffset,
    maxExposureOffset,
    currentExposureOffset,
    hasZoom,
    maxZoomLevel,
    currentZoomLevel,
  ];

  @override
  String toString() {
    return 'CameraCapabilities('
        'resolution: $currentResolution, '
        'hasFlash: $hasFlash, '
        'hasAutoFocus: $hasAutoFocus, '
        'hasExposureControl: $hasExposureControl, '
        'hasZoom: $hasZoom'
        ')';
  }
}

// ==================== State Extension Helpers ====================

extension CameraStateExtensions on CameraState {
  /// Whether the camera is ready for use
  bool get isReady => this is CameraReady || this is CameraStreamActive;

  /// Whether the camera is currently streaming images
  bool get isStreaming => this is CameraStreamActive;

  /// Whether the camera has encountered an error
  bool get hasError {
    return this is CameraPermissionDenied ||
           this is CameraDiscoveryFailed ||
           this is CameraInitializationFailed ||
           this is CameraStreamStartFailed ||
           this is CameraSwitchFailed ||
           this is CameraError;
  }

  /// Whether the current error state can be retried
  bool get canRetry {
    if (this is CameraDiscoveryFailed) {
      return (this as CameraDiscoveryFailed).canRetry;
    } else if (this is CameraInitializationFailed) {
      return (this as CameraInitializationFailed).canRetry;
    } else if (this is CameraStreamStartFailed) {
      return (this as CameraStreamStartFailed).canRetry;
    } else if (this is CameraError) {
      return (this as CameraError).isRecoverable;
    }
    return false;
  }

  /// Gets the camera controller if available
  CameraController? get cameraController {
    if (this is CameraReady) {
      return (this as CameraReady).cameraController;
    } else if (this is CameraStreamActive) {
      return (this as CameraStreamActive).cameraController;
    } else if (this is CameraStreamStarting) {
      return (this as CameraStreamStarting).cameraController;
    } else if (this is CameraStreamStartFailed) {
      return (this as CameraStreamStartFailed).cameraController;
    } else if (this is CameraSwitching) {
      return (this as CameraSwitching).currentController;
    } else if (this is CameraSwitchFailed) {
      return (this as CameraSwitchFailed).originalController;
    }
    return null;
  }

  /// Gets available cameras if known
  List<CameraDescription> get availableCameras {
    if (this is CamerasDiscovered) {
      return (this as CamerasDiscovered).availableCameras;
    } else if (this is CameraReady) {
      return (this as CameraReady).availableCameras;
    } else if (this is CameraStreamActive) {
      return (this as CameraStreamActive).availableCameras;
    } else if (this is CameraInitializationFailed) {
      return (this as CameraInitializationFailed).availableCameras;
    } else if (this is CameraSwitchFailed) {
      return (this as CameraSwitchFailed).availableCameras;
    }
    return [];
  }

  /// Gets the active camera description if available
  CameraDescription? get activeCameraDescription {
    if (this is CameraReady) {
      return (this as CameraReady).activeCameraDescription;
    } else if (this is CameraStreamActive) {
      return (this as CameraStreamActive).activeCameraDescription;
    } else if (this is CameraStreamStarting) {
      return (this as CameraStreamStarting).cameraDescription;
    } else if (this is CameraStreamStartFailed) {
      return (this as CameraStreamStartFailed).cameraDescription;
    } else if (this is CameraInitializing) {
      return (this as CameraInitializing).cameraDescription;
    }
    return null;
  }

  /// Gets user-friendly status message
  String get statusMessage {
    if (this is CameraInitial) {
      return 'Camera not initialized';
    } else if (this is CameraPermissionRequesting) {
      return 'Requesting camera permission...';
    } else if (this is CameraPermissionGranted) {
      return 'Camera permission granted';
    } else if (this is CameraPermissionDenied) {
      final denied = this as CameraPermissionDenied;
      return denied.message;
    } else if (this is CameraDiscovering) {
      return 'Discovering available cameras...';
    } else if (this is CamerasDiscovered) {
      final discovered = this as CamerasDiscovered;
      return '${discovered.availableCameras.length} cameras found';
    } else if (this is CameraInitializing) {
      final initializing = this as CameraInitializing;
      return initializing.progressMessage;
    } else if (this is CameraReady) {
      return 'Camera ready';
    } else if (this is CameraStreamActive) {
      return 'Camera streaming';
    } else if (this is CameraStreamStarting) {
      return 'Starting camera stream...';
    } else if (this is CameraSwitching) {
      final switching = this as CameraSwitching;
      return 'Switching to ${switching.toCamera.lensDirection.name} camera...';
    } else if (this is CameraDisposed) {
      return 'Camera disposed';
    } else if (hasError) {
      // Return specific error message for error states
      if (this is CameraDiscoveryFailed) {
        return (this as CameraDiscoveryFailed).errorMessage;
      } else if (this is CameraInitializationFailed) {
        return (this as CameraInitializationFailed).errorMessage;
      } else if (this is CameraStreamStartFailed) {
        return (this as CameraStreamStartFailed).errorMessage;
      } else if (this is CameraSwitchFailed) {
        return (this as CameraSwitchFailed).errorMessage;
      } else if (this is CameraError) {
        return (this as CameraError).errorMessage;
      }
    }
    return 'Unknown camera state';
  }
}