import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'skeleton_loader.dart';

/// Optimized image widget for gallery with lazy loading and caching
class OptimizedGalleryImage extends StatefulWidget {
  final String imageUrl;
  final VoidCallback? onTap;
  final String heroTag;

  const OptimizedGalleryImage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.onTap,
  });

  @override
  State<OptimizedGalleryImage> createState() => _OptimizedGalleryImageState();
}

class _OptimizedGalleryImageState extends State<OptimizedGalleryImage>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; // Keep widget alive to maintain loaded state

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return GestureDetector(
      onTap: widget.onTap,
      child: Hero(
        tag: widget.heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl,
            fit: BoxFit.cover,
            
            // Memory cache options
            memCacheWidth: 400, // Limit memory cache size for performance
            memCacheHeight: 400,
            
            // Placeholder while loading
            placeholder: (context, url) => const ImageTileSkeleton(),
            
            // Error widget
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
            
            // Progressive loading with fade-in animation
            fadeInDuration: const Duration(milliseconds: 200),
            fadeOutDuration: const Duration(milliseconds: 100),
            
            // HTTP headers for better caching
            httpHeaders: const {
              'Cache-Control': 'max-age=3600', // Cache for 1 hour
            },
          ),
        ),
      ),
    );
  }
}