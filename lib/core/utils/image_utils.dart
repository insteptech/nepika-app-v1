import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Utility class for image processing operations
class ImageUtils {
  /// Fixes image orientation based on EXIF data and handles front camera mirroring
  /// This ensures images captured from camera are properly oriented
  static Future<String> fixImageOrientation(String imagePath, {bool isFromFrontCamera = false}) async {
    try {
      // Read the image file
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // Decode the image
      final img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        return imagePath; // Return original if decode fails
      }
      
      // Fix orientation based on EXIF data
      img.Image orientedImage = img.bakeOrientation(image);
      
      // Flip horizontally if from front camera to fix mirroring
      if (isFromFrontCamera) {
        orientedImage = img.flipHorizontal(orientedImage);
      }
      
      // Encode the corrected image
      final List<int> correctedBytes = img.encodeJpg(orientedImage, quality: 90);
      
      // Create a new file path for the corrected image
      final String directory = imageFile.parent.path;
      final String fileName = imageFile.path.split('/').last;
      final String nameWithoutExt = fileName.split('.').first;
      final String correctedPath = '$directory/${nameWithoutExt}_corrected.jpg';
      
      // Write the corrected image
      final File correctedFile = File(correctedPath);
      await correctedFile.writeAsBytes(correctedBytes);
      
      // Delete the original file to save space
      await imageFile.delete();
      
      return correctedPath;
    } catch (e) {
      // If processing fails, return the original path
      return imagePath;
    }
  }
  
  /// Compresses and resizes image while maintaining aspect ratio
  static Future<String> compressImage(String imagePath, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
    bool isFromFrontCamera = false,
  }) async {
    try {
      // Read the image file
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // Decode the image
      final img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        return imagePath; // Return original if decode fails
      }
      
      // Fix orientation first
      img.Image orientedImage = img.bakeOrientation(image);
      
      // Flip horizontally if from front camera to fix mirroring
      if (isFromFrontCamera) {
        orientedImage = img.flipHorizontal(orientedImage);
      }
      
      // Calculate new dimensions while maintaining aspect ratio
      int newWidth = orientedImage.width;
      int newHeight = orientedImage.height;
      
      if (newWidth > maxWidth || newHeight > maxHeight) {
        final double aspectRatio = newWidth / newHeight;
        
        if (aspectRatio > 1) {
          // Landscape
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
        } else {
          // Portrait or square
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
        }
      }
      
      // Resize the image if needed
      img.Image resizedImage = orientedImage;
      if (newWidth != orientedImage.width || newHeight != orientedImage.height) {
        resizedImage = img.copyResize(
          orientedImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      }
      
      // Encode the processed image
      final List<int> processedBytes = img.encodeJpg(resizedImage, quality: quality);
      
      // Create a new file path for the processed image
      final String directory = imageFile.parent.path;
      final String fileName = imageFile.path.split('/').last;
      final String nameWithoutExt = fileName.split('.').first;
      final String processedPath = '$directory/${nameWithoutExt}_processed.jpg';
      
      // Write the processed image
      final File processedFile = File(processedPath);
      await processedFile.writeAsBytes(processedBytes);
      
      // Delete the original file to save space
      await imageFile.delete();
      
      return processedPath;
    } catch (e) {
      // If processing fails, return the original path
      return imagePath;
    }
  }
}