import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../domain/face_scan/entities/camera_scan_session.dart';
import '../../../domain/face_scan/repositories/face_scan_repository.dart';
import '../models/scan_image_model.dart';

/// Abstract interface for camera hardware integration.
/// 
/// This interface defines the contract for camera operations including
/// initialization, image capture, face detection, and hardware management.
/// Implementations should handle platform-specific camera APIs and permissions.
abstract class FaceScanCameraDataSource {
  // ===== Camera Management =====

  /// Gets available camera devices on the system.
  /// 
  /// Returns:
  /// - [List<CameraDeviceInfo>]: List of available camera devices with capabilities
  /// 
  /// Throws:
  /// - [Exception]: For camera enumeration errors
  Future<List<CameraDeviceInfo>> getAvailableCameras();

  /// Initializes a camera controller with specified configuration.
  /// 
  /// Parameters:
  /// - [cameraDescription]: Camera device to initialize
  /// - [resolutionPreset]: Desired resolution setting
  /// - [enableAudio]: Whether to enable audio recording
  /// 
  /// Returns:
  /// - [CameraController]: Initialized camera controller
  /// 
  /// Throws:
  /// - [Exception]: For camera initialization errors
  Future<CameraController> initializeCamera({
    required CameraDescription cameraDescription,
    ResolutionPreset resolutionPreset = ResolutionPreset.medium,
    bool enableAudio = false,
  });

  /// Disposes of camera resources properly.
  /// 
  /// Parameters:
  /// - [controller]: Camera controller to dispose
  /// 
  /// Throws:
  /// - [Exception]: For camera disposal errors
  Future<void> disposeCamera(CameraController controller);

  /// Starts the camera preview and image stream.
  /// 
  /// Parameters:
  /// - [controller]: Initialized camera controller
  /// - [onImageAvailable]: Callback for processing camera frames
  /// 
  /// Throws:
  /// - [Exception]: For camera stream errors
  Future<void> startCameraStream({
    required CameraController controller,
    required Function(CameraImage) onImageAvailable,
  });

  /// Stops the camera image stream.
  /// 
  /// Parameters:
  /// - [controller]: Camera controller with active stream
  /// 
  /// Throws:
  /// - [Exception]: For camera stream errors
  Future<void> stopCameraStream(CameraController controller);

  // ===== Image Capture =====

  /// Captures a still image from the camera.
  /// 
  /// Parameters:
  /// - [controller]: Active camera controller
  /// - [flashMode]: Flash setting for capture
  /// 
  /// Returns:
  /// - [ScanImageModel]: Captured image with metadata
  /// 
  /// Throws:
  /// - [Exception]: For image capture errors
  Future<ScanImageModel> captureImage({
    required CameraController controller,
    FlashMode flashMode = FlashMode.auto,
  });

  /// Captures image with quality validation.
  /// 
  /// Parameters:
  /// - [controller]: Active camera controller
  /// - [qualityRequirements]: Minimum quality standards
  /// - [flashMode]: Flash setting for capture
  /// 
  /// Returns:
  /// - [ScanImageModel]: Captured image with quality validation
  /// 
  /// Throws:
  /// - [Exception]: For capture or validation errors
  Future<ScanImageModel> captureValidatedImage({
    required CameraController controller,
    ImageQualityRequirements? qualityRequirements,
    FlashMode flashMode = FlashMode.auto,
  });

  /// Validates image quality for analysis suitability.
  /// 
  /// Parameters:
  /// - [imageBytes]: Image data to validate
  /// 
  /// Returns:
  /// - [ImageQualityModel]: Quality metrics and validation results
  /// 
  /// Throws:
  /// - [Exception]: For image processing errors
  Future<ImageQualityModel> validateImageQuality(Uint8List imageBytes);

  // ===== Face Detection =====

  /// Initializes face detection with specified options.
  /// 
  /// Parameters:
  /// - [options]: Face detection configuration
  /// 
  /// Returns:
  /// - [FaceDetector]: Configured face detector instance
  /// 
  /// Throws:
  /// - [Exception]: For face detector initialization errors
  Future<FaceDetector> initializeFaceDetector({
    FaceDetectorOptions? options,
  });

  /// Processes a camera frame for face detection.
  /// 
  /// Parameters:
  /// - [cameraImage]: Raw camera frame
  /// - [detector]: Face detector instance
  /// - [cameraDescription]: Camera configuration for coordinate transformation
  /// 
  /// Returns:
  /// - [List<Face>]: Detected faces with landmarks and poses
  /// 
  /// Throws:
  /// - [Exception]: For face detection processing errors
  Future<List<Face>> detectFacesInFrame({
    required CameraImage cameraImage,
    required FaceDetector detector,
    required CameraDescription cameraDescription,
  });

  /// Validates face alignment and position for scanning.
  /// 
  /// Parameters:
  /// - [faces]: Detected faces from the camera
  /// - [imageSize]: Size of the camera preview
  /// - [tolerances]: Alignment tolerance settings
  /// 
  /// Returns:
  /// - [Map<String, dynamic>]: Alignment validation results
  /// 
  /// Throws:
  /// - [Exception]: For alignment validation errors
  Future<Map<String, dynamic>> validateFaceAlignment({
    required List<Face> faces,
    required Size imageSize,
    FaceAlignmentTolerance? tolerances,
  });

  /// Disposes of face detection resources.
  /// 
  /// Parameters:
  /// - [detector]: Face detector to dispose
  /// 
  /// Throws:
  /// - [Exception]: For detector disposal errors
  Future<void> disposeFaceDetector(FaceDetector detector);

  // ===== Permissions =====

  /// Checks current camera permission status.
  /// 
  /// Returns:
  /// - [bool]: True if camera permission is granted
  /// 
  /// Throws:
  /// - [Exception]: For permission check errors
  Future<bool> checkCameraPermission();

  /// Requests camera permission from the user.
  /// 
  /// Returns:
  /// - [bool]: True if permission was granted
  /// 
  /// Throws:
  /// - [Exception]: For permission request errors
  Future<bool> requestCameraPermission();

  /// Gets detailed permission status information.
  /// 
  /// Returns:
  /// - [Map<String, dynamic>]: Detailed permission status
  /// 
  /// Throws:
  /// - [Exception]: For permission status errors
  Future<Map<String, dynamic>> getPermissionStatus();

  // ===== Utility Methods =====

  /// Converts camera image to InputImage for ML processing.
  /// 
  /// Parameters:
  /// - [cameraImage]: Raw camera frame
  /// - [cameraDescription]: Camera configuration
  /// 
  /// Returns:
  /// - [InputImage]: Formatted image for ML Kit processing
  /// 
  /// Throws:
  /// - [Exception]: For image conversion errors
  Future<InputImage?> convertCameraImageToInputImage({
    required CameraImage cameraImage,
    required CameraDescription cameraDescription,
  });

  /// Gets optimal camera settings for face scanning.
  /// 
  /// Parameters:
  /// - [availableCameras]: List of available cameras
  /// 
  /// Returns:
  /// - [Map<String, dynamic>]: Recommended camera settings
  /// 
  /// Throws:
  /// - [Exception]: For camera configuration errors
  Future<Map<String, dynamic>> getOptimalCameraSettings({
    required List<CameraDescription> availableCameras,
  });

  /// Estimates image file size for quality settings.
  /// 
  /// Parameters:
  /// - [resolution]: Camera resolution preset
  /// - [quality]: JPEG quality setting (0-100)
  /// 
  /// Returns:
  /// - [int]: Estimated file size in bytes
  Future<int> estimateImageSize({
    required ResolutionPreset resolution,
    int quality = 85,
  });
}