import 'package:flutter/material.dart';
import '../models/report_image_model.dart';
import '../../face_scan/screens/scan_result_details_screen.dart';
import '../../../core/widgets/back_button.dart';

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

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late PageController _pageController;
  late int _currentImageIndex;

  @override
  void initState() {
    super.initState();
    _currentImageIndex = widget.currentIndex ?? 0;
    _pageController = PageController(initialPage: _currentImageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentImageIndex = index;
    });
  }

  void _viewReport() {
    if (widget.allImages != null && _currentImageIndex < widget.allImages!.length) {
      final currentImage = widget.allImages![_currentImageIndex];
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ScanResultDetailsScreen(
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
      body: Column(
        children: [
          // Top header with full opacity black background
          SafeArea(
            bottom: false,
            child: Container(
              color: Colors.black,
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
                  
                  // View Results button on right
                  if (widget.allImages != null)
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
                ],
              ),
            ),
          ),

          // Main image in center (expanded to fill remaining space)
          Expanded(
            child: Container(
              color: Colors.black,
              width: double.infinity,
              child: hasMultipleImages
                  ? _buildPageView(context)
                  : _buildSingleImage(context),
            ),
          ),

          // Bottom header with full opacity black background for image numbers
          if (hasMultipleImages)
            Container(
              color: Colors.black,
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
        ],
      ),
    );
  }


  Widget _buildSingleImage(BuildContext context) {
    return InteractiveViewer(
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
    );
  }

  Widget _buildPageView(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: widget.allImageUrls?.length ?? 1,
      itemBuilder: (context, index) {
        final url = widget.allImageUrls![index];
        return InteractiveViewer(
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
        );
      },
    );
  }

}
