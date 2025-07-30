import 'package:flutter/material.dart';

class ImageGallerySection extends StatelessWidget {
  final List<Map<String, dynamic>> imageGallery;

  const ImageGallerySection({
    Key? key,
    required this.imageGallery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayImages = imageGallery.isNotEmpty
        ? imageGallery
        : [
            {
              "id": "img_1",
              "timestamp": "2025-06-10T10:00:00Z"
            },
            {
              "id": "img_2",
              "timestamp": "2025-06-15T10:00:00Z"
            },
            {
              "id": "img_3",
              "timestamp": "2025-06-15T10:00:00Z"
            },
            {
              "id": "img_4",
              "timestamp": "2025-06-20T10:00:00Z"
            }
          ];

    return SizedBox(
      height: 135,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayImages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final img = displayImages[index];
          final imageUrl = img['url'];

          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 125,
                    height: 130,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/image_placeholder.png',
                      width: 125,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    'assets/images/image_placeholder.png',
                    width: 125,
                    height: 130,
                    fit: BoxFit.cover,
                  ),
          );
        },
      ),
    );
  }
}
