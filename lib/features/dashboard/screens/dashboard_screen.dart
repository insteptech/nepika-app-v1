import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/utils/debug_logger.dart';
import 'package:nepika/data/dashboard/repositories/dashboard_repository.dart';
import 'package:nepika/features/face_scan/screens/scan_result_details_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/di/injection_container.dart' as di;
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
import '../widgets/skin_score_card.dart';
import '../widgets/section_header.dart';
import '../widgets/conditions_section.dart';

// Memoization wrapper using RepaintBoundary for performance
Widget _memoizedWidget({
  required Widget child,
  required Object cacheKey,
}) {
  return RepaintBoundary(
    key: ValueKey(cacheKey),
    child: child,
  ); 
}

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
  
  // Cached data to prevent rebuilding on every state change
  Map<String, dynamic>? _cachedUser;
  Map<String, dynamic>? _cachedFaceScan;
  Map<String, dynamic>? _cachedSkinScore;
  Map<String, dynamic>? _cachedProgressSummary;
  Map<String, dynamic>? _cachedDailyRoutine;
  List<Map<String, dynamic>>? _cachedImageGallery;
  List<Map<String, dynamic>>? _cachedRecommendedProducts;
  Map<String, dynamic>? _cachedLatestConditionResult;
  String? _latestSkinReportId;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    try {
      _dashboardBloc = di.ServiceLocator.get<DashboardBloc>();
    } catch (e) {
      // Fallback to creating new instance if DI not available
      _dashboardBloc = DashboardBloc(DashboardRepositoryImpl(ApiBase()));
    }

    // Focus listener removed - was causing excessive requests
    
    _loadTokenAndFetch();
  }


  Future<void> checkNotificationPermission() async {
    debugPrint('\n\n\nChecking notification permission status\n\n\n');
    final status = await Permission.notification.status;
    if (status.isGranted) {
      return;
    }
    await Permission.notification.request();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _isPageVisible = true;
      // Only refresh if app was backgrounded for more than 5 minutes
      if (_isInitialized && _token != null && _shouldRefreshOnResume()) {
        debugPrint('App resumed after long pause, refreshing dashboard data');
        _refreshDashboard();
      }
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
    // Don't auto-refresh when returning from other screens
    // User can manually pull-to-refresh if needed
  }

  @override
  void didPushNext() {
    // Called when the current route has been pushed
    debugPrint('Dashboard: Navigated to another screen');
    _isPageVisible = false;
  }

  // Removed _shouldRefresh method as it's no longer used
  // Dashboard now only refreshes on manual pull-to-refresh

  bool _shouldRefreshOnResume() {
    final now = DateTime.now();
    if (_lastRefreshTime == null) {
      return true;
    }
    // Only refresh on app resume if more than 5 minutes has passed
    return now.difference(_lastRefreshTime!).inMinutes > 5;
  }

  Future<void> _loadTokenAndFetch() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final accessToken = sharedPrefs.getString(AppConstants.accessTokenKey);
    // await checkNotificationPermission();

    setState(() {
      _token = accessToken ?? widget.token;
      _isInitialized = true;
    });

    if (_token != null) {
      // FCM token generation will be triggered after dashboard response
      // with backend token validation optimization
      _dashboardBloc.add(DashboardRequested(_token!));
    }
  }

  /// Generate FCM token when user reaches dashboard (optimized for first-time users)
  /// Now with backend token validation to avoid unnecessary saves
  void _generateFcmToken([String? backendFcmToken]) {
    // Use optimized token generation that checks backend token first
    Future.microtask(() async {
      try {
        debugPrint('🔄 Starting optimized FCM token generation...');
        
        String? token;
        if (backendFcmToken != null) {
          // Use optimized method with backend check
          debugPrint('🔍 Backend FCM token found, checking validity...');
          token = await UnifiedFcmService.instance.generateTokenWithBackendCheck(backendFcmToken);
        } else {
          // No backend token, use normal flow
          debugPrint('⚠️ No backend FCM token found, using normal flow...');
          token = await UnifiedFcmService.instance.generateTokenAndEnsureSaved();
        }
        
        if (token != null) {
          debugPrint('✅ FCM token ready: ${token.substring(0, 20)}...');
        } else {
          debugPrint('⚠️ FCM token generation failed - will retry automatically');
          
          // Fallback: try background generation for retry
          UnifiedFcmService.instance.generateTokenInBackground();
        }
      } catch (e) {
        debugPrint('❌ FCM token generation error: $e');
        
        // Fallback: try background generation
        try {
          UnifiedFcmService.instance.generateTokenInBackground();
        } catch (fallbackError) {
          debugPrint('❌ FCM fallback also failed: $fallbackError');
        }
      }
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
    return BlocProvider.value(
      value: _dashboardBloc,
      child: BlocBuilder<DashboardBloc, DashboardState>(
        buildWhen: (previous, current) {
          // Only rebuild when state type changes or when we get new data
          return previous.runtimeType != current.runtimeType ||
                 (current is DashboardLoaded && previous is! DashboardLoaded);
        },
        builder: (context, state) {
          _updateCachedData(state);
          return _buildDashboardContent(context, state);
        },
      ),
    );
  }
  
  void _updateCachedData(DashboardState state) {
    if (state is DashboardLoaded) {
      final dashboardData = state.dashboardData.data;
      _cachedUser = Map<String, dynamic>.from(dashboardData['user'] ?? {});
      _cachedFaceScan = Map<String, dynamic>.from(dashboardData['faceScan'] ?? {});
      _cachedSkinScore = Map<String, dynamic>.from(dashboardData['skinScore'] ?? {});
      _cachedProgressSummary = Map<String, dynamic>.from(dashboardData['progressSummary'] ?? {});
      _cachedDailyRoutine = Map<String, dynamic>.from(dashboardData['dailyRoutine'] ?? {});
      _cachedImageGallery = List<Map<String, dynamic>>.from(dashboardData['imageGallery'] ?? []);
      _cachedRecommendedProducts = List<Map<String, dynamic>>.from(dashboardData['recommendedProducts'] ?? []);
      _cachedLatestConditionResult = dashboardData['latestConditionResult'];
      _latestSkinReportId = dashboardData['latestSkinReportId'] ?? '';
      
      // Extract FCM token from dashboard response for optimization
      final backendFcmToken = _cachedUser?['fcm_token'] as String?;
      debugPrint('🔍 Dashboard response FCM token: ${backendFcmToken?.isNotEmpty == true ? "${backendFcmToken!.substring(0, 20)}..." : "empty/null"}');
      
      // Use optimized FCM token generation with backend validation
      _generateFcmToken(backendFcmToken);
    }
  }

  Widget _buildDashboardContent(BuildContext context, DashboardState state) {
    final bool isLoading = state is DashboardLoading;
    final bool isError = state is DashboardError;

    // Use cached data if available, otherwise use empty defaults
    final user = _cachedUser ?? <String, dynamic>{};
    final faceScan = _cachedFaceScan ?? <String, dynamic>{};
    final skinScore = _cachedSkinScore ?? <String, dynamic>{};
    final progressSummary = _cachedProgressSummary ?? <String, dynamic>{};
    final dailyRoutine = _cachedDailyRoutine ?? <String, dynamic>{};
    final imageGallery = _cachedImageGallery ?? <Map<String, dynamic>>[];
    final recommendedProducts = _cachedRecommendedProducts ?? <Map<String, dynamic>>[];
    final latestConditionResult = _cachedLatestConditionResult;
    final latestSkinReportId = _latestSkinReportId ?? '';
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
                          latestSkinReportId,
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
    String latestSkinReportId,
  ) {




    return SliverPadding(
      padding: const EdgeInsets.only(left: 20,right:20, bottom:20),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isError || isLoading)
              _buildLoadingErrorSection(context, isLoading, isError),
            SizedBox(height: isError || isLoading ? 10 : 30),
            _memoizedWidget(
              cacheKey: '${faceScan.hashCode}_${skinScore.hashCode}',
              child: _buildMainCardsRow(faceScan, skinScore),
            ),
            _memoizedWidget(
              cacheKey: '${latestConditionResult.hashCode}',
             child: ConditionsSection(
                latestConditionResult: latestConditionResult,
                onConditionTap: (conditionName) {
                  logJson(latestConditionResult);
                  debugPrint(conditionName);
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (context) => ScanResultDetailsScreen(
                        reportId: latestSkinReportId,
                        condition: conditionName,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _memoizedWidget(
              cacheKey: progressSummary.hashCode,
              child: _buildProgressSummarySection(progressSummary),
            ),
            _memoizedWidget(
              cacheKey: '${dailyRoutine.hashCode}_$isLoading',
              child: _buildDailyRoutineSection(dailyRoutine, isLoading),
            ),
            _memoizedWidget(
              cacheKey: '${imageGallery.hashCode}_$isLoading',
              child: _buildImageGallerySection(imageGallery, isLoading),
            ),
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
    return RepaintBoundary(
      child: IntrinsicHeight(
        child: Column(
          spacing: 10,
          // crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: RepaintBoundary(
                child: FaceScanCard(
                  faceScan: faceScan,
                  onTap: widget.onFaceScanTap,
                ),
              ),
            ),
            const SizedBox(width: 26),
            Expanded(
              child: RepaintBoundary(
                child: SkinScoreCard(skinScore: skinScore),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummarySection(Map<String, dynamic> progressSummary) {
    return RepaintBoundary(
      child: Column(
        children: [
          const SectionHeader(
            heading: 'Progress Summary',
            showButton: false,
          ),
          RepaintBoundary(
            child: ProgressSummaryChart(
              progressSummary: progressSummary,
              height: 280,
              showPointsAndLabels: false,
            ),
          ),
        ],
      ),
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
    return RepaintBoundary(
      child: Column(
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
          RepaintBoundary(
            child: ImageGallerySection(
              imageGallery: imageGallery,
              isLoading: isLoading,
              onShowAll: () {
                Navigator.of(context, rootNavigator: true).pushNamed(
                  AppRoutes.dashboardImageGallery,
                  arguments: {'images': imageGallery},
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Removed _buildRecommendedProductsSection as it's currently commented out
  // Can be restored if needed in the future

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