import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/data/dashboard/repositories/dashboard_repository.dart';
import 'package:nepika/presentation/routine/widgets/daily_routine.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/face_scan_card.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/greeting_section.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/image_gallery.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/progress_summary_chart.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/recomended_products.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/skin_score_card.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/section_header.dart';
import 'package:nepika/presentation/pages/dashboard/widgets/conditions_section.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../bloc/dashboard/dashboard_event.dart';
import '../../bloc/dashboard/dashboard_state.dart';

class DashboardPage extends StatefulWidget {
  final String? token;
  final VoidCallback? onFaceScanTap;
  final void Function(String route)? onNavigate;

  const DashboardPage({
    super.key,
    this.token,
    this.onFaceScanTap,
    this.onNavigate,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with WidgetsBindingObserver, RouteAware {
  late DashboardBloc _dashboardBloc;
  String? _token;
  bool _isInitialized = false;
  DateTime? _lastRefreshTime;
  bool _hasNavigatedAway = false;
  final FocusNode _focusNode = FocusNode();
  bool _isPageVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dashboardBloc = DashboardBloc(DashboardRepositoryImpl(ApiBase()));
    
    // Add focus listener for additional refresh trigger
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _isInitialized && _token != null && _shouldRefresh()) {
        debugPrint('Dashboard: Focus gained, refreshing data');
        _refreshDashboard();
      }
    });
    
    _loadTokenAndFetch();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _isInitialized && _token != null) {
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
      final routeObserver = observers.whereType<RouteObserver<PageRoute>>().firstOrNull;
      if (routeObserver != null) {
        routeObserver.subscribe(this, route);
      }
    }
    
    // Additional refresh trigger when dependencies change
    if (_hasNavigatedAway && _isInitialized && _token != null && _shouldRefresh()) {
      debugPrint('Dashboard: Dependencies changed, refreshing after navigation');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshDashboard();
        _hasNavigatedAway = false;
      });
    }
  }

  @override
  void didPopNext() {
    // Called when a route has been popped off, and the current route shows up
    debugPrint('Dashboard: Returned from another screen, refreshing data');
    _isPageVisible = true;
    _hasNavigatedAway = false;
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
    _hasNavigatedAway = true;
    _isPageVisible = false;
  }

  bool _shouldRefresh() {
    final now = DateTime.now();
    if (_lastRefreshTime == null) {
      return true;
    }
    // Refresh if more than 1 second has passed since last refresh (reduced for better responsiveness)
    return now.difference(_lastRefreshTime!).inSeconds > 1;
  }

  Future<void> _loadTokenAndFetch() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final accessToken = sharedPrefs.getString(AppConstants.accessTokenKey);

    setState(() {
      _token = accessToken ?? widget.token;
      _isInitialized = true;
    });

    if (_token != null) {
      _dashboardBloc.add(DashboardRequested(_token!));
    }
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
    final navigator = Navigator.of(context);
    final observers = navigator.widget.observers;
    final routeObserver = observers.whereType<RouteObserver<PageRoute>>().firstOrNull;
    if (routeObserver != null) {
      routeObserver.unsubscribe(this);
    }
    _dashboardBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Add a post-frame callback to refresh when widget is rebuilt after navigation
    if (_isInitialized && _token != null && _hasNavigatedAway) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_shouldRefresh()) {
          debugPrint('Dashboard: Build after navigation, refreshing data');
          _refreshDashboard();
          _hasNavigatedAway = false;
        }
      });
    }
    
    return BlocProvider.value(
      value: _dashboardBloc,
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          // Default values
          Map<String, dynamic> user = {};
          Map<String, dynamic> faceScan = {};
          Map<String, dynamic> skinScore = {};
          Map<String, dynamic> progressSummary = {};
          Map<String, dynamic> dailyRoutine = {};
          List<Map<String, dynamic>> imageGallery = [];
          List<Map<String, dynamic>> recommendedProducts = [];
          Map<String, dynamic>? latestConditionResult;

          bool isLoading = state is DashboardLoading;
          bool isError = state is DashboardError;

          if (state is DashboardLoaded) {
            final dashboardData = state.dashboardData.data;
            user = dashboardData['user'] ?? {};
            faceScan = dashboardData['faceScan'] ?? {};
            skinScore = dashboardData['skinScore'] ?? {};
            progressSummary = dashboardData['progressSummary'] ?? {};
            dailyRoutine = dashboardData['dailyRoutine'] ?? {};
            imageGallery = List<Map<String, dynamic>>.from(
              dashboardData['imageGallery'] ?? [],
            );
            recommendedProducts = List<Map<String, dynamic>>.from(
              dashboardData['recommendedProducts'] ?? [],
            );
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
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              sliver: SliverToBoxAdapter(
                                child: const SizedBox(height: 0),
                              ),
                            ),
                            
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _SliverAppBarDelegate(
                                minHeight: 55,
                                maxHeight: 56,
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
                            ),

                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              sliver: SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                              if (isError || isLoading)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      isLoading
                                          ? 'Loading...'
                                          : 'Failed to load dashboard data',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                  ),
                                ),

                              isError || isLoading
                                  ? const SizedBox(height: 10)
                                  : const SizedBox(height: 30),

                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 170,
                                      child: FaceScanCard(
                                        faceScan: faceScan,
                                        onTap: widget.onFaceScanTap,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: SizedBox(
                                      height: 170,
                                      child: SkinScoreCard(skinScore: skinScore),
                                    ),
                                  ),
                                ],
                              ),


                              
                              ConditionsSection(
                                latestConditionResult: latestConditionResult,
                                onConditionTap: (conditionName) {
                                  
                                  final arguments = {
                                    'skinScore': skinScore,
                                    'conditionInfo': conditionName
                                  };
                                  Navigator.of(
                                    context,
                                    rootNavigator: true
                                  ).pushNamed(AppRoutes.conditionDetailsPage, arguments: arguments);
                                },
                              ),

                              const SizedBox(height: 10),

                              SectionHeader(
                                heading: 'Progress Summary',
                                showButton: false,
                              ),

                              ProgressSummaryChart(
                                progressSummary: progressSummary,
                                height: 280,
                                showPointsAndLabels: false,
                              ),

                              RepaintBoundary(
                                child: SectionHeader(
                                  heading: 'Daily Routine',
                                  showButton: true,
                                  buttonText: 'View all',
                                  onButtonPressed: () {
                                    Navigator.of(
                                      context,
                                    ).pushNamed(AppRoutes.dashboardTodaysRoutine);
                                  },
                                  buttonLoading: isLoading,
                                ),
                              ),

                              DailyRoutineSection(dailyRoutine: dailyRoutine),

                              SectionHeader(
                                heading: 'Image Gallery',
                                showButton: true,
                                buttonText: 'View all',
                                onButtonPressed: () {
                                  if (widget.onNavigate != null) {
                                    widget.onNavigate!('/image_gallery');
                                  }
                                },
                                buttonLoading: isLoading,
                              ),

                              ImageGallerySection(imageGallery: imageGallery, token: _token!),

                              SectionHeader(
                                heading: 'Recommend Products',
                                showButton: true,
                                buttonText: 'View all',
                                onButtonPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.dashboardAllProducts);
                                },
                                buttonLoading: isLoading,
                              ),

                                      RecommendedProductsSection(
                                        products: recommendedProducts,
                                        scrollDirection: Axis.horizontal,
                                        showTag: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                        ),
                      ),
              ),
            ),
              ), // Close Focus widget
          );
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
