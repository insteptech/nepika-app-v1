import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import 'camera_event.dart' as event;
import 'camera_state.dart' as state;

/// Dedicated BLoC for camera hardware management and permissions.
/// 
/// This BLoC handles all camera-related operations including:
/// - Camera permission management
/// - Camera device discovery and selection
/// - Camera initialization and configuration
/// - Camera stream management
/// - Camera switching (front/back)
/// - Camera settings and capabilities
/// - Resource cleanup and disposal
/// 
/// Separates camera concerns from face scanning business logic
/// for better maintainability and testability.
class CameraBloc extends Bloc<event.CameraEvent, state.CameraState> {
  // Internal state tracking
  CameraController? _currentController;
  List<CameraDescription>? _availableCameras;
  StreamSubscription? _cameraErrorSubscription;

  CameraBloc() : super(const state.CameraInitial()) {
    // Register event handlers
    on<CameraPermissionRequested>(_onCameraPermissionRequested);
    on<CameraPermissionUpdated>(_onCameraPermissionUpdated);
    on<CameraDiscoveryRequested>(_onCameraDiscoveryRequested);
    on<CamerasDiscovered>(_onCamerasDiscovered);
    on<CameraDiscoveryFailed>(_onCameraDiscoveryFailed);
    on<CameraInitializationRequested>(_onCameraInitializationRequested);
    on<CameraInitialized>(_onCameraInitialized);
    on<CameraInitializationFailed>(_onCameraInitializationFailed);
    on<CameraStreamStartRequested>(_onCameraStreamStartRequested);
    on<CameraStreamStarted>(_onCameraStreamStarted);
    on<CameraStreamStartFailed>(_onCameraStreamStartFailed);
    on<CameraStreamStopRequested>(_onCameraStreamStopRequested);
    on<CameraStreamStopped>(_onCameraStreamStopped);
    on<CameraSwitchRequested>(_onCameraSwitchRequested);
    on<CameraSwitched>(_onCameraSwitched);
    on<CameraSwitchFailed>(_onCameraSwitchFailed);
    on<CameraSettingsUpdateRequested>(_onCameraSettingsUpdateRequested);
    on<CameraSettingsUpdated>(_onCameraSettingsUpdated);
    on<CameraDisposalRequested>(_onCameraDisposalRequested);
    on<CameraDisposed>(_onCameraDisposed);
    on<CameraRetryRequested>(_onCameraRetryRequested);
    on<CameraResetRequested>(_onCameraResetRequested);
  }

  // ==================== Permission Management ====================

  /// Handles camera permission request
  Future<void> _onCameraPermissionRequested(
    CameraPermissionRequested event,
    Emitter<CameraState> emit,
  ) async {
    emit(const CameraPermissionRequesting());

    try {
      final status = await Permission.camera.status;
      
      if (status.isGranted) {
        add(const CameraPermissionUpdated(
          isGranted: true,
          isPermanentlyDenied: false,
        ));
      } else if (status.isDenied) {
        final result = await Permission.camera.request();
        add(CameraPermissionUpdated(
          isGranted: result.isGranted,
          isPermanentlyDenied: result.isPermanentlyDenied,
        ));
      } else {
        add(CameraPermissionUpdated(
          isGranted: false,
          isPermanentlyDenied: status.isPermanentlyDenied,
        ));
      }
    } catch (e) {
      emit(CameraError(
        errorMessage: 'Failed to request camera permission: $e',
        errorCode: 'PERMISSION_REQUEST_FAILED',
        isRecoverable: true,
      ));
    }
  }

  /// Handles camera permission update result
  Future<void> _onCameraPermissionUpdated(
    CameraPermissionUpdated event,
    Emitter<CameraState> emit,
  ) async {
    if (event.isGranted) {
      emit(const CameraPermissionGranted());
      // Automatically start camera discovery after permission granted
      add(const CameraDiscoveryRequested());
    } else {
      emit(CameraPermissionDenied(
        isPermanent: event.isPermanentlyDenied,
        message: event.isPermanentlyDenied
            ? 'Camera permission permanently denied. Please enable it in Settings.'
            : 'Camera permission is required to use this feature.',
      ));
    }
  }

  // ==================== Camera Discovery ====================

