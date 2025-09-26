import 'package:flutter/material.dart';
import 'package:nepika/core/config/env.dart';
import 'package:nepika/core/widgets/authenticated_network_image.dart';

class ImageGallerySection extends StatelessWidget {
  final List<Map<String, dynamic>> imageGallery;
  final bool isLoading;

  const ImageGallerySection({
    super.key,
    required this.imageGallery,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildSkeletonLoader();
    }

    if (imageGallery.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildImageGallery();
  }

  Widget _buildSkeletonLoader() {
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

  Widget _buildEmptyState(BuildContext context) {
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

  Widget _buildImageGallery() {
    return SizedBox(
      height: 135,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageGallery.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final img = imageGallery[index];
          final imageUrl = '${Env.baseUrl}/reports/${img['id']}/image';
          return AuthenticatedNetworkImage(
            imageUrl: imageUrl,
            width: 125,
            height: 130,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(20),
            placeholder: Container(
              width: 125,
              height: 130,
              color: Colors.grey.shade300,
            ),
            errorWidget: Image.asset(
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