import 'package:flutter/material.dart';
import 'package:nepika/core/config/env.dart';

class ImageGallerySection extends StatelessWidget {
  final List<Map<String, dynamic>> imageGallery;
  final bool isLoading;
  final String token;

  const ImageGallerySection({
    Key? key,
    required this.token,
    required this.imageGallery,
    this.isLoading = false, // default not loading
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // 🔄 Show skeleton loaders while fetching
      return SizedBox(
        height: 135,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 125,
              height: 130,
              color: Colors.grey.shade300,
            ),
          ),
        ),
      );
    }

    if (imageGallery.isEmpty) {
      // ❌ No images found
      return SizedBox(
        height: 135,
        child: Center(
          child: Text(
            "No images found",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ),
      );
    }

    // ✅ Show images
    return SizedBox(
      height: 135,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageGallery.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final img = imageGallery[index];
          final imageUrl =  '${Env.baseUrl}/reports/${img['id']}/image';
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              imageUrl,
              headers: {
                'Authorization': 'Bearer $token'
              },
              width: 125,
              height: 130,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 125,
                  height: 130,
                  color: Colors.grey.shade300,
                );
              },
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/image_placeholder.png',
                width: 125,
                height: 130,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
