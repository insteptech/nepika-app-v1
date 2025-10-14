import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'skeleton_loader.dart';

/// Production-ready gallery image widget with robust error handling
/// Following industry standards for image loading and caching
class RobustGalleryImage extends StatefulWidget {
  final String imageUrl;
  final VoidCallback? onTap;
  final String heroTag;
  final bool enableCaching;

  const RobustGalleryImage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.onTap,
    this.enableCaching = true,
  });

  @override
  State<RobustGalleryImage> createState() => _RobustGalleryImageState();
}

class _RobustGalleryImageState extends State<RobustGalleryImage> {
  bool _hasCacheError = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Hero(
        tag: widget.heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildImageWidget(),
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    // If caching failed or is disabled, use fallback Image.network
    if (_hasCacheError || !widget.enableCaching) {
      return _buildFallbackImage();
    }

    // Try cached network image first
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: BoxFit.cover,
      
      // Success callback
      imageBuilder: (context, imageProvider) {
        debugPrint('✅ Cached image loaded: ${widget.heroTag}');
        return Image(image: imageProvider, fit: BoxFit.cover);
      },
      
      // Optimized caching settings
      memCacheWidth: 400,
      memCacheHeight: 400,
      maxWidthDiskCache: 600,
      maxHeightDiskCache: 600,
      
      // Loading placeholder
      placeholder: (context, url) {
        debugPrint('🔄 Loading cached image: ${widget.heroTag}');
        return const ImageTileSkeleton();
      },
      
      // Error handling with fallback
      errorWidget: (context, url, error) {
        debugPrint('❌ Cached image error for ${widget.heroTag}: $error');
        
        // Switch to fallback mode on caching errors
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _hasCacheError = true;
            });
          }
        });
        
        return _buildFallbackImage();
      },
      
      // Progressive loading
      fadeInDuration: const Duration(milliseconds: 250),
      fadeOutDuration: const Duration(milliseconds: 100),
      
      // Cache configuration
      cacheKey: _generateCacheKey(widget.imageUrl),
      
      // HTTP headers for better performance
      httpHeaders: {
        'Cache-Control': 'max-age=3600, must-revalidate',
        'Accept': 'image/webp,image/apng,image/png,image/jpeg,*/*;q=0.8',
      },
    );
  }

  Widget _buildFallbackImage() {
    debugPrint('🔄 Loading fallback image: ${widget.heroTag}');
    
    return Image.network(
      widget.imageUrl,
      fit: BoxFit.cover,
      
      // Loading builder
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          debugPrint('✅ Fallback image loaded: ${widget.heroTag}');
          return child;
        }
        
        return const ImageTileSkeleton();
      },
      
      // Error builder
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Fallback image error for ${widget.heroTag}: $error');
        return _buildErrorPlaceholder();
      },
      
      // Performance headers
      headers: {
        'Cache-Control': 'max-age=3600',
        'Accept': 'image/webp,image/apng,image/png,image/jpeg,*/*;q=0.8',
      },
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color: Colors.grey[600],
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            'Image unavailable',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Generate a stable cache key from URL
  String _generateCacheKey(String url) {
    // Extract filename from URL, removing query parameters
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.isNotEmpty) {
      final filename = pathSegments.last;
      // Remove file extension and use as cache key
      final nameWithoutExt = filename.split('.').first;
      return 'gallery_$nameWithoutExt';
    }
    
    // Fallback to URL hash
    return 'gallery_${url.hashCode}';
  }
}