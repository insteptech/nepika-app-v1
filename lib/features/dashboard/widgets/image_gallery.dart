import 'package:flutter/material.dart';

class ImageGallerySection extends StatelessWidget {
  final List<Map<String, dynamic>> imageGallery;
  final bool isLoading;

  const ImageGallerySection({
    super.key,
    required this.imageGallery,
    this.isLoading = false, // default not loading
  });

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

    // Filter out items with null URLs
    final filteredGallery = imageGallery.where((img) => img['url'] != null).toList();
    
    if (filteredGallery.isEmpty) {
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
        itemCount: filteredGallery.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final img = filteredGallery[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              img['url'],
              width: 125,
              height: 130,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 125,
                  height: 130,
                  color: Colors.grey.shade300,
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/image_placeholder.png',
                  width: 125,
                  height: 130,
                  fit: BoxFit.cover,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
