import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Media preview component for displaying selected media
/// Follows Single Responsibility Principle - only handles media display
class MediaPreview extends StatelessWidget {
  final List<XFile> selectedMedia;
  final Function(int) onRemoveMedia;

  const MediaPreview({
    super.key,
    required this.selectedMedia,
    required this.onRemoveMedia,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedMedia.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: selectedMedia.length,
        itemBuilder: (context, index) {
          final media = selectedMedia[index];
          final isVideo = media.path.toLowerCase().contains('.mp4') ||
                         media.path.toLowerCase().contains('.mov') ||
                         media.path.toLowerCase().contains('.avi');

          return Container(
            width: 90,
            height: 90,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: isVideo
                      ? Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.videocam,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Image.file(
                          File(media.path),
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 90,
                              height: 90,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.error,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => onRemoveMedia(index),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                if (isVideo)
                  const Positioned(
                    bottom: 4,
                    left: 4,
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}