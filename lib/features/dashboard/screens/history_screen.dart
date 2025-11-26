import 'package:flutter/material.dart';
import '../../../core/api_base.dart';
import '../../../core/widgets/back_button.dart';
import '../models/scan_history_models.dart';
import '../widgets/skeleton_loader.dart';
import '../../face_scan/screens/scan_recommendations_loader_screen.dart';

/// Scan history screen showing user's scanning timeline
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<ScanHistoryItem> _scans = [];
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  
  int _currentOffset = 0;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      if (!_isLoadingMore && _hasMore && !_isLoading) {
        _loadMoreHistory();
      }
    }
  }

  Future<void> _loadHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentOffset = 0;
      });

      debugPrint('🕒 Fetching scan history from API...');

      final response = await ApiBase().request(
        path: '/training/scan-history',
        method: 'GET',
        query: {
          'limit': _limit.toString(),
          'offset': '0',
        },
      );

      debugPrint('📡 History API response status: ${response.statusCode}');
      debugPrint('📡 History API response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = ScanHistoryResponse.fromJson(response.data as Map<String, dynamic>);
        
        debugPrint('✅ Loaded ${data.scans.length} scans (total: ${data.totalCount})');

        setState(() {
          _scans.clear();
          _scans.addAll(data.scans);
          _hasMore = data.scans.length >= _limit && _scans.length < data.totalCount;
          _isLoading = false;
          _currentOffset = data.scans.length;
        });
      } else {
        throw Exception('Failed to load history: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching history: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreHistory() async {
    if (_isLoadingMore || !_hasMore) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      debugPrint('📄 Loading more history from offset $_currentOffset...');

      final response = await ApiBase().request(
        path: '/training/scan-history',
        method: 'GET',
        query: {
          'limit': _limit.toString(),
          'offset': _currentOffset.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = ScanHistoryResponse.fromJson(response.data as Map<String, dynamic>);
        
        debugPrint('✅ Loaded ${data.scans.length} more scans');

        setState(() {
          _scans.addAll(data.scans);
          _hasMore = data.scans.length >= _limit && _scans.length < data.totalCount;
          _currentOffset += data.scans.length;
          _isLoadingMore = false;
        });
      } else {
        throw Exception('Failed to load more history');
      }
    } catch (e) {
      debugPrint('❌ Error loading more history: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshHistory() async {
    await _loadHistory();
  }

  void _openScanDetails(ScanHistoryItem scan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScanRecommendationsLoaderScreen(
          reportId: scan.id,
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

    if (_scans.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: _refreshHistory,
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

          // Sticky header with animated back button and scan count
          SliverPersistentHeader(
            pinned: true,
            delegate: _ScanHistoryHeaderDelegate(
              minHeight: 50,
              maxHeight: 50,
              scanCount: _scans.length,
            ),
          ),

          // Spacing before content
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),

          // History timeline
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= _scans.length) {
                  return _buildLoadingMoreIndicator();
                }
                
                final scan = _scans[index];
                return _buildHistoryItem(scan, index);
              },
              childCount: _scans.length + (_isLoadingMore ? 1 : 0),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(ScanHistoryItem scan, int index) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 5),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _openScanDetails(scan),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Scan image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Image.network(
                      scan.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const ImageTileSkeleton();
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[600],
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Scan details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date and skin score
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              scan.formattedDate,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: scan.skinScoreColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${scan.skinScore}%',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scan.skinScoreColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Primary condition
                      Text(
                        'Primary: ${scan.primaryCondition.prediction}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Top issues
                      if (scan.topIssues.isNotEmpty)
                        Text(
                          'Issues: ${scan.topIssues.take(2).join(', ')}${scan.topIssues.length > 2 ? '...' : ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withValues(alpha: 0.6),
                          ),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // Recommendations count
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${scan.recommendationsCount} recommendations',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
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

        // Sticky header with loading state (0 scans)
        SliverPersistentHeader(
          pinned: true,
          delegate: _ScanHistoryHeaderDelegate(
            minHeight: 50,
            maxHeight: 50,
            scanCount: 0,
          ),
        ),

        // Spacing before content
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),

        // Loading skeletons
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Container(
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
              height: 112,
              child: const ImageTileSkeleton(),
            ),
            childCount: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return CustomScrollView(
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

        // Sticky header with error state (0 scans)
        SliverPersistentHeader(
          pinned: true,
          delegate: _ScanHistoryHeaderDelegate(
            minHeight: 50,
            maxHeight: 50,
            scanCount: 0,
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
                    'Failed to load history',
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
                    onPressed: _loadHistory,
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

        // Sticky header with animated back button and scan count
        SliverPersistentHeader(
          pinned: true,
          delegate: _ScanHistoryHeaderDelegate(
            minHeight: 50,
            maxHeight: 50,
            scanCount: 0,
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
                    Icons.history,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Scan History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start scanning to see your history here',
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

  Widget _buildLoadingMoreIndicator() {
    if (!_isLoadingMore) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Custom header delegate for scan history with title and count
class _ScanHistoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final int scanCount;

  _ScanHistoryHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.scanCount,
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
              "Scan History",
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),

          // Scan count
          Text(
            '$scanCount ${scanCount == 1 ? 'scan' : 'scans'}',
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
  bool shouldRebuild(_ScanHistoryHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        scanCount != oldDelegate.scanCount;
  }
}