  /// Handles camera discovery request
  Future<void> _onCameraDiscoveryRequested(
    CameraDiscoveryRequested event,
    Emitter<CameraState> emit,
  ) async {
    emit(const CameraDiscovering());

    try {
      final cameras = await _discoverCamerasWithRetry();
      _availableCameras = cameras;

      // Categorize cameras by lens direction
      CameraDescription? frontCamera;
      CameraDescription? backCamera;

      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front && frontCamera == null) {
          frontCamera = camera;
        } else if (camera.lensDirection == CameraLensDirection.back && backCamera == null) {
          backCamera = camera;
        }
      }

      add(CamerasDiscovered(
        cameras: cameras,
      ));

    } catch (e) {
      add(CameraDiscoveryFailed(
        errorMessage: _getReadableError(e.toString()),
      ));
    }
  }

  /// Handles successful camera discovery
  Future<void> _onCamerasDiscovered(
    CamerasDiscovered event,
    Emitter<CameraState> emit,
  ) async {
    if (event.cameras.isEmpty) {
      emit(const CameraDiscoveryFailed(
        errorMessage: 'No cameras found on this device',
        canRetry: false,
      ));
      return;
    }

    _availableCameras = event.cameras;

    // Categorize cameras
    CameraDescription? frontCamera;
    CameraDescription? backCamera;

    for (final camera in event.cameras) {
      if (camera.lensDirection == CameraLensDirection.front && frontCamera == null) {
        frontCamera = camera;
      } else if (camera.lensDirection == CameraLensDirection.back && backCamera == null) {
        backCamera = camera;
      }
    }

    emit(CamerasDiscovered(
      availableCameras: event.cameras,
      frontCamera: frontCamera,
      backCamera: backCamera,
    ));
  }

  /// Handles camera discovery failure
  Future<void> _onCameraDiscoveryFailed(
    CameraDiscoveryFailed event,
    Emitter<CameraState> emit,
  ) async {
    emit(CameraDiscoveryFailed(
      errorMessage: event.errorMessage,
      canRetry: true,
    ));
  }

  // ==================== Camera Initialization ====================

  /// Handles camera initialization request
  Future<void> _onCameraInitializationRequested(
    CameraInitializationRequested event,
    Emitter<CameraState> emit,
  ) async {
    emit(CameraInitializing(
      cameraDescription: event.cameraDescription,
      progressMessage: 'Initializing ${event.cameraDescription.name}...',
    ));

    try {
      // Dispose existing controller if any
      await _disposeCurrentController();

      // Create new controller
      final controller = CameraController(
        event.cameraDescription,
        event.resolutionPreset,
        enableAudio: event.enableAudio,
        imageFormatGroup: event.imageFormatGroup ?? _getDefaultImageFormatGroup(),
      );

      // Initialize with timeout
      await controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Camera initialization timed out'),
      );

      _currentController = controller;

      // Set up error subscription
      _setupCameraErrorSubscription(controller);

      add(CameraInitialized(
        cameraController: controller,
        cameraDescription: event.cameraDescription,
      ));

    } catch (e) {
      add(CameraInitializationFailed(
        cameraDescription: event.cameraDescription,
        errorMessage: _getReadableError(e.toString()),
        isRecoverable: !e.toString().contains('already in use'),
      ));
    }
  }

  /// Handles successful camera initialization
  Future<void> _onCameraInitialized(
    CameraInitialized event,
    Emitter<CameraState> emit,
  ) async {
    final capabilities = await _getCameraCapabilities(event.cameraController);
    
    emit(CameraReady(
      cameraController: event.cameraController,
      activeCameraDescription: event.cameraDescription,
      availableCameras: _availableCameras ?? [event.cameraDescription],
      capabilities: capabilities,
      isStreamingImages: false,
    ));
  }

  /// Handles camera initialization failure
  Future<void> _onCameraInitializationFailed(
    CameraInitializationFailed event,
    Emitter<CameraState> emit,
  ) async {
    emit(CameraInitializationFailed(
      failedCamera: event.cameraDescription,
      errorMessage: event.errorMessage,
      canRetry: event.isRecoverable,
      availableCameras: _availableCameras ?? [],
    ));
  }

  // ==================== Camera Stream Management ====================

  /// Handles camera stream start request
  Future<void> _onCameraStreamStartRequested(
    CameraStreamStartRequested event,
    Emitter<CameraState> emit,
  ) async {
    if (_currentController == null || !_currentController!.value.isInitialized) {
      emit(const CameraError(
        errorMessage: 'Camera not initialized. Cannot start stream.',
        errorCode: 'CAMERA_NOT_INITIALIZED',
        isRecoverable: true,
      ));
      return;
    }

    if (state is! CameraReady) {
      emit(const CameraError(
        errorMessage: 'Camera not ready. Cannot start stream.',
        errorCode: 'CAMERA_NOT_READY',
        isRecoverable: true,
      ));
      return;
    }

    final currentState = state as CameraReady;
    
    emit(CameraStreamStarting(
      cameraController: _currentController!,
      cameraDescription: currentState.activeCameraDescription,
    ));

    try {
      // Note: The actual image stream callback will be set up by the consumer
      // This just validates that streaming is possible
      if (_currentController!.value.isStreamingImages) {
        await _currentController!.stopImageStream();
      }

      add(const CameraStreamStarted());

    } catch (e) {
      add(CameraStreamStartFailed(
        errorMessage: _getReadableError(e.toString()),
      ));
    }
  }

  /// Handles successful camera stream start
  Future<void> _onCameraStreamStarted(
    CameraStreamStarted event,
    Emitter<CameraState> emit,
  ) async {
    if (state is CameraStreamStarting) {
      final currentState = state as CameraStreamStarting;
      
      emit(CameraStreamActive(
        cameraController: currentState.cameraController,
        activeCameraDescription: currentState.cameraDescription,
        availableCameras: _availableCameras ?? [],
        capabilities: await _getCameraCapabilities(currentState.cameraController),
      ));
    }
  }

  /// Handles camera stream start failure
  Future<void> _onCameraStreamStartFailed(
    CameraStreamStartFailed event,
    Emitter<CameraState> emit,
  ) async {
    if (state is CameraStreamStarting) {
      final currentState = state as CameraStreamStarting;
      
      emit(CameraStreamStartFailed(
        cameraController: currentState.cameraController,
        cameraDescription: currentState.cameraDescription,
        errorMessage: event.errorMessage,
        canRetry: true,
      ));
    }
  }

  /// Handles camera stream stop request
  Future<void> _onCameraStreamStopRequested(
    CameraStreamStopRequested event,
    Emitter<CameraState> emit,
  ) async {
    if (_currentController != null && _currentController!.value.isStreamingImages) {
      try {
        await _currentController!.stopImageStream();
        add(const CameraStreamStopped());
      } catch (e) {
        emit(CameraError(
          errorMessage: 'Failed to stop camera stream: ${_getReadableError(e.toString())}',
          errorCode: 'STREAM_STOP_FAILED',
          isRecoverable: true,
        ));
      }
    } else {
      add(const CameraStreamStopped());
    }
  }

  /// Handles camera stream stopped
  Future<void> _onCameraStreamStopped(
    CameraStreamStopped event,
    Emitter<CameraState> emit,
  ) async {
    if (state is CameraStreamActive) {
      final currentState = state as CameraStreamActive;
      
      emit(CameraReady(
        cameraController: currentState.cameraController,
        activeCameraDescription: currentState.activeCameraDescription,
        availableCameras: currentState.availableCameras,
        capabilities: currentState.capabilities,
        isStreamingImages: false,
      ));
    }
  }

  // ==================== Camera Switching ====================

  /// Handles camera switch request
  Future<void> _onCameraSwitchRequested(
    CameraSwitchRequested event,
    Emitter<CameraState> emit,
  ) async {
    if (_currentController == null) {
      emit(const CameraError(
        errorMessage: 'No active camera to switch from',
        errorCode: 'NO_ACTIVE_CAMERA',
        isRecoverable: true,
      ));
      return;
    }

    final currentCamera = state.activeCameraDescription;
    if (currentCamera == null) {
      emit(const CameraError(
        errorMessage: 'Cannot determine current camera',
        errorCode: 'CURRENT_CAMERA_UNKNOWN',
        isRecoverable: true,
      ));
      return;
    }

    emit(CameraSwitching(
      fromCamera: currentCamera,
      toCamera: event.targetCamera,
      currentController: _currentController!,
    ));

    try {
      // Store the old controller for potential fallback
      final oldController = _currentController;
      
      // Stop image stream if active
      if (oldController!.value.isStreamingImages) {
        await oldController.stopImageStream();
      }

      // Create new controller
      final newController = CameraController(
        event.targetCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: _getDefaultImageFormatGroup(),
      );

      await newController.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Camera switch initialization timed out'),
      );

      // Dispose old controller after successful initialization
      await oldController.dispose();
      _currentController = newController;

      // Set up error subscription for new controller
      _setupCameraErrorSubscription(newController);

      add(CameraSwitched(
        newCameraController: newController,
        activeCameraDescription: event.targetCamera,
      ));

    } catch (e) {
      add(CameraSwitchFailed(
        targetCamera: event.targetCamera,
        errorMessage: _getReadableError(e.toString()),
      ));
    }
  }

  /// Handles successful camera switch
  Future<void> _onCameraSwitched(
    CameraSwitched event,
    Emitter<CameraState> emit,
  ) async {
    final capabilities = await _getCameraCapabilities(event.newCameraController);
    
    emit(CameraReady(
      cameraController: event.newCameraController,
      activeCameraDescription: event.activeCameraDescription,
      availableCameras: _availableCameras ?? [],
      capabilities: capabilities,
      isStreamingImages: false,
    ));
  }

  /// Handles camera switch failure
  Future<void> _onCameraSwitchFailed(
    CameraSwitchFailed event,
    Emitter<CameraState> emit,
  ) async {
    if (state is CameraSwitching) {
      final currentState = state as CameraSwitching;
      
      emit(CameraSwitchFailed(
        fromCamera: currentState.fromCamera,
        failedToCamera: event.targetCamera,
        errorMessage: event.errorMessage,
        originalController: _currentController,
        availableCameras: _availableCameras ?? [],
      ));
    }
  }

  // ==================== Camera Settings ====================

  /// Handles camera settings update request
  Future<void> _onCameraSettingsUpdateRequested(
    CameraSettingsUpdateRequested event,
    Emitter<CameraState> emit,
  ) async {
    if (_currentController == null || !_currentController!.value.isInitialized) {
      emit(const CameraError(
        errorMessage: 'Camera not initialized. Cannot update settings.',
        errorCode: 'CAMERA_NOT_INITIALIZED',
        isRecoverable: true,
      ));
      return;
    }

    try {
      final settings = <String, dynamic>{};

      if (event.exposureOffset != null) {
        await _currentController!.setExposureOffset(event.exposureOffset!);
        settings['exposureOffset'] = event.exposureOffset;
      }

      if (event.zoomLevel != null) {
        await _currentController!.setZoomLevel(event.zoomLevel!);
        settings['zoomLevel'] = event.zoomLevel;
      }

      if (event.flashMode != null) {
        await _currentController!.setFlashMode(event.flashMode!);
        settings['flashMode'] = event.flashMode!.name;
      }

      if (event.focusMode != null) {
        await _currentController!.setFocusMode(event.focusMode!);
        settings['focusMode'] = event.focusMode!.name;
      }

      add(CameraSettingsUpdated(currentSettings: settings));

    } catch (e) {
      emit(CameraError(
        errorMessage: 'Failed to update camera settings: ${_getReadableError(e.toString())}',
        errorCode: 'SETTINGS_UPDATE_FAILED',
        isRecoverable: true,
      ));
    }
  }

  /// Handles camera settings updated
  Future<void> _onCameraSettingsUpdated(
    CameraSettingsUpdated event,
    Emitter<CameraState> emit,
  ) async {
    if (state.isReady && _currentController != null) {
      final capabilities = await _getCameraCapabilities(_currentController!);
      
      if (state is CameraReady) {
        final currentState = state as CameraReady;
        emit(currentState.copyWith(capabilities: capabilities));
      } else if (state is CameraStreamActive) {
        final currentState = state as CameraStreamActive;
        emit(CameraStreamActive(
          cameraController: currentState.cameraController,
          activeCameraDescription: currentState.activeCameraDescription,
          availableCameras: currentState.availableCameras,
          capabilities: capabilities,
        ));
      }
    }
  }

  // ==================== Camera Disposal ====================

  /// Handles camera disposal request
  Future<void> _onCameraDisposalRequested(
    CameraDisposalRequested event,
    Emitter<CameraState> emit,
  ) async {
    await _disposeCurrentController();
    add(const CameraDisposed());
  }

  /// Handles camera disposed
  Future<void> _onCameraDisposed(
    CameraDisposed event,
    Emitter<CameraState> emit,
  ) async {
    emit(const CameraDisposed());
  }

  // ==================== Error Recovery ====================

  /// Handles retry request
  Future<void> _onCameraRetryRequested(
    CameraRetryRequested event,
    Emitter<CameraState> emit,
  ) async {
    if (state is CameraDiscoveryFailed) {
      add(const CameraDiscoveryRequested());
    } else if (state is CameraInitializationFailed) {
      final failedState = state as CameraInitializationFailed;
      add(CameraInitializationRequested(
        cameraDescription: failedState.failedCamera,
      ));
    } else if (state is CameraStreamStartFailed) {
      add(const CameraStreamStartRequested());
    } else if (state is CameraSwitchFailed) {
      final failedState = state as CameraSwitchFailed;
      add(CameraSwitchRequested(targetCamera: failedState.failedToCamera));
    }
  }

  /// Handles camera reset request
  Future<void> _onCameraResetRequested(
    CameraResetRequested event,
    Emitter<CameraState> emit,
  ) async {
    await _disposeCurrentController();
    _availableCameras = null;
    emit(const CameraInitial());
  }

  // ==================== Helper Methods ====================

  /// Discovers cameras with retry mechanism
  Future<List<CameraDescription>> _discoverCamerasWithRetry({
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        final cameras = await availableCameras().timeout(
          const Duration(seconds: 5),
        );
        return cameras;
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * retryCount));
      }
    }
    
    throw Exception('Failed to discover cameras after $maxRetries attempts');
  }

  /// Gets default image format group based on platform
  ImageFormatGroup _getDefaultImageFormatGroup() {
    return Platform.isAndroid
        ? ImageFormatGroup.nv21
        : ImageFormatGroup.bgra8888;
  }

  /// Gets camera capabilities from controller
  Future<CameraCapabilities> _getCameraCapabilities(CameraController controller) async {
    try {
      return CameraCapabilities.basic(
        resolution: ResolutionPreset.medium,
      );
    } catch (e) {
      return CameraCapabilities.basic();
    }
  }

  /// Sets up error subscription for camera controller
  void _setupCameraErrorSubscription(CameraController controller) {
    _cameraErrorSubscription?.cancel();
    // Note: Camera plugin doesn't provide error stream directly
    // This would be implemented based on specific error handling needs
  }

  /// Disposes current controller safely
  Future<void> _disposeCurrentController() async {
    _cameraErrorSubscription?.cancel();
    _cameraErrorSubscription = null;

    if (_currentController != null) {
      try {
        if (_currentController!.value.isStreamingImages) {
          await _currentController!.stopImageStream();
        }
        await _currentController!.dispose().timeout(
          const Duration(seconds: 3),
          onTimeout: () => print('Camera disposal timed out'),
        );
      } catch (e) {
        print('Error disposing camera: $e');
      } finally {
        _currentController = null;
      }
    }
  }

  /// Converts technical errors to user-readable messages
  String _getReadableError(String error) {
    if (error.contains('timeout') || error.contains('timed out')) {
      return 'Camera is taking too long to respond. Please try again.';
    } else if (error.contains('permission') || error.contains('denied')) {
      return 'Camera permission is required. Please grant permission in Settings.';
    } else if (error.contains('No cameras available')) {
      return 'No cameras found on this device.';
    } else if (error.contains('already in use') || error.contains('in use')) {
      return 'Camera is being used by another app. Please close other camera apps.';
    } else if (error.contains('PlatformException')) {
      return 'Camera hardware error. Please restart the app.';
    }
    return 'Camera error occurred. Please try again.';
  }

  @override
  Future<void> close() async {
    await _disposeCurrentController();
    return super.close();
  }
}

/// Extension for CameraReady state to add copyWith functionality
extension CameraReadyExtension on CameraReady {
  CameraReady copyWith({
    CameraController? cameraController,
    CameraDescription? activeCameraDescription,
    List<CameraDescription>? availableCameras,
    CameraCapabilities? capabilities,
    bool? isStreamingImages,
  }) {
    return CameraReady(
      cameraController: cameraController ?? this.cameraController,
      activeCameraDescription: activeCameraDescription ?? this.activeCameraDescription,
      availableCameras: availableCameras ?? this.availableCameras,
      capabilities: capabilities ?? this.capabilities,
      isStreamingImages: isStreamingImages ?? this.isStreamingImages,
    );
  }
}