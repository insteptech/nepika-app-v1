import 'package:flutter/material.dart';

/// Media picker component for selecting images and videos
/// Follows Single Responsibility Principle - only handles media selection UI
class MediaPickerBottomSheet extends StatelessWidget {
  final VoidCallback onGalleryTap;
  final VoidCallback onVideoTap;
  final VoidCallback onCameraTap;

  const MediaPickerBottomSheet({
    super.key,
    required this.onGalleryTap,
    required this.onVideoTap,
    required this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Photo Gallery'),
              subtitle: const Text('Select photos from gallery'),
              onTap: () {
                Navigator.pop(context);
                onGalleryTap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.red),
              title: const Text('Video Gallery'),
              subtitle: const Text('Select videos from gallery'),
              onTap: () {
                Navigator.pop(context);
                onVideoTap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.green),
              title: const Text('Camera'),
              subtitle: const Text('Take a new photo'),
              onTap: () {
                Navigator.pop(context);
                onCameraTap();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Static method to show the media picker bottom sheet
  static void show(
    BuildContext context, {
    required VoidCallback onGalleryTap,
    required VoidCallback onVideoTap,
    required VoidCallback onCameraTap,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return MediaPickerBottomSheet(
          onGalleryTap: onGalleryTap,
          onVideoTap: onVideoTap,
          onCameraTap: onCameraTap,
        );
      },
    );
  }
}