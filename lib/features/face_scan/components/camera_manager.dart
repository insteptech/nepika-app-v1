import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

/// Manages camera initialization, lifecycle, and configuration for face scanning
class CameraManager {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isDisposed = false;
  String? _errorMessage;
  
  // Getters
  CameraController? get controller => _isDisposed ? null : _controller;
  List<CameraDescription>? get cameras => _cameras;
  bool get isInitialized => _isInitialized && !_isDisposed;
  bool get isInitializing => _isInitializing;
  bool get isDisposed => _isDisposed;
  String? get errorMessage => _errorMessage;

  /// Initialize camera with retry logic and proper error handling
  Future<bool> initializeCamera({
    CameraController? preInitializedController,
    List<CameraDescription>? availableCameras,
  }) async {
    if (_isInitializing) return false;
    
    _isInitializing = true;
    _isInitialized = false;
    _errorMessage = null;

    try {
      // Use pre-initialized camera if available
      if (preInitializedController != null && 
          preInitializedController.value.isInitialized) {
        debugPrint('Using pre-initialized camera controller');
        _controller = preInitializedController;
        _cameras = availableCameras;
        _isInitialized = true;
        _isInitializing = false;
        return true;
      }

      // Initialize camera ourselves
      debugPrint('Initializing camera from scratch');
      
      await _disposeController();

      final hasPermission = await _checkCameraPermission();
      if (!hasPermission) {
        throw Exception('Camera permission denied');
      }

      if (availableCameras != null) {
        _cameras = availableCameras;
      } else {
        _cameras = await _getCamerasWithRetry();
      }

      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available on this device');
      }

      final selectedCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      await _createController(selectedCamera);

      _isInitialized = true;
      _isInitializing = false;
      return true;

    } catch (e) {
      debugPrint('Camera initialization error: $e');
      _errorMessage = _getReadableError(e.toString());
      _isInitializing = false;
      _isInitialized = false;
      return false;
    }
  }

  /// Start image stream for face detection
  Future<void> startImageStream(Function(CameraImage) onImage) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('Cannot start image stream: controller not ready');
      return;
    }

    try {
      debugPrint('Starting image stream...');
      await _controller!.startImageStream(onImage);
      debugPrint('Image stream started successfully');
    } catch (e) {
      debugPrint('Error starting image stream: $e');
      _errorMessage = 'Failed to start camera stream: $e';
    }
  }

  /// Stop image stream
  Future<void> stopImageStream() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      try {
        await _controller!.stopImageStream();
        debugPrint('Image stream stopped');
      } catch (e) {
        debugPrint('Error stopping image stream: $e');
      }
    }
  }

  /// Capture photo
  Future<XFile?> capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('Cannot capture photo: controller not ready');
      return null;
    }

    try {
      // Stop image stream before capture
      await stopImageStream();
      final file = await _controller!.takePicture();
      debugPrint('Photo captured successfully');
      return file;
    } catch (e) {
      debugPrint('Capture error: $e');
      _errorMessage = 'Failed to capture photo: $e';
      return null;
    }
  }

  /// Dispose camera controller
  Future<void> dispose() async {
    debugPrint('Disposing camera manager...');
    _isDisposed = true;
    _isInitialized = false;
    await _disposeController();
  }

  /// Check camera permission
  Future<bool> _checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      if (status.isDenied) {
        final result = await Permission.camera.request();
        return result.isGranted;
      }
      return status.isGranted;
    } catch (e) {
      debugPrint('Permission check error: $e');
      return false;
    }
  }

  /// Get cameras with retry logic
  Future<List<CameraDescription>> _getCamerasWithRetry() async {
    int retryCount = 0;
    const maxRetries = 3;

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

    throw Exception('Failed to get cameras after $maxRetries attempts');
  }

  /// Create camera controller
  Future<void> _createController(CameraDescription camera) async {
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize().timeout(const Duration(seconds: 10));
  }

  /// Dispose controller safely
  Future<void> _disposeController() async {
    if (_controller != null) {
      try {
        if (_controller!.value.isInitialized) {
          if (_controller!.value.isStreamingImages) {
            await _controller!.stopImageStream();
          }
          await _controller!.dispose().timeout(
            const Duration(seconds: 3),
            onTimeout: () => debugPrint('Camera disposal timed out'),
          );
        }
      } catch (e) {
        debugPrint('Error disposing camera: $e');
      } finally {
        _controller = null;
      }
    }
  }

  /// Get readable error message
  String _getReadableError(String error) {
    if (error.contains('timeout') || error.contains('timed out')) {
      return 'Camera is taking too long to respond. Please try again.';
    } else if (error.contains('permission') || error.contains('denied')) {
      return 'Camera permission is required. Please grant permission in Settings.';
    } else if (error.contains('No cameras available')) {
      return 'No cameras found on this device.';
    } else if (error.contains('already in use') || error.contains('in use')) {
      return 'Camera is being used by another app. Please close other camera apps.';
    } else {
      return 'Failed to initialize camera. Please try again.';
    }
  }
}