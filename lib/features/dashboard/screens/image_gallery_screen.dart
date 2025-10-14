import 'package:flutter/material.dart';
import '../../../core/api_base.dart';
import '../../../core/widgets/back_button.dart';
import '../models/report_image_model.dart';
import '../widgets/bento_grid_layout.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/simple_gallery_image.dart';
import 'image_preview_screen.dart';

/// Full screen image gallery with bento grid layout
/// Displays all user's scan images in an aesthetically pleasing grid
class ImageGalleryScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initialImages;

  const ImageGalleryScreen({
    super.key,
    this.initialImages,
  });

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  final List<ReportImage> _images = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  int _currentPage = 0;
  static const int _pageSize = 6; // Further reduced for immediate loading

  @override
  void initState() {
    super.initState();
    _loadImages();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Handle scroll events for lazy loading
  void _onScroll() {
    // Load more when user is 600px from bottom (very aggressive preloading)
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 600) {
      if (!_isLoadingMore && _hasMore && !_isLoading) {
        _loadMoreImages();
      }
    }
  }

  /// Initial load of images
  Future<void> _loadImages() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 0;
      });

      debugPrint('🖼️ Fetching report images from API...');

      // Fetch images from API
      final response = await ApiBase().request(
        path: '/training/report-images',
        method: 'GET',
      );

      debugPrint('📡 Report images API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = ReportImagesResponse.fromJson(response.data as Map<String, dynamic>);

        debugPrint('✅ Loaded ${data.reports.length} images (total: ${data.totalCount})');

        setState(() {
          _images.clear();
          _images.addAll(data.reports.take(_pageSize));
          _hasMore = data.reports.length > _pageSize;
          _isLoading = false;
        });
        
        // Preload the next batch immediately if available
        if (_hasMore && data.reports.length > _pageSize) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_isLoadingMore) {
              _loadMoreImages();
            }
          });
        }
      } else {
        throw Exception('Failed to load images: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching images: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Load more images for pagination
  Future<void> _loadMoreImages() async {
    if (_isLoadingMore || !_hasMore) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      _currentPage++;

      debugPrint('📄 Loading page $_currentPage...');

      // In a real implementation, you would pass page/offset to the API
      // For now, we simulate pagination by loading all and slicing locally
      final response = await ApiBase().request(
        path: '/training/report-images',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final data = ReportImagesResponse.fromJson(response.data as Map<String, dynamic>);

        final startIndex = _currentPage * _pageSize;
        final endIndex = startIndex + _pageSize;
        final moreImages = data.reports.skip(startIndex).take(_pageSize).toList();

        debugPrint('✅ Loaded ${moreImages.length} more images');

        setState(() {
          _images.addAll(moreImages);
          _hasMore = endIndex < data.reports.length;
          _isLoadingMore = false;
        });
      } else {
        throw Exception('Failed to load more images');
      }
    } catch (e) {
      debugPrint('❌ Error loading more images: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshImages() async {
    await _loadImages();
  }

  void _openImagePreview(String imageUrl, int index) {
    final allImageUrls = _images.map((img) => img.imageUrl).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImagePreviewScreen(
          imageUrl: imageUrl,
          heroTag: 'gallery_image_$index',
          allImageUrls: allImageUrls,
          currentIndex: index,
          allImages: _images, // Pass the full image data including report IDs
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState(context);
    }

    if (_images.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: _refreshImages,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Top spacer with back button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SizedBox(height: 16),
                  CustomBackButton(),
                  SizedBox(height: 15),
                ],
              ),
            ),
          ),

          // Sticky header with animated back button and image count
          SliverPersistentHeader(
            pinned: true,
            delegate: _ImageGalleryHeaderDelegate(
              minHeight: 50,
              maxHeight: 50,
              imageCount: _images.length,
            ),
          ),

          // Spacing before content
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),

          // Bento grid images
          SliverToBoxAdapter(
            child: BentoGridLayout(
              children: _buildImageWidgets(),
            ),
          ),

          // Loading more indicator for pagination
          SliverToBoxAdapter(
            child: _buildLoadingMoreIndicator(),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 16),
                CustomBackButton(),
                SizedBox(height: 15),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _ImageGalleryLoadingHeaderDelegate(
            minHeight: 50,
            maxHeight: 50,
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: BentoGridSkeleton(itemCount: 6),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 16),
                CustomBackButton(),
                SizedBox(height: 15),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _ImageGalleryHeaderDelegate(
            minHeight: 50,
            maxHeight: 50,
            imageCount: 0,
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load images',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error ?? 'Unknown error',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.7),
                        ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadImages,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 16),
                CustomBackButton(),
                SizedBox(height: 15),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _ImageGalleryHeaderDelegate(
            minHeight: 50,
            maxHeight: 50,
            imageCount: 0,
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Images Yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your scan images will appear here',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildImageWidgets() {
    debugPrint('🎨 Building bento grid with ${_images.length} images');
    
    return List.generate(_images.length, (index) {
      final image = _images[index];

      return BentoGridItem(
        onTap: () => _openImagePreview(image.imageUrl, index),
        child: SimpleGalleryImage(
          imageUrl: image.imageUrl,
          heroTag: 'gallery_image_$index',
          onTap: () => _openImagePreview(image.imageUrl, index),
        ),
      );
    });
  }


  /// Build loading indicator for pagination
  Widget _buildLoadingMoreIndicator() {
    if (!_isLoadingMore) return const SizedBox.shrink();

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Custom header delegate for image gallery with title and count
class _ImageGalleryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final int imageCount;

  _ImageGalleryHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.imageCount,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isStuckToTop = shrinkOffset > 0;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Animated back button that appears when stuck
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isStuckToTop ? 40 : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isStuckToTop ? 1.0 : 0.0,
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: 40,
                child: CustomBackButton(
                  label: '',
                  iconSize: 24,
                  iconColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),

          // Title
          Expanded(
            child: Text(
              "Image Gallery",
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),

          // Image count
          Text(
            '$imageCount ${imageCount == 1 ? 'image' : 'images'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_ImageGalleryHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        imageCount != oldDelegate.imageCount;
  }
}

/// Loading header delegate with skeleton for image count
class _ImageGalleryLoadingHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;

  _ImageGalleryLoadingHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isStuckToTop = shrinkOffset > 0;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Animated back button that appears when stuck
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isStuckToTop ? 40 : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isStuckToTop ? 1.0 : 0.0,
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: 40,
                child: CustomBackButton(
                  label: '',
                  iconSize: 24,
                  iconColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),

          // Title
          Expanded(
            child: Text(
              "Image Gallery",
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),

          // Loading skeleton for count
          const HeaderCountSkeleton(),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_ImageGalleryLoadingHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight;
  }
}
