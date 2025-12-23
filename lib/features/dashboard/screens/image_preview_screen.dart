import 'package:flutter/material.dart';
import '../models/report_image_model.dart';
import '../../face_scan/screens/scan_recommendations_loader_screen.dart';
import '../../../core/widgets/back_button.dart';
import '../../../core/config/constants/routes.dart';

/// Full-screen image preview with blurred background
/// Provides an immersive viewing experience for gallery images
class ImagePreviewScreen extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;
  final List<String>? allImageUrls;
  final int? currentIndex;
  final List<ReportImage>? allImages; // Add full image data

  const ImagePreviewScreen({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.allImageUrls,
    this.currentIndex,
    this.allImages,
  });

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentImageIndex;
  late AnimationController _headerFooterController;
  late Animation<double> _headerFooterAnimation;
  bool _isHeaderFooterVisible = true;
  
  // Pull-to-dismiss variables
  late AnimationController _dismissController;
  late Animation<double> _dismissAnimation;
  bool _isDragging = false;
  double _dragProgress = 0.0;
  double _panStartY = 0.0;
  double _panStartX = 0.0;
  double _lastDeltaY = 0.0;
  bool _gestureDecided = false; // Track if we've decided on horizontal vs vertical

  @override
  void initState() {
    super.initState();
    _currentImageIndex = widget.currentIndex ?? 0;
    _pageController = PageController(initialPage: _currentImageIndex);
    
    // Initialize animation controller for header/footer visibility
    _headerFooterController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerFooterAnimation = CurvedAnimation(
      parent: _headerFooterController,
      curve: Curves.easeInOut,
    );
    
    // Initialize animation controller for pull-to-dismiss
    _dismissController = AnimationController(
      duration: const Duration(milliseconds: 200), // Faster animation
      vsync: this,
    );
    _dismissAnimation = CurvedAnimation(
      parent: _dismissController,
      curve: Curves.fastOutSlowIn, // Snappier curve
    );
    
    // Start with header and footer visible
    _headerFooterController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _headerFooterController.dispose();
    _dismissController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentImageIndex = index;
    });
  }

  void _toggleHeaderFooter() {
    setState(() {
      _isHeaderFooterVisible = !_isHeaderFooterVisible;
    });
    
    if (_isHeaderFooterVisible) {
      _headerFooterController.forward();
    } else {
      _headerFooterController.reverse();
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    
    final screenHeight = MediaQuery.of(context).size.height;
    final delta = details.delta.dy;
    
    // Allow downward drag with increased sensitivity
    if (delta > 0) {
      setState(() {
        // Increase sensitivity by reducing the divisor
        _dragProgress += delta / (screenHeight * 0.6); // More sensitive
        _dragProgress = _dragProgress.clamp(0.0, 1.0);
      });
      
      // Update the dismiss animation based on drag progress
      _dismissController.value = _dragProgress;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    
    setState(() {
      _isDragging = false;
    });
    
    const dismissThreshold = 0.15; // Lower threshold for distance
    final velocity = details.velocity.pixelsPerSecond.dy;
    
    // More aggressive dismissal conditions for quick gestures
    if (_dragProgress > dismissThreshold || 
        velocity > 150 ||  // Lower velocity threshold
        (_dragProgress > 0.05 && velocity > 100)) { // Quick short drags
      // Animate out and close quickly
      _dismissController.forward().then((_) {
        Navigator.of(context).pop();
      });
    } else {
      // Snap back to original position
      _dismissController.reverse().then((_) {
        setState(() {
          _dragProgress = 0.0;
        });
      });
    }
  }

  void _viewReport() {
    if (widget.allImages != null && _currentImageIndex < widget.allImages!.length) {
      final currentImage = widget.allImages![_currentImageIndex];
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ScanRecommendationsLoaderScreen(
            reportId: currentImage.id,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasMultipleImages = widget.allImageUrls != null && widget.allImageUrls!.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
          animation: _dismissAnimation,
          builder: (context, child) {
            final translateY = _dismissAnimation.value * MediaQuery.of(context).size.height * 0.4; // More movement
            final scale = 1.0 - (_dismissAnimation.value * 0.15); // More scaling
            final opacity = 1.0 - (_dismissAnimation.value * 0.7); // More dramatic fade
            
            return Transform.translate(
              offset: Offset(0, translateY),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Stack(
                    children: [
                      // Main image (within safe area)
                      Positioned.fill(
                        child: SafeArea(
                          child: Container(
                            color: Colors.black,
                            width: double.infinity,
                            child: hasMultipleImages
                                ? _buildPageView(context)
                                : _buildSingleImage(context),
                          ),
                        ),
                      ),

          // Top header with animation
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -1),
                end: Offset.zero,
              ).animate(_headerFooterAnimation),
              child: FadeTransition(
                opacity: _headerFooterAnimation,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Custom back button on left
                        CustomBackButton(
                          label: '',
                          iconColor: Colors.white,
                          iconSize: 24,
                        ),
                        
                        // Action buttons on right
                        if (widget.allImages != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // View Results button
                              TextButton(
                                onPressed: _viewReport,
                                child: Text(
                                  'View Results',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Face Scan Info button
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushNamed(AppRoutes.faceScanInfo);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom footer with animation for image numbers
          if (hasMultipleImages)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(_headerFooterAnimation),
                child: FadeTransition(
                  opacity: _headerFooterAnimation,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.8),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SafeArea(
                      top: false,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_currentImageIndex + 1} / ${widget.allImageUrls!.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
    );
  }


  Widget _buildSingleImage(BuildContext context) {
    return Listener(
      onPointerDown: (details) {
        // Track the start position for potential pan gesture
        _panStartY = details.position.dy;
        _panStartX = details.position.dx;
        _gestureDecided = false;
      },
      onPointerMove: (details) {
        // Check if this looks like a downward drag
        final deltaY = details.position.dy - _panStartY;
        final deltaX = (details.position.dx - _panStartX).abs();

        // Only decide once per gesture
        if (!_gestureDecided && (deltaY.abs() > 15 || deltaX > 15)) {
          _gestureDecided = true;

          // Only treat as vertical dismiss if:
          // 1. Vertical movement is significantly greater than horizontal (2:1 ratio)
          // 2. Movement is downward
          // 3. Minimum vertical threshold met
          if (deltaY > 30 && deltaY > deltaX * 2) {
            _onPanStart(DragStartDetails(
              globalPosition: details.position,
              localPosition: details.localPosition,
            ));
          }
        }

        if (_isDragging) {
          _onPanUpdate(DragUpdateDetails(
            globalPosition: details.position,
            localPosition: details.localPosition,
            delta: Offset(0, deltaY - _lastDeltaY),
          ));
          _lastDeltaY = deltaY;
        }
      },
      onPointerUp: (details) {
        if (_isDragging) {
          final deltaY = details.position.dy - _panStartY;
          final velocity = deltaY / 100; // Simple velocity calculation
          _onPanEnd(DragEndDetails(
            velocity: Velocity(pixelsPerSecond: Offset(0, velocity * 1000)),
          ));
        }
        _lastDeltaY = 0;
        _gestureDecided = false;
      },
      child: GestureDetector(
        onTap: _toggleHeaderFooter,
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: widget.heroTag ?? widget.imageUrl,
            child: Image.network(
              widget.imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageView(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: widget.allImageUrls?.length ?? 1,
      itemBuilder: (context, index) {
        final url = widget.allImageUrls![index];
        return Listener(
          onPointerDown: (details) {
            _panStartY = details.position.dy;
            _panStartX = details.position.dx;
            _gestureDecided = false;
          },
          onPointerMove: (details) {
            final deltaY = details.position.dy - _panStartY;
            final deltaX = (details.position.dx - _panStartX).abs();

            // Only decide once per gesture
            if (!_gestureDecided && (deltaY.abs() > 15 || deltaX > 15)) {
              _gestureDecided = true;

              // Only treat as vertical dismiss if:
              // 1. Vertical movement is significantly greater than horizontal (2:1 ratio)
              // 2. Movement is downward
              // 3. Minimum vertical threshold met
              if (deltaY > 30 && deltaY > deltaX * 2) {
                _onPanStart(DragStartDetails(
                  globalPosition: details.position,
                  localPosition: details.localPosition,
                ));
              }
            }

            if (_isDragging) {
              _onPanUpdate(DragUpdateDetails(
                globalPosition: details.position,
                localPosition: details.localPosition,
                delta: Offset(0, deltaY - _lastDeltaY),
              ));
              _lastDeltaY = deltaY;
            }
          },
          onPointerUp: (details) {
            if (_isDragging) {
              final deltaY = details.position.dy - _panStartY;
              final velocity = deltaY / 100;
              _onPanEnd(DragEndDetails(
                velocity: Velocity(pixelsPerSecond: Offset(0, velocity * 1000)),
              ));
            }
            _lastDeltaY = 0;
            _gestureDecided = false;
          },
          child: GestureDetector(
            onTap: _toggleHeaderFooter,
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                url,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 64,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

}
