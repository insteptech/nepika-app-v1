import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

/// Handles image processing for face scan captured images
class FaceScanImageProcessor {
  
  /// Process captured image for upload (flip if front camera)
  static Future<XFile> processImageForUpload(
    XFile imageFile,
    CameraLensDirection? lensDirection,
  ) async {
    // If it's a front camera, flip the image horizontally
    if (lensDirection == CameraLensDirection.front) {
      try {
        final bytes = await imageFile.readAsBytes();
        final image = img.decodeImage(bytes);
        
        if (image != null) {
          // Flip horizontally
          final flippedImage = img.flipHorizontal(image);
          
          // Save the flipped image to a temporary file
          final tempDir = Directory.systemTemp;
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final tempFile = File('${tempDir.path}/flipped_face_image_$timestamp.jpg');
          await tempFile.writeAsBytes(img.encodeJpg(flippedImage));
          
          debugPrint('Image flipped for front camera');
          return XFile(tempFile.path);
        }
      } catch (e) {
        debugPrint('Error processing image: $e');
      }
    }
    
    // Return original image if not front camera or if processing failed
    return imageFile;
  }

  /// Create a filename for temporary image files
  static String generateImageFilename({String prefix = 'face_scan'}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp.jpg';
  }

  /// Validate image file before processing
  static Future<bool> validateImageFile(XFile imageFile) async {
    try {
      final file = File(imageFile.path);
      if (!await file.exists()) {
        debugPrint('Image file does not exist');
        return false;
      }

      final fileSize = await file.length();
      const maxFileSize = 10 * 1024 * 1024; // 10MB
      
      if (fileSize > maxFileSize) {
        debugPrint('Image file too large: ${fileSize} bytes');
        return false;
      }

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        debugPrint('Invalid image format');
        return false;
      }

      debugPrint('Image validation passed: ${image.width}x${image.height}');
      return true;
    } catch (e) {
      debugPrint('Error validating image: $e');
      return false;
    }
  }

  /// Get image dimensions
  static Future<Size?> getImageDimensions(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image != null) {
        return Size(image.width.toDouble(), image.height.toDouble());
      }
    } catch (e) {
      debugPrint('Error getting image dimensions: $e');
    }
    return null;
  }

  /// Cleanup temporary image files
  static Future<void> cleanupTempFiles(List<String> filePaths) async {
    for (final path in filePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          debugPrint('Cleaned up temp file: $path');
        }
      } catch (e) {
        debugPrint('Error cleaning up temp file $path: $e');
      }
    }
  }
}

/// Represents image dimensions
class Size {
  final double width;
  final double height;

  const Size(this.width, this.height);

  @override
  String toString() => 'Size($width, $height)';
}