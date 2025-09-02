import 'dart:typed_data';
import 'package:equatable/equatable.dart';

/// Entity representing the images associated with a face scan.
/// Contains both the original captured image and the AI-processed annotated image.
class ScanImage extends Equatable {
  /// Original captured image file path
  final String? originalImagePath;
  
  /// Original captured image as bytes (for immediate processing)
  final Uint8List? originalImageBytes;
  
  /// AI-processed annotated image as bytes (with skin areas highlighted)
  final Uint8List? annotatedImageBytes;
  
  /// Metadata about the original image capture
  final ImageCaptureMetadata captureMetadata;
  
  /// Whether the annotated image was successfully generated
  final bool hasAnnotatedImage;
  
  /// File format of the images (jpg, png, etc.)
  final String imageFormat;

  const ScanImage({
    this.originalImagePath,
    this.originalImageBytes,
    this.annotatedImageBytes,
    required this.captureMetadata,
    required this.hasAnnotatedImage,
    required this.imageFormat,
  });

  /// Creates a copy of this ScanImage with the given fields replaced with new values
  ScanImage copyWith({
    String? originalImagePath,
    Uint8List? originalImageBytes,
    Uint8List? annotatedImageBytes,
    ImageCaptureMetadata? captureMetadata,
    bool? hasAnnotatedImage,
    String? imageFormat,
  }) {
    return ScanImage(
      originalImagePath: originalImagePath ?? this.originalImagePath,
      originalImageBytes: originalImageBytes ?? this.originalImageBytes,
      annotatedImageBytes: annotatedImageBytes ?? this.annotatedImageBytes,
      captureMetadata: captureMetadata ?? this.captureMetadata,
      hasAnnotatedImage: hasAnnotatedImage ?? this.hasAnnotatedImage,
      imageFormat: imageFormat ?? this.imageFormat,
    );
  }

  /// Creates an empty ScanImage for failed scans
  factory ScanImage.empty() {
    return ScanImage(
      captureMetadata: ImageCaptureMetadata.empty(),
      hasAnnotatedImage: false,
      imageFormat: 'jpg',
    );
  }

  /// Creates a ScanImage from captured image file
  factory ScanImage.fromCapture({
    required String imagePath,
    required Uint8List imageBytes,
    required ImageCaptureMetadata metadata,
    String format = 'jpg',
  }) {
    return ScanImage(
      originalImagePath: imagePath,
      originalImageBytes: imageBytes,
      captureMetadata: metadata,
      hasAnnotatedImage: false,
      imageFormat: format,
    );
  }

  /// Adds the annotated image to this ScanImage
  ScanImage withAnnotatedImage(Uint8List annotatedBytes) {
    return copyWith(
      annotatedImageBytes: annotatedBytes,
      hasAnnotatedImage: true,
    );
  }

  /// Gets the image to display (prioritizes annotated image if available)
  Uint8List? get displayImage => annotatedImageBytes ?? originalImageBytes;

  /// Checks if both original and annotated images are available
  bool get isComplete => originalImageBytes != null && annotatedImageBytes != null;

  /// Gets the size of the original image in bytes
  int get originalImageSize => originalImageBytes?.length ?? 0;

  /// Gets the size of the annotated image in bytes
  int get annotatedImageSize => annotatedImageBytes?.length ?? 0;

  @override
  List<Object?> get props => [
        originalImagePath,
        originalImageBytes,
        annotatedImageBytes,
        captureMetadata,
        hasAnnotatedImage,
        imageFormat,
      ];

  @override
  String toString() {
    return 'ScanImage('
        'originalImagePath: $originalImagePath, '
        'hasOriginalBytes: ${originalImageBytes != null}, '
        'hasAnnotatedBytes: ${annotatedImageBytes != null}, '
        'captureMetadata: $captureMetadata, '
        'hasAnnotatedImage: $hasAnnotatedImage, '
        'imageFormat: $imageFormat'
        ')';
  }
}

/// Metadata about the image capture process
class ImageCaptureMetadata extends Equatable {
  /// Timestamp when the image was captured
  final DateTime captureTimestamp;
  
  /// Image dimensions
  final ImageDimensions dimensions;
  
  /// Camera settings used for capture
  final CameraSettings cameraSettings;
  
  /// Quality metrics of the captured image
  final ImageQuality quality;
  
  /// Whether the image meets quality requirements for analysis
  final bool isValidForAnalysis;

  const ImageCaptureMetadata({
    required this.captureTimestamp,
    required this.dimensions,
    required this.cameraSettings,
    required this.quality,
    required this.isValidForAnalysis,
  });

  /// Creates a copy of this ImageCaptureMetadata with the given fields replaced with new values
  ImageCaptureMetadata copyWith({
    DateTime? captureTimestamp,
    ImageDimensions? dimensions,
    CameraSettings? cameraSettings,
    ImageQuality? quality,
    bool? isValidForAnalysis,
  }) {
    return ImageCaptureMetadata(
      captureTimestamp: captureTimestamp ?? this.captureTimestamp,
      dimensions: dimensions ?? this.dimensions,
      cameraSettings: cameraSettings ?? this.cameraSettings,
      quality: quality ?? this.quality,
      isValidForAnalysis: isValidForAnalysis ?? this.isValidForAnalysis,
    );
  }

  /// Creates empty metadata for failed captures
  factory ImageCaptureMetadata.empty() {
    return ImageCaptureMetadata(
      captureTimestamp: DateTime.now(),
      dimensions: const ImageDimensions(width: 0, height: 0),
      cameraSettings: CameraSettings.unknown(),
      quality: ImageQuality.poor(),
      isValidForAnalysis: false,
    );
  }

  @override
  List<Object?> get props => [
        captureTimestamp,
        dimensions,
        cameraSettings,
        quality,
        isValidForAnalysis,
      ];

  @override
  String toString() {
    return 'ImageCaptureMetadata('
        'captureTimestamp: $captureTimestamp, '
        'dimensions: $dimensions, '
        'cameraSettings: $cameraSettings, '
        'quality: $quality, '
        'isValidForAnalysis: $isValidForAnalysis'
        ')';
  }
}

/// Represents image dimensions
class ImageDimensions extends Equatable {
  final int width;
  final int height;

  const ImageDimensions({
    required this.width,
    required this.height,
  });

  /// Gets the aspect ratio of the image
  double get aspectRatio => height != 0 ? width / height : 0.0;

  /// Gets the total number of pixels
  int get totalPixels => width * height;

  /// Creates a copy of this ImageDimensions with the given fields replaced with new values
  ImageDimensions copyWith({
    int? width,
    int? height,
  }) {
    return ImageDimensions(
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  List<Object?> get props => [width, height];

  @override
  String toString() {
    return 'ImageDimensions(width: $width, height: $height)';
  }
}

/// Camera settings used during capture
class CameraSettings extends Equatable {
  /// Camera lens direction (front/back)
  final String lensDirection;
  
  /// Resolution preset used
  final String resolutionPreset;
  
  /// Whether flash was used
  final bool flashUsed;
  
  /// Camera exposure value
  final double? exposureValue;
  
  /// Camera focus mode
  final String? focusMode;

  const CameraSettings({
    required this.lensDirection,
    required this.resolutionPreset,
    required this.flashUsed,
    this.exposureValue,
    this.focusMode,
  });

  /// Creates camera settings for unknown/failed captures
  factory CameraSettings.unknown() {
    return const CameraSettings(
      lensDirection: 'unknown',
      resolutionPreset: 'unknown',
      flashUsed: false,
    );
  }

  /// Creates a copy of this CameraSettings with the given fields replaced with new values
  CameraSettings copyWith({
    String? lensDirection,
    String? resolutionPreset,
    bool? flashUsed,
    double? exposureValue,
    String? focusMode,
  }) {
    return CameraSettings(
      lensDirection: lensDirection ?? this.lensDirection,
      resolutionPreset: resolutionPreset ?? this.resolutionPreset,
      flashUsed: flashUsed ?? this.flashUsed,
      exposureValue: exposureValue ?? this.exposureValue,
      focusMode: focusMode ?? this.focusMode,
    );
  }

  @override
  List<Object?> get props => [
        lensDirection,
        resolutionPreset,
        flashUsed,
        exposureValue,
        focusMode,
      ];

  @override
  String toString() {
    return 'CameraSettings('
        'lensDirection: $lensDirection, '
        'resolutionPreset: $resolutionPreset, '
        'flashUsed: $flashUsed, '
        'exposureValue: $exposureValue, '
        'focusMode: $focusMode'
        ')';
  }
}

/// Image quality assessment
class ImageQuality extends Equatable {
  /// Overall quality score (0-100)
  final int qualityScore;
  
  /// Brightness level (0-100)
  final int brightness;
  
  /// Sharpness level (0-100)
  final int sharpness;
  
  /// Blur detection score (0-100, higher means less blur)
  final int clarity;
  
  /// Whether the image has sufficient lighting
  final bool hasGoodLighting;
  
  /// Whether the image is in focus
  final bool isInFocus;

  const ImageQuality({
    required this.qualityScore,
    required this.brightness,
    required this.sharpness,
    required this.clarity,
    required this.hasGoodLighting,
    required this.isInFocus,
  });

  /// Creates poor quality metrics for failed captures
  factory ImageQuality.poor() {
    return const ImageQuality(
      qualityScore: 0,
      brightness: 0,
      sharpness: 0,
      clarity: 0,
      hasGoodLighting: false,
      isInFocus: false,
    );
  }

  /// Creates quality metrics indicating good capture conditions
  factory ImageQuality.good({
    int qualityScore = 85,
    int brightness = 75,
    int sharpness = 80,
    int clarity = 90,
  }) {
    return ImageQuality(
      qualityScore: qualityScore,
      brightness: brightness,
      sharpness: sharpness,
      clarity: clarity,
      hasGoodLighting: brightness > 60,
      isInFocus: sharpness > 70,
    );
  }

  /// Checks if the image quality is acceptable for analysis
  bool get isAcceptableForAnalysis {
    return qualityScore >= 60 && hasGoodLighting && isInFocus;
  }

  /// Creates a copy of this ImageQuality with the given fields replaced with new values
  ImageQuality copyWith({
    int? qualityScore,
    int? brightness,
    int? sharpness,
    int? clarity,
    bool? hasGoodLighting,
    bool? isInFocus,
  }) {
    return ImageQuality(
      qualityScore: qualityScore ?? this.qualityScore,
      brightness: brightness ?? this.brightness,
      sharpness: sharpness ?? this.sharpness,
      clarity: clarity ?? this.clarity,
      hasGoodLighting: hasGoodLighting ?? this.hasGoodLighting,
      isInFocus: isInFocus ?? this.isInFocus,
    );
  }

  @override
  List<Object?> get props => [
        qualityScore,
        brightness,
        sharpness,
        clarity,
        hasGoodLighting,
        isInFocus,
      ];

  @override
  String toString() {
    return 'ImageQuality('
        'qualityScore: $qualityScore, '
        'brightness: $brightness, '
        'sharpness: $sharpness, '
        'clarity: $clarity, '
        'hasGoodLighting: $hasGoodLighting, '
        'isInFocus: $isInFocus'
        ')';
  }
}