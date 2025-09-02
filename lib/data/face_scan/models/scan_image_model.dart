import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../domain/face_scan/entities/scan_image.dart';

/// Data model for scan images that handles file paths, bytes, and base64 conversion.
/// Manages both original captured images and AI-processed annotated images.
class ScanImageModel {
  /// File path to the original captured image
  final String? originalImagePath;
  
  /// Original image bytes (for immediate processing)
  final Uint8List? originalImageBytes;
  
  /// AI-processed annotated image as base64 string
  final String? annotatedImageBase64;
  
  /// Annotated image bytes (decoded from base64)
  final Uint8List? annotatedImageBytes;
  
  /// Image format (jpg, png, etc.)
  final String imageFormat;
  
  /// Metadata about the capture
  final ImageCaptureMetadataModel captureMetadata;
  
  /// Whether annotated image is available
  final bool hasAnnotatedImage;

  const ScanImageModel({
    this.originalImagePath,
    this.originalImageBytes,
    this.annotatedImageBase64,
    this.annotatedImageBytes,
    required this.imageFormat,
    required this.captureMetadata,
    required this.hasAnnotatedImage,
  });

  /// Creates from captured image file and metadata
  factory ScanImageModel.fromCapture({
    required String imagePath,
    required ImageCaptureMetadataModel metadata,
    String format = 'jpg',
  }) {
    return ScanImageModel(
      originalImagePath: imagePath,
      imageFormat: format,
      captureMetadata: metadata,
      hasAnnotatedImage: false,
    );
  }

  /// Creates from image bytes and metadata
  factory ScanImageModel.fromBytes({
    required Uint8List imageBytes,
    required ImageCaptureMetadataModel metadata,
    String? imagePath,
    String format = 'jpg',
  }) {
    return ScanImageModel(
      originalImagePath: imagePath,
      originalImageBytes: imageBytes,
      imageFormat: format,
      captureMetadata: metadata,
      hasAnnotatedImage: false,
    );
  }

  /// Creates empty model for failed captures
  factory ScanImageModel.empty() {
    return ScanImageModel(
      imageFormat: 'jpg',
      captureMetadata: ImageCaptureMetadataModel.empty(),
      hasAnnotatedImage: false,
    );
  }

  /// Creates from JSON for storage/retrieval
  factory ScanImageModel.fromJson(Map<String, dynamic> json) {
    return ScanImageModel(
      originalImagePath: json['original_image_path'] as String?,
      originalImageBytes: json['original_image_bytes'] != null
          ? base64Decode(json['original_image_bytes'] as String)
          : null,
      annotatedImageBase64: json['annotated_image_base64'] as String?,
      annotatedImageBytes: json['annotated_image_base64'] != null
          ? _decodeBase64Image(json['annotated_image_base64'] as String)
          : null,
      imageFormat: json['image_format'] as String? ?? 'jpg',
      captureMetadata: ImageCaptureMetadataModel.fromJson(
        json['capture_metadata'] as Map<String, dynamic>? ?? {},
      ),
      hasAnnotatedImage: json['has_annotated_image'] as bool? ?? false,
    );
  }

  /// Converts to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'original_image_path': originalImagePath,
      'original_image_bytes': originalImageBytes != null
          ? base64Encode(originalImageBytes!)
          : null,
      'annotated_image_base64': annotatedImageBase64,
      'image_format': imageFormat,
      'capture_metadata': captureMetadata.toJson(),
      'has_annotated_image': hasAnnotatedImage,
    };
  }

  /// Converts to domain entity
  ScanImage toEntity() {
    return ScanImage(
      originalImagePath: originalImagePath,
      originalImageBytes: originalImageBytes,
      annotatedImageBytes: annotatedImageBytes,
      captureMetadata: captureMetadata.toEntity(),
      hasAnnotatedImage: hasAnnotatedImage,
      imageFormat: imageFormat,
    );
  }

  /// Adds annotated image from base64 string
  ScanImageModel withAnnotatedImage(String base64Image) {
    final decodedBytes = _decodeBase64Image(base64Image);
    
    return copyWith(
      annotatedImageBase64: base64Image,
      annotatedImageBytes: decodedBytes,
      hasAnnotatedImage: decodedBytes != null,
    );
  }

  /// Loads original image bytes from file if not already loaded
  Future<ScanImageModel> withOriginalImageBytes() async {
    if (originalImageBytes != null || originalImagePath == null) {
      return this;
    }

    try {
      final file = File(originalImagePath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return copyWith(originalImageBytes: bytes);
      }
    } catch (e) {
      // File not found or read error, return unchanged
    }
    
    return this;
  }

  /// Helper method to decode base64 image safely
  static Uint8List? _decodeBase64Image(String base64String) {
    try {
      // Remove data URL prefix if present
      String cleanBase64 = base64String;
      if (base64String.startsWith('data:image')) {
        final commaIndex = base64String.indexOf(',');
        if (commaIndex != -1) {
          cleanBase64 = base64String.substring(commaIndex + 1);
        }
      }
      
      return base64Decode(cleanBase64);
    } catch (e) {
      return null;
    }
  }

  /// Gets the appropriate image to display (prioritizes annotated)
  Uint8List? get displayImageBytes => annotatedImageBytes ?? originalImageBytes;

  /// Gets the size of original image in bytes
  int get originalImageSize => originalImageBytes?.length ?? 0;

  /// Gets the size of annotated image in bytes
  int get annotatedImageSize => annotatedImageBytes?.length ?? 0;

  /// Checks if both images are available
  bool get isComplete => originalImageBytes != null && annotatedImageBytes != null;

  /// Creates a copy with updated fields
  ScanImageModel copyWith({
    String? originalImagePath,
    Uint8List? originalImageBytes,
    String? annotatedImageBase64,
    Uint8List? annotatedImageBytes,
    String? imageFormat,
    ImageCaptureMetadataModel? captureMetadata,
    bool? hasAnnotatedImage,
  }) {
    return ScanImageModel(
      originalImagePath: originalImagePath ?? this.originalImagePath,
      originalImageBytes: originalImageBytes ?? this.originalImageBytes,
      annotatedImageBase64: annotatedImageBase64 ?? this.annotatedImageBase64,
      annotatedImageBytes: annotatedImageBytes ?? this.annotatedImageBytes,
      imageFormat: imageFormat ?? this.imageFormat,
      captureMetadata: captureMetadata ?? this.captureMetadata,
      hasAnnotatedImage: hasAnnotatedImage ?? this.hasAnnotatedImage,
    );
  }

  @override
  String toString() {
    return 'ScanImageModel('
        'originalImagePath: $originalImagePath, '
        'hasOriginalBytes: ${originalImageBytes != null}, '
        'hasAnnotatedImage: $hasAnnotatedImage, '
        'imageFormat: $imageFormat'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScanImageModel &&
        other.originalImagePath == originalImagePath &&
        other.originalImageBytes == originalImageBytes &&
        other.annotatedImageBase64 == annotatedImageBase64 &&
        other.imageFormat == imageFormat &&
        other.captureMetadata == captureMetadata &&
        other.hasAnnotatedImage == hasAnnotatedImage;
  }

  @override
  int get hashCode {
    return originalImagePath.hashCode ^
        originalImageBytes.hashCode ^
        annotatedImageBase64.hashCode ^
        imageFormat.hashCode ^
        captureMetadata.hashCode ^
        hasAnnotatedImage.hashCode;
  }
}

/// Data model for image capture metadata
class ImageCaptureMetadataModel {
  /// When the image was captured
  final DateTime captureTimestamp;
  
  /// Image dimensions
  final ImageDimensionsModel dimensions;
  
  /// Camera settings used
  final CameraSettingsModel cameraSettings;
  
  /// Image quality metrics
  final ImageQualityModel quality;
  
  /// Whether valid for analysis
  final bool isValidForAnalysis;

  const ImageCaptureMetadataModel({
    required this.captureTimestamp,
    required this.dimensions,
    required this.cameraSettings,
    required this.quality,
    required this.isValidForAnalysis,
  });

  /// Creates empty metadata
  factory ImageCaptureMetadataModel.empty() {
    return ImageCaptureMetadataModel(
      captureTimestamp: DateTime.now(),
      dimensions: const ImageDimensionsModel(width: 0, height: 0),
      cameraSettings: CameraSettingsModel.unknown(),
      quality: ImageQualityModel.poor(),
      isValidForAnalysis: false,
    );
  }

  /// Creates from JSON
  factory ImageCaptureMetadataModel.fromJson(Map<String, dynamic> json) {
    return ImageCaptureMetadataModel(
      captureTimestamp: json['capture_timestamp'] != null
          ? DateTime.parse(json['capture_timestamp'] as String)
          : DateTime.now(),
      dimensions: ImageDimensionsModel.fromJson(
        json['dimensions'] as Map<String, dynamic>? ?? {'width': 0, 'height': 0},
      ),
      cameraSettings: CameraSettingsModel.fromJson(
        json['camera_settings'] as Map<String, dynamic>? ?? {},
      ),
      quality: ImageQualityModel.fromJson(
        json['quality'] as Map<String, dynamic>? ?? {},
      ),
      isValidForAnalysis: json['is_valid_for_analysis'] as bool? ?? false,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'capture_timestamp': captureTimestamp.toIso8601String(),
      'dimensions': dimensions.toJson(),
      'camera_settings': cameraSettings.toJson(),
      'quality': quality.toJson(),
      'is_valid_for_analysis': isValidForAnalysis,
    };
  }

  /// Converts to domain entity
  ImageCaptureMetadata toEntity() {
    return ImageCaptureMetadata(
      captureTimestamp: captureTimestamp,
      dimensions: dimensions.toEntity(),
      cameraSettings: cameraSettings.toEntity(),
      quality: quality.toEntity(),
      isValidForAnalysis: isValidForAnalysis,
    );
  }
}

/// Data model for image dimensions
class ImageDimensionsModel {
  final int width;
  final int height;

  const ImageDimensionsModel({
    required this.width,
    required this.height,
  });

  factory ImageDimensionsModel.fromJson(Map<String, dynamic> json) {
    return ImageDimensionsModel(
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'width': width, 'height': height};
  }

  ImageDimensions toEntity() {
    return ImageDimensions(width: width, height: height);
  }
}

/// Data model for camera settings
class CameraSettingsModel {
  final String lensDirection;
  final String resolutionPreset;
  final bool flashUsed;
  final double? exposureValue;
  final String? focusMode;

  const CameraSettingsModel({
    required this.lensDirection,
    required this.resolutionPreset,
    required this.flashUsed,
    this.exposureValue,
    this.focusMode,
  });

  factory CameraSettingsModel.unknown() {
    return const CameraSettingsModel(
      lensDirection: 'unknown',
      resolutionPreset: 'unknown',
      flashUsed: false,
    );
  }

  factory CameraSettingsModel.fromJson(Map<String, dynamic> json) {
    return CameraSettingsModel(
      lensDirection: json['lens_direction'] as String? ?? 'unknown',
      resolutionPreset: json['resolution_preset'] as String? ?? 'unknown',
      flashUsed: json['flash_used'] as bool? ?? false,
      exposureValue: json['exposure_value'] as double?,
      focusMode: json['focus_mode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lens_direction': lensDirection,
      'resolution_preset': resolutionPreset,
      'flash_used': flashUsed,
      'exposure_value': exposureValue,
      'focus_mode': focusMode,
    };
  }

  CameraSettings toEntity() {
    return CameraSettings(
      lensDirection: lensDirection,
      resolutionPreset: resolutionPreset,
      flashUsed: flashUsed,
      exposureValue: exposureValue,
      focusMode: focusMode,
    );
  }
}

/// Data model for image quality
class ImageQualityModel {
  final int qualityScore;
  final int brightness;
  final int sharpness;
  final int clarity;
  final bool hasGoodLighting;
  final bool isInFocus;

  const ImageQualityModel({
    required this.qualityScore,
    required this.brightness,
    required this.sharpness,
    required this.clarity,
    required this.hasGoodLighting,
    required this.isInFocus,
  });

  factory ImageQualityModel.poor() {
    return const ImageQualityModel(
      qualityScore: 0,
      brightness: 0,
      sharpness: 0,
      clarity: 0,
      hasGoodLighting: false,
      isInFocus: false,
    );
  }

  factory ImageQualityModel.fromJson(Map<String, dynamic> json) {
    final brightness = json['brightness'] as int? ?? 0;
    final sharpness = json['sharpness'] as int? ?? 0;
    
    return ImageQualityModel(
      qualityScore: json['quality_score'] as int? ?? 0,
      brightness: brightness,
      sharpness: sharpness,
      clarity: json['clarity'] as int? ?? 0,
      hasGoodLighting: brightness > 60,
      isInFocus: sharpness > 70,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quality_score': qualityScore,
      'brightness': brightness,
      'sharpness': sharpness,
      'clarity': clarity,
      'has_good_lighting': hasGoodLighting,
      'is_in_focus': isInFocus,
    };
  }

  ImageQuality toEntity() {
    return ImageQuality(
      qualityScore: qualityScore,
      brightness: brightness,
      sharpness: sharpness,
      clarity: clarity,
      hasGoodLighting: hasGoodLighting,
      isInFocus: isInFocus,
    );
  }
}