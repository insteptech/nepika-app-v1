import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'optimized_gallery_image.dart';
import 'skeleton_loader.dart';

/// Lazy loading wrapper that only loads images when they become visible
class LazyLoadingImage extends StatefulWidget {
  final String imageUrl;
  final VoidCallback? onTap;
  final String heroTag;

  const LazyLoadingImage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.onTap,
  });

  @override
  State<LazyLoadingImage> createState() => _LazyLoadingImageState();
}

class _LazyLoadingImageState extends State<LazyLoadingImage> {
  bool _hasBeenVisible = false;

  @override
  void initState() {
    super.initState();
    // Delay visibility check to ensure widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    if (!mounted) return;
    
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject == null) return;

    final RenderAbstractViewport? viewport = RenderAbstractViewport.of(renderObject);
    if (viewport == null) return;

    final ScrollableState? scrollableState = Scrollable.of(context);
    if (scrollableState == null) return;

    // Get the viewport bounds
    final RevealedOffset offsetToRevealTop = viewport.getOffsetToReveal(renderObject, 0.0);
    final RevealedOffset offsetToRevealBottom = viewport.getOffsetToReveal(renderObject, 1.0);
    
    final double currentOffset = scrollableState.position.pixels;
    
    // Add buffer to start loading images slightly before they're visible
    const double buffer = 200.0;
    
    final bool isVisible = currentOffset >= (offsetToRevealTop.offset - buffer) && 
                          currentOffset <= (offsetToRevealBottom.offset + buffer);

    if (isVisible && !_hasBeenVisible) {
      setState(() {
        _hasBeenVisible = true; // Once loaded, keep it loaded
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to scroll updates
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!_hasBeenVisible) {
          _checkVisibility();
        }
        return false;
      },
      child: _hasBeenVisible 
          ? OptimizedGalleryImage(
              imageUrl: widget.imageUrl,
              heroTag: widget.heroTag,
              onTap: widget.onTap,
            )
          : GestureDetector(
              onTap: widget.onTap,
              child: const ImageTileSkeleton(), // Show skeleton until image becomes visible
            ),
    );
  }
}