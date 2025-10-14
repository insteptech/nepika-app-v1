import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'skeleton_loader.dart';

/// Optimized gallery image with caching but immediate loading
class CachedGalleryImage extends StatelessWidget {
  final String imageUrl;
  final VoidCallback? onTap;
  final String heroTag;

  const CachedGalleryImage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            
            // Add image loading callback
            imageBuilder: (context, imageProvider) {
              debugPrint('✅ Image loaded successfully: $imageUrl');
              return Image(image: imageProvider, fit: BoxFit.cover);
            },
            
            // Optimize memory usage
            memCacheWidth: 400,
            memCacheHeight: 400,
            maxWidthDiskCache: 800,
            maxHeightDiskCache: 800,
            
            // Loading state
            placeholder: (context, url) {
              debugPrint('🔄 Loading image: $url');
              return const ImageTileSkeleton();
            },
            
            // Error state
            errorWidget: (context, url, error) {
              debugPrint('❌ Error loading gallery image: $error');
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.grey[600],
                  size: 40,
                ),
              );
            },
            
            // Progressive loading
            fadeInDuration: const Duration(milliseconds: 300),
            fadeOutDuration: const Duration(milliseconds: 100),
            
            // Cache configuration
            cacheKey: imageUrl,
            useOldImageOnUrlChange: true,
            
            // HTTP headers
            httpHeaders: const {
              'Cache-Control': 'max-age=3600',
              'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
            },
          ),
        ),
      ),
    );
  }
}