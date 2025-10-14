import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'skeleton_loader.dart';

/// Simple lazy loading image that only loads when scrolled into view
class SimpleLazyImage extends StatefulWidget {
  final String imageUrl;
  final VoidCallback? onTap;
  final String heroTag;

  const SimpleLazyImage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.onTap,
  });

  @override
  State<SimpleLazyImage> createState() => _SimpleLazyImageState();
}

class _SimpleLazyImageState extends State<SimpleLazyImage> {
  bool _shouldLoad = false;

  @override
  void initState() {
    super.initState();
    // Check visibility after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    if (!mounted || _shouldLoad) return;
    
    try {
      final renderObject = context.findRenderObject() as RenderBox?;
      if (renderObject != null && renderObject.hasSize) {
        final position = renderObject.localToGlobal(Offset.zero);
        final size = renderObject.size;
        final viewportHeight = MediaQuery.of(context).size.height;
        
        // Check if any part of the widget is visible or close to being visible
        final isVisible = position.dy < viewportHeight + 300 && // Buffer below
                         (position.dy + size.height) > -300; // Buffer above
        
        if (isVisible) {
          setState(() {
            _shouldLoad = true;
          });
        }
      }
    } catch (e) {
      // If error occurs, load the image anyway
      debugPrint('Visibility check error: $e');
      setState(() {
        _shouldLoad = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (!_shouldLoad) {
              _checkVisibility();
            }
            return false;
          },
          child: GestureDetector(
            onTap: widget.onTap,
            child: _shouldLoad ? _buildCachedImage() : _buildPlaceholder(),
          ),
        );
      },
    );
  }

  Widget _buildCachedImage() {
    return Hero(
      tag: widget.heroTag,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: widget.imageUrl,
          fit: BoxFit.cover,
          memCacheWidth: 400,
          memCacheHeight: 400,
          placeholder: (context, url) => const ImageTileSkeleton(),
          errorWidget: (context, url, error) {
            debugPrint('❌ Error loading image: $error');
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
          fadeInDuration: const Duration(milliseconds: 200),
          httpHeaders: const {
            'Cache-Control': 'max-age=3600',
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: const ImageTileSkeleton(),
    );
  }
}