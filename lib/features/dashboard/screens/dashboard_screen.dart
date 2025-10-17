import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/data/dashboard/repositories/dashboard_repository.dart';
import 'package:nepika/features/routine/main.dart';
import 'package:nepika/core/services/unified_fcm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/face_scan_card.dart';
import '../widgets/greeting_section.dart';
import '../widgets/image_gallery_section.dart';
import '../widgets/progress_summary_chart.dart';
import '../widgets/recommended_products_section.dart';
import '../widgets/skin_score_card.dart';
import '../widgets/section_header.dart';
import '../widgets/conditions_section.dart';

class DashboardScreen extends StatefulWidget {
  final String? token;
  final VoidCallback? onFaceScanTap;
  final void Function(String route)? onNavigate;

  const DashboardScreen({
    super.key,
    this.token,
    this.onFaceScanTap,
    this.onNavigate,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver, RouteAware {
  late DashboardBloc _dashboardBloc;
  String? _token;
  bool _isInitialized = false;
  DateTime? _lastRefreshTime;
  final FocusNode _focusNode = FocusNode();
  // ignore: unused_field
  bool _isPageVisible = true;
  RouteObserver<PageRoute>? _routeObserver;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dashboardBloc = DashboardBloc(DashboardRepositoryImpl(ApiBase()));

    // Focus listener removed - was causing excessive requests
    
    _loadTokenAndFetch();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed &&
        _isInitialized &&
        _token != null) {
      debugPrint('App resumed, refreshing dashboard data');
      _isPageVisible = true;
      _refreshDashboard();
    } else if (state == AppLifecycleState.paused) {
      _isPageVisible = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Route observer setup
    final route = ModalRoute.of(context);
    if (route != null && route is PageRoute) {
      final navigator = Navigator.of(context);
      final observers = navigator.widget.observers;
      _routeObserver = observers
          .whereType<RouteObserver<PageRoute>>()
          .firstOrNull;
      if (_routeObserver != null) {
        _routeObserver!.subscribe(this, route);
      }
    }
    // Removed dependency change refresh - was causing excessive requests
  }

  @override
  void didPopNext() {
    // Called when a route has been popped off, and the current route shows up
    debugPrint('Dashboard: Returned from another screen');
    _isPageVisible = true;
    // Only refresh if enough time has passed (30 seconds)
    if (_isInitialized && _token != null && _shouldRefresh()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshDashboard();
      });
    }
  }

  @override
  void didPushNext() {
    // Called when the current route has been pushed
    debugPrint('Dashboard: Navigated to another screen');
    _isPageVisible = false;
  }

  bool _shouldRefresh() {
    final now = DateTime.now();
    if (_lastRefreshTime == null) {
      return true;
    }
    // Refresh if more than 30 seconds has passed since last refresh
    // This prevents over-requesting the /welcome endpoint
    return now.difference(_lastRefreshTime!).inSeconds > 30;
  }

  Future<void> _loadTokenAndFetch() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final accessToken = sharedPrefs.getString(AppConstants.accessTokenKey);

    setState(() {
      _token = accessToken ?? widget.token;
      _isInitialized = true;
    });

    if (_token != null) {
      // Generate FCM token now that user is authenticated and on dashboard
      _generateFcmToken();
      
      _dashboardBloc.add(DashboardRequested(_token!));
    }
  }

  /// Generate FCM token when user reaches dashboard
  void _generateFcmToken() {
    // Generate FCM token asynchronously without blocking dashboard load
    UnifiedFcmService.instance.generateToken().then((token) {
      if (token != null) {
        debugPrint('✅ FCM token generated successfully from dashboard: ${token.substring(0, 20)}...');
      } else {
        debugPrint('⚠️ FCM token generation failed from dashboard');
      }
    }).catchError((error) {
      debugPrint('❌ FCM token generation error from dashboard: $error');
      // Don't block dashboard flow for FCM failures
    });
  }

  void _refreshDashboard() {
    if (_token != null) {
      debugPrint('Refreshing dashboard with token');
      _lastRefreshTime = DateTime.now();
      _dashboardBloc.add(DashboardRequested(_token!));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();

    // Unsubscribe from RouteObserver
    if (_routeObserver != null) {
      _routeObserver!.unsubscribe(this);
    }
    _dashboardBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Removed build refresh - handled by didPopNext instead

    return BlocProvider.value(
      value: _dashboardBloc,
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return _buildDashboardContent(context, state);
        },
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, DashboardState state) {
    // Initialize default values
    final Map<String, dynamic> user = {};
    final Map<String, dynamic> faceScan = {};
    final Map<String, dynamic> skinScore = {};
    final Map<String, dynamic> progressSummary = {};
    final Map<String, dynamic> dailyRoutine = {};
    final List<Map<String, dynamic>> imageGallery = [];
    final List<Map<String, dynamic>> recommendedProducts = [];
    Map<String, dynamic>? latestConditionResult;

    final bool isLoading = state is DashboardLoading;
    final bool isError = state is DashboardError;

    // Extract data if loaded
    if (state is DashboardLoaded) {
      final dashboardData = state.dashboardData.data;
      user.addAll(dashboardData['user'] ?? {});
      faceScan.addAll(dashboardData['faceScan'] ?? {});
      skinScore.addAll(dashboardData['skinScore'] ?? {});
      progressSummary.addAll(dashboardData['progressSummary'] ?? {});
      dailyRoutine.addAll(dashboardData['dailyRoutine'] ?? {});
      imageGallery.addAll(List<Map<String, dynamic>>.from(
        dashboardData['imageGallery'] ?? [],
      ));
      recommendedProducts.addAll(List<Map<String, dynamic>>.from(
        dashboardData['recommendedProducts'] ?? [],
      ));
      latestConditionResult = dashboardData['latestConditionResult'];
    }

    return PopScope(
      canPop: false,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: _token == null
                ? const Center(child: Text("No token found"))
                : RefreshIndicator(
                    onRefresh: () async {
                      if (_token != null) {
                        context
                            .read<DashboardBloc>()
                            .add(DashboardRequested(_token!));
                      }
                    },
                    child: CustomScrollView(
                      slivers: [
                        _buildSpacerSliver(),
                        _buildGreetingSliver(user),
                        _buildMainContentSliver(
                          context,
                          isLoading,
                          isError,
                          faceScan,
                          skinScore,
                          latestConditionResult,
                          progressSummary,
                          dailyRoutine,
                          imageGallery,
                          recommendedProducts,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpacerSliver() {
    return const SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      sliver: SliverToBoxAdapter(
        child: SizedBox(height: 0),
      ),
    );
  }

  Widget _buildGreetingSliver(Map<String, dynamic> user) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        minHeight: 55,
        maxHeight: 62,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCollapsed = constraints.maxHeight <= 55;
                  return GreetingSection(
                    user: user,
                    isCollapsed: isCollapsed,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContentSliver(
    BuildContext context,
    bool isLoading,
    bool isError,
    Map<String, dynamic> faceScan,
    Map<String, dynamic> skinScore,
    Map<String, dynamic>? latestConditionResult,
    Map<String, dynamic> progressSummary,
    Map<String, dynamic> dailyRoutine,
    List<Map<String, dynamic>> imageGallery,
    List<Map<String, dynamic>> recommendedProducts,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isError || isLoading)
              _buildLoadingErrorSection(context, isLoading, isError),
            SizedBox(height: isError || isLoading ? 10 : 30),
            _buildMainCardsRow(faceScan, skinScore),
            ConditionsSection(
              latestConditionResult: latestConditionResult,
              onConditionTap: (conditionName) =>
                  _handleConditionTap(conditionName, skinScore, imageGallery),
            ),
            const SizedBox(height: 10),
            _buildProgressSummarySection(progressSummary),
            _buildDailyRoutineSection(dailyRoutine, isLoading),
            _buildImageGallerySection(imageGallery, isLoading),
            // _buildRecommendedProductsSection(recommendedProducts, isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingErrorSection(
      BuildContext context, bool isLoading, bool isError) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          isLoading ? 'Loading...' : 'Failed to load dashboard data',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }

  Widget _buildMainCardsRow(
      Map<String, dynamic> faceScan, Map<String, dynamic> skinScore) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: FaceScanCard(
              faceScan: faceScan,
              onTap: widget.onFaceScanTap,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SkinScoreCard(skinScore: skinScore),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummarySection(Map<String, dynamic> progressSummary) {
    return Column(
      children: [
        const SectionHeader(
          heading: 'Progress Summary',
          showButton: false,
        ),
        ProgressSummaryChart(
          progressSummary: progressSummary,
          height: 280,
          showPointsAndLabels: false,
        ),
      ],
    );
  }

  Widget _buildDailyRoutineSection(
      Map<String, dynamic> dailyRoutine, bool isLoading) {
    return Column(
      children: [
        RepaintBoundary(
          child: SectionHeader(
            heading: 'Daily Routine',
            showButton: true,
            buttonText: 'View all',
            onButtonPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.dashboardTodaysRoutine);
            },
            buttonLoading: isLoading,
          ),
        ),
        DailyRoutineCard(dailyRoutine: dailyRoutine),
      ],
    );
  }

  Widget _buildImageGallerySection(
      List<Map<String, dynamic>> imageGallery, bool isLoading) {
    return Column(
      children: [
        SectionHeader(
          heading: 'Image Gallery',
          showButton: true,
          buttonText: 'View all',
          onButtonPressed: () {
            Navigator.of(context, rootNavigator: true).pushNamed(
              AppRoutes.dashboardImageGallery,
              arguments: {'images': imageGallery},
            );
          },
          buttonLoading: isLoading,
        ),
        ImageGallerySection(
          imageGallery: imageGallery,
          isLoading: isLoading,
          onShowAll: () {
            Navigator.of(context, rootNavigator: true).pushNamed(
              AppRoutes.dashboardImageGallery,
              arguments: {'images': imageGallery},
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecommendedProductsSection(
      List<Map<String, dynamic>> recommendedProducts, bool isLoading) {
    return Column(
      children: [
        SectionHeader(
          heading: 'Recommend Products',
          showButton: true,
          buttonText: 'View all',
          onButtonPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.dashboardAllProducts);
          },
          buttonLoading: isLoading,
        ),
        RecommendedProductsSection(
          products: recommendedProducts,
          scrollDirection: Axis.horizontal,
          showTag: true,
        ),
      ],
    );
  }

  void _handleConditionTap(
      String conditionName,
      Map<String, dynamic> skinScore,
      List<Map<String, dynamic>> imageGallery) {
    // Get the latest report ID from imageGallery
    String? reportId;
    if (imageGallery.isNotEmpty) {
      reportId = imageGallery.first['id'] as String?;
    }

    if (reportId != null) {
      // Navigate to scan result details screen with report ID
      Navigator.of(context, rootNavigator: true).pushNamed(
        AppRoutes.scanResultDetails,
        arguments: {
          'reportId': reportId,
        },
      );
    } else {
      // Fallback: Show error if no report ID available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No scan results available'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  const _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}