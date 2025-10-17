import 'package:flutter/material.dart';
import 'package:nepika/core/config/env.dart';
import 'package:nepika/core/widgets/authenticated_network_image.dart';

class ImageGallerySection extends StatelessWidget {
  final List<Map<String, dynamic>> imageGallery;
  final bool isLoading;
  final VoidCallback? onShowAll; // optional callback when "Show All" pressed

  const ImageGallerySection({
    super.key,
    required this.imageGallery,
    this.isLoading = false,
    this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildSkeletonLoader();
    }

    if (imageGallery.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildImageGallery(context);
  }

  Widget _buildSkeletonLoader() {
    return SizedBox(
      height: 135,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 125,
            height: 130,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      height: 135,
      child: Center(
        child: Text(
          "No images found",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    final showAllTile = imageGallery.length >= 6;
    final displayList = showAllTile
        ? imageGallery.take(5).toList()
        : imageGallery;

    return SizedBox(
      height: 135,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayList.length + (showAllTile ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          // If it's the last item and we need a Show All tile
          if (showAllTile && index == displayList.length) {
            return _buildShowAllTile(context);
          }

          final img = displayList[index];
          final imageUrl = '${Env.baseUrl}/reports/${img['id']}/image';
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              img['url'] ?? imageUrl,
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

  Widget _buildShowAllTile(BuildContext context) {
    return GestureDetector(
      onTap: onShowAll,
      child: Container(
        width: 125,
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.onTertiary,
          // border: Border.all(color: Colors.grey.shade400),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_forward,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Show All',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
