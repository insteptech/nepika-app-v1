import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../domain/face_scan/entities/camera_scan_session.dart';
import '../../../domain/face_scan/repositories/face_scan_repository.dart';
import '../models/scan_image_model.dart';
import 'face_scan_camera_data_source.dart';

/// Implementation of camera data source for face scanning operations.
/// 
/// This implementation handles camera hardware integration, face detection,
/// and image quality validation using platform-specific camera APIs.
@injectable
class FaceScanCameraDataSourceImpl implements FaceScanCameraDataSource {
  FaceDetector? _faceDetector;

  // ===== Camera Management =====

  @override
  Future<List<CameraDeviceInfo>> getAvailableCameras() async {
    try {
      final cameras = await availableCameras();
      
      return cameras.map((camera) => CameraDeviceInfo(
        deviceId: camera.name,
        deviceName: camera.name,
        lensDirection: camera.lensDirection.name,
        supportedResolutions: _getSupportedResolutions(),
        hasFlash: true, // Most cameras have flash, would need platform-specific check
        hasAutoFocus: true, // Most cameras have auto-focus
        sensorOrientation: camera.sensorOrientation,
      )).toList();
    } catch (e) {
      throw Exception('Failed to get available cameras: $e');
    }
  }

  @override
  Future<CameraController> initializeCamera({
    required CameraDescription cameraDescription,
    ResolutionPreset resolutionPreset = ResolutionPreset.medium,
    bool enableAudio = false,
  }) async {
    try {
      final controller = CameraController(
        cameraDescription,
        resolutionPreset,
        enableAudio: enableAudio,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize().timeout(const Duration(seconds: 10));
      
      debugPrint('📷 Camera initialized successfully: ${cameraDescription.name}');
      return controller;
    } catch (e) {
      throw Exception('Failed to initialize camera: $e');
    }
  }

  @override
  Future<void> disposeCamera(CameraController controller) async {
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      
      await controller.dispose().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⚠️ Camera disposal timed out');
        },
      );
      
      debugPrint('📷 Camera disposed successfully');
    } catch (e) {
      throw Exception('Failed to dispose camera: $e');
    }
  }

  @override
  Future<void> startCameraStream({
    required CameraController controller,
    required Function(CameraImage) onImageAvailable,
  }) async {
    try {
      if (!controller.value.isInitialized) {
        throw Exception('Camera controller is not initialized');
      }

      await controller.startImageStream(onImageAvailable);
      debugPrint('📹 Camera stream started successfully');
    } catch (e) {
      throw Exception('Failed to start camera stream: $e');
    }
  }

  @override
  Future<void> stopCameraStream(CameraController controller) async {
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
        debugPrint('📹 Camera stream stopped successfully');
      }
    } catch (e) {
      throw Exception('Failed to stop camera stream: $e');
    }
  }

  // ===== Image Capture =====

  @override
  Future<ScanImageModel> captureImage({
    required CameraController controller,
    FlashMode flashMode = FlashMode.auto,
  }) async {
    try {
      if (!controller.value.isInitialized) {
        throw Exception('Camera controller is not initialized');
      }

      // Stop image stream if running
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }

      // Set flash mode if needed
      if (flashMode != FlashMode.auto) {
        await controller.setFlashMode(flashMode);
      }

      // Capture image
      final XFile imageFile = await controller.takePicture();
      final imageBytes = await imageFile.readAsBytes();

      // Create metadata
      final metadata = await _createCaptureMetadata(controller, imageBytes);

      debugPrint('📸 Image captured successfully: ${imageBytes.length} bytes');

      return ScanImageModel.fromBytes(
        imageBytes: imageBytes,
        imagePath: imageFile.path,
        metadata: metadata,
        format: 'jpg',
      );
    } catch (e) {
      throw Exception('Failed to capture image: $e');
    }
  }

  @override
  Future<ScanImageModel> captureValidatedImage({
    required CameraController controller,
    ImageQualityRequirements? qualityRequirements,
    FlashMode flashMode = FlashMode.auto,
  }) async {
    try {
      // Capture the image first
      final scanImage = await captureImage(
        controller: controller,
        flashMode: flashMode,
      );

      // Validate image quality
      if (scanImage.originalImageBytes != null) {
        final qualityModel = await validateImageQuality(scanImage.originalImageBytes!);
        
        final requirements = qualityRequirements ?? ImageQualityRequirements.standard();
        
        // Check if image meets quality requirements
        if (!qualityModel.isInFocus && requirements.minSharpness > 0) {
          throw Exception('Image is not in focus. Please try again.');
        }
        
        if (!qualityModel.hasGoodLighting && requirements.minBrightness > 0) {
          throw Exception('Poor lighting conditions. Please ensure good lighting.');
        }
        
        if (qualityModel.qualityScore < requirements.minQualityScore) {
          throw Exception('Image quality is too low. Please try again.');
        }
      }

      return scanImage;
    } catch (e) {
      throw Exception('Failed to capture validated image: $e');
    }
  }

  @override
  Future<ImageQualityModel> validateImageQuality(Uint8List imageBytes) async {
    try {
      // Basic image quality assessment
      // In a real implementation, you would use image processing libraries
      // to analyze brightness, sharpness, etc.
      
      final imageSize = imageBytes.length;
      
      // Simple quality scoring based on file size and basic checks
      int qualityScore = 70; // Base score
      int brightness = 75;   // Estimated brightness
      int sharpness = 80;    // Estimated sharpness
      int clarity = 85;      // Estimated clarity
      
      // Adjust scores based on image size (larger usually means better quality)
      if (imageSize < 100 * 1024) { // Less than 100KB
        qualityScore -= 20;
        sharpness -= 30;
        clarity -= 25;
      } else if (imageSize > 500 * 1024) { // More than 500KB
        qualityScore += 10;
        sharpness += 10;
        clarity += 10;
      }
      
      // Clamp values
      qualityScore = qualityScore.clamp(0, 100);
      brightness = brightness.clamp(0, 100);
      sharpness = sharpness.clamp(0, 100);
      clarity = clarity.clamp(0, 100);
      
      return ImageQualityModel(
        qualityScore: qualityScore,
        brightness: brightness,
        sharpness: sharpness,
        clarity: clarity,
        hasGoodLighting: brightness > 60,
        isInFocus: sharpness > 70,
      );
    } catch (e) {
      // Return poor quality if validation fails
      return ImageQualityModel.poor();
    }
  }

  // ===== Face Detection =====

  @override
  Future<FaceDetector> initializeFaceDetector({
    FaceDetectorOptions? options,
  }) async {
    try {
      final faceOptions = options ?? FaceDetectorOptions(
        enableLandmarks: true,
        enableContours: true,
        performanceMode: FaceDetectorMode.fast,
      );
      
      _faceDetector = FaceDetector(options: faceOptions);
      
      debugPrint('👤 Face detector initialized successfully');
      return _faceDetector!;
    } catch (e) {
      throw Exception('Failed to initialize face detector: $e');
    }
  }

  @override
  Future<List<Face>> detectFacesInFrame({
    required CameraImage cameraImage,
    required FaceDetector detector,
    required CameraDescription cameraDescription,
  }) async {
    try {
      final inputImage = await convertCameraImageToInputImage(
        cameraImage: cameraImage,
        cameraDescription: cameraDescription,
      );
      
      if (inputImage == null) {
        return [];
      }
      
      final faces = await detector.processImage(inputImage);
      return faces;
    } catch (e) {
      debugPrint('❌ Face detection error: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> validateFaceAlignment({
    required List<Face> faces,
    required Size imageSize,
    FaceAlignmentTolerance? tolerances,
  }) async {
    try {
      final tolerance = tolerances ?? FaceAlignmentTolerance.standard();
      
      if (faces.isEmpty) {
        return {
          'isAligned': false,
          'reason': 'No face detected',
          'faceCount': 0,
        };
      }
      
      if (faces.length > 1) {
        return {
          'isAligned': false,
          'reason': 'Multiple faces detected',
          'faceCount': faces.length,
        };
      }
      
      final face = faces.first;
      
      // Check head angles
      final rotY = face.headEulerAngleY ?? 0.0;
      final rotZ = face.headEulerAngleZ ?? 0.0;
      
      final faceAngles = FaceAngles(
        yaw: rotY,
        pitch: face.headEulerAngleX ?? 0.0,
        roll: rotZ,
      );
      
      if (!faceAngles.isWithinTolerance(tolerance)) {
        return {
          'isAligned': false,
          'reason': 'Face not looking straight',
          'angles': {
            'yaw': rotY,
            'pitch': face.headEulerAngleX ?? 0.0,
            'roll': rotZ,
          },
        };
      }
      
      // Check face position
      final boundingBox = face.boundingBox;
      final centerX = boundingBox.center.dx;
      final centerY = boundingBox.center.dy;
      
      final imageCenterX = imageSize.width / 2;
      final imageCenterY = imageSize.height / 2;
      
      final normalizedX = (centerX - imageCenterX) / imageCenterX;
      final normalizedY = (centerY - imageCenterY) / imageCenterY;
      
      final distanceFromCenter = sqrt(normalizedX * normalizedX + normalizedY * normalizedY);
      
      final facePosition = FacePosition(
        normalizedX: normalizedX,
        normalizedY: normalizedY,
        scaleFactor: _calculateScaleFactor(boundingBox, imageSize),
        distanceFromCenter: distanceFromCenter,
      );
      
      if (!facePosition.isWithinTolerance(tolerance)) {
        return {
          'isAligned': false,
          'reason': 'Face not properly positioned',
          'position': {
            'normalizedX': normalizedX,
            'normalizedY': normalizedY,
            'distanceFromCenter': distanceFromCenter,
          },
        };
      }
      
      return {
        'isAligned': true,
        'reason': 'Face properly aligned',
        'faceCount': 1,
        'angles': {
          'yaw': rotY,
          'pitch': face.headEulerAngleX ?? 0.0,
          'roll': rotZ,
        },
        'position': {
          'normalizedX': normalizedX,
          'normalizedY': normalizedY,
          'distanceFromCenter': distanceFromCenter,
        },
      };
    } catch (e) {
      return {
        'isAligned': false,
        'reason': 'Alignment validation error: $e',
      };
    }
  }

  @override
  Future<void> disposeFaceDetector(FaceDetector detector) async {
    try {
      await detector.close();
      _faceDetector = null;
      debugPrint('👤 Face detector disposed successfully');
    } catch (e) {
      throw Exception('Failed to dispose face detector: $e');
    }
  }

  // ===== Permissions =====

  @override
  Future<bool> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getPermissionStatus() async {
    try {
      final cameraStatus = await Permission.camera.status;
      
      return {
        'camera': {
          'status': cameraStatus.name,
          'isGranted': cameraStatus.isGranted,
          'isDenied': cameraStatus.isDenied,
          'isPermanentlyDenied': cameraStatus.isPermanentlyDenied,
          'isRestricted': cameraStatus.isRestricted,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // ===== Utility Methods =====

  @override
  Future<InputImage?> convertCameraImageToInputImage({
    required CameraImage cameraImage,
    required CameraDescription cameraDescription,
  }) async {
    try {
      final rotation = _getImageRotation(cameraDescription);
      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(cameraImage.format.raw);
      if (format == null) return null;

      final plane = cameraImage.planes.first;

      final metadata = InputImageMetadata(
        size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      );

      return InputImage.fromBytes(bytes: plane.bytes, metadata: metadata);
    } catch (e) {
      debugPrint('❌ Error converting camera image: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> getOptimalCameraSettings({
    required List<CameraDescription> availableCameras,
  }) async {
    try {
      // Prefer front camera for face scanning
      final frontCamera = availableCameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => availableCameras.first,
      );

      return {
        'recommendedCamera': {
          'name': frontCamera.name,
          'lensDirection': frontCamera.lensDirection.name,
          'sensorOrientation': frontCamera.sensorOrientation,
        },
        'recommendedResolution': 'medium',
        'recommendedSettings': {
          'enableAudio': false,
          'flashMode': 'auto',
          'focusMode': 'auto',
        },
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  @override
  Future<int> estimateImageSize({
    required ResolutionPreset resolution,
    int quality = 85,
  }) async {
    // Rough estimates based on resolution preset
    switch (resolution) {
      case ResolutionPreset.low:
        return (200 * 1024 * quality / 100).round(); // ~200KB base
      case ResolutionPreset.medium:
        return (500 * 1024 * quality / 100).round(); // ~500KB base
      case ResolutionPreset.high:
        return (1200 * 1024 * quality / 100).round(); // ~1.2MB base
      case ResolutionPreset.veryHigh:
        return (2000 * 1024 * quality / 100).round(); // ~2MB base
      case ResolutionPreset.ultraHigh:
        return (3000 * 1024 * quality / 100).round(); // ~3MB base
      case ResolutionPreset.max:
        return (4000 * 1024 * quality / 100).round(); // ~4MB base
    }
  }

  // ===== Private Helper Methods =====

  InputImageRotation? _getImageRotation(CameraDescription camera) {
    final sensorOrientation = camera.sensorOrientation;

    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  double _calculateScaleFactor(Rect boundingBox, Size imageSize) {
    // Calculate how much of the image the face occupies
    final faceArea = boundingBox.width * boundingBox.height;
    final imageArea = imageSize.width * imageSize.height;
    
    // Ideal face should occupy about 25% of the image
    const idealFaceRatio = 0.25;
    final actualFaceRatio = faceArea / imageArea;
    
    return actualFaceRatio / idealFaceRatio;
  }

  Future<ImageCaptureMetadataModel> _createCaptureMetadata(
    CameraController controller,
    Uint8List imageBytes,
  ) async {
    final previewSize = controller.value.previewSize;
    
    return ImageCaptureMetadataModel(
      captureTimestamp: DateTime.now(),
      dimensions: ImageDimensionsModel(
        width: previewSize?.width.toInt() ?? 0,
        height: previewSize?.height.toInt() ?? 0,
      ),
      cameraSettings: CameraSettingsModel(
        lensDirection: controller.description.lensDirection.name,
        resolutionPreset: controller.resolutionPreset.name,
        flashUsed: controller.value.flashMode == FlashMode.always ||
                   controller.value.flashMode == FlashMode.torch,
      ),
      quality: await validateImageQuality(imageBytes),
      isValidForAnalysis: imageBytes.length > 50 * 1024, // Basic check
    );
  }

  List<String> _getSupportedResolutions() {
    // Return common supported resolutions
    // In a real implementation, this would query the camera capabilities
    return [
      'low',
      'medium',
      'high',
      'veryHigh',
    ];
  }
}