import 'package:flutter/material.dart';
import 'skeleton_loader.dart';

/// Optimized gallery image widget with fast loading and preloading
class SimpleGalleryImage extends StatefulWidget {
  final String imageUrl;
  final VoidCallback? onTap;
  final String heroTag;

  const SimpleGalleryImage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.onTap,
  });

  @override
  State<SimpleGalleryImage> createState() => _SimpleGalleryImageState();
}

class _SimpleGalleryImageState extends State<SimpleGalleryImage> {
  late ImageProvider _imageProvider;
  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _imageProvider = NetworkImage(widget.imageUrl);
    _preloadImage();
  }

  void _preloadImage() {
    _imageProvider.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onError: (exception, stackTrace) {
          debugPrint('❌ Error preloading image: $exception');
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Hero(
        tag: widget.heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildImageContent(),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isLoaded) {
      return const ImageTileSkeleton();
    }

    return Image(
      image: _imageProvider,
      fit: BoxFit.cover,
      gaplessPlayback: true, // Prevents flicker during image changes
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Error displaying image: $error');
        return _buildErrorWidget();
      },
    );
  }

  Widget _buildErrorWidget() {
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
  }

  @override
  void dispose() {
    // Clean up image provider if needed
    super.dispose();
  }
}