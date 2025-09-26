import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Service for handling face detection using Google ML Kit
class FaceDetectorService {
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  List<Face> _detectedFaces = [];
  
  // Getters
  bool get isDetecting => _isDetecting;
  List<Face> get detectedFaces => _detectedFaces;

  /// Initialize face detector
  void initialize() {
    try {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableContours: true,
          performanceMode: FaceDetectorMode.fast,
        ),
      );
      debugPrint('Face detector initialized successfully');
    } catch (e) {
      debugPrint('Face detector initialization error: $e');
      rethrow;
    }
  }

  /// Process camera frame for face detection
  Future<List<Face>> processFrame(CameraImage image, CameraDescription camera) async {
    if (_isDetecting) {
      return _detectedFaces;
    }

    _isDetecting = true;

    try {
      final input = _convertCameraImage(image, camera);
      if (input != null) {
        final faces = await _faceDetector.processImage(input);
        _detectedFaces = faces;
        return faces;
      }
      return [];
    } catch (e) {
      debugPrint('Face detection error: $e');
      return [];
    } finally {
      _isDetecting = false;
    }
  }

  /// Evaluate face alignment based on detected faces and camera preview size
  FaceAlignmentResult evaluateAlignment(
    List<Face> faces,
    Size? previewSize, {
    double maxHeadRotation = 15.0,
    double ovalWidthFactor = 0.5,
    double ovalHeightFactor = 0.65,
  }) {
    if (previewSize == null || faces.isEmpty) {
      return FaceAlignmentResult(
        isAligned: false,
        hasDetectedFace: faces.isNotEmpty,
        alignmentIssues: faces.isEmpty ? ['No face detected'] : ['Preview size not available'],
      );
    }

    final face = faces.first;
    final alignmentIssues = <String>[];

    // Check head rotation
    final rotY = face.headEulerAngleY ?? 0;
    final rotZ = face.headEulerAngleZ ?? 0;
    final lookingStraight = rotY.abs() < maxHeadRotation && rotZ.abs() < maxHeadRotation;

    if (!lookingStraight) {
      alignmentIssues.add('Please look straight at the camera');
    }

    // Check face position within oval
    final box = face.boundingBox;
    final centerX = box.center.dx;
    final centerY = box.center.dy;

    // Screen center
    final cx = previewSize.width / 2;
    final cy = previewSize.height / 2;

    final dx = (centerX - cx).abs();
    final dy = (centerY - cy).abs();

    // Oval boundaries
    final rx = previewSize.width * ovalWidthFactor;
    final ry = previewSize.height * ovalHeightFactor;

    final insideOval = (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) < 1;

    if (!insideOval) {
      alignmentIssues.add('Position your face inside the oval');
    }

    final isAligned = lookingStraight && insideOval;

    return FaceAlignmentResult(
      isAligned: isAligned,
      hasDetectedFace: true,
      alignmentIssues: alignmentIssues,
      faceBox: box,
      headRotationY: rotY,
      headRotationZ: rotZ,
    );
  }

  /// Convert camera image to InputImage for ML Kit
  InputImage? _convertCameraImage(CameraImage image, CameraDescription camera) {
    try {
      final rotation = _getImageRotation(camera);
      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final plane = image.planes.first;

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      );

      return InputImage.fromBytes(bytes: plane.bytes, metadata: metadata);
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }

  /// Get image rotation based on camera sensor orientation
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

  /// Dispose face detector
  void dispose() {
    try {
      _faceDetector.close();
      debugPrint('Face detector disposed');
    } catch (e) {
      debugPrint('Error disposing face detector: $e');
    }
  }
}

/// Result of face alignment evaluation
class FaceAlignmentResult {
  final bool isAligned;
  final bool hasDetectedFace;
  final List<String> alignmentIssues;
  final Rect? faceBox;
  final double? headRotationY;
  final double? headRotationZ;

  const FaceAlignmentResult({
    required this.isAligned,
    required this.hasDetectedFace,
    required this.alignmentIssues,
    this.faceBox,
    this.headRotationY,
    this.headRotationZ,
  });
}