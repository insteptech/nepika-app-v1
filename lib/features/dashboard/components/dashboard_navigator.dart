import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/di/injection_container.dart' as di;
import 'package:nepika/features/error_pricing/screens/not_found_screen.dart';
import 'package:nepika/features/reminders/bloc/reminder_bloc.dart';
import '../screens/set_reminder_screen.dart';
// import 'package:nepika/presentation/pages/pricing_and_error/not_found.dart';
import 'package:nepika/features/routine/main.dart';
import 'package:nepika/features/products/main.dart';
import 'package:nepika/features/settings/main.dart';
import '../screens/dashboard_screen.dart';
import '../widgets/dashboard_navbar.dart';
import 'scrollable_page_wrapper.dart';

class DashboardNavigator extends StatefulWidget {
  const DashboardNavigator({super.key});

  @override
  State<DashboardNavigator> createState() => _DashboardNavigatorState();
}

class _DashboardNavigatorState extends State<DashboardNavigator>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String _currentRoute = AppRoutes.dashboardHome;
  Timer? _routeCheckTimer;

  // Navigation bar auto-hide functionality
  late AnimationController _navBarAnimationController;
  late Animation<double> _navBarAnimation;
  bool _isNavBarVisible = true;
  final double _scrollThreshold = 5.0;

  // Map routes to navbar indices
  final Map<String, int> _routeToIndex = {
    AppRoutes.dashboardHome: 0,
    AppRoutes.dashboardExplore: 1,
    AppRoutes.dashboardTodaysRoutine: 2,
    AppRoutes.dashboardAllProducts: 3,
    AppRoutes.dashboardSettings: 4,
    AppRoutes.dashboardEditRoutine: 2,
    AppRoutes.dashboardAddRoutine: 2,
    AppRoutes.dashboardSpecificProduct: 3,
    AppRoutes.dashboardReminderSettings: 4,
    AppRoutes.notificationsAndSettings: 4,
    AppRoutes.setupNotifications: 4,
    AppRoutes.communityAndEngagement: 4,
    AppRoutes.helpAndSupport: 4,
  };

  int get _selectedIndex => _routeToIndex[_currentRoute] ?? 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initializeNavigationBar();
    _startRouteCheckTimer();
  }

  void _initializeNavigationBar() {
    _navBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _navBarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _navBarAnimationController,
      curve: Curves.easeInOut,
    ));

    _navBarAnimationController.forward();
  }

  void _startRouteCheckTimer() {
    _routeCheckTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _updateCurrentRoute(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routeCheckTimer?.cancel();
    _navBarAnimationController.dispose();
    super.dispose();
  }

  void _onNavBarTap(int index, String route) {
    if (route == AppRoutes.cameraScanGuidence) {
      Navigator.of(context).pushNamed(AppRoutes.cameraScanGuidence);
      return;
    }

    _resetNavBarVisibility();
    setState(() {
      _currentRoute = route;
    });
    _navigatorKey.currentState?.pushNamed(route);
  }

  void _resetNavBarVisibility() {
    if (!_isNavBarVisible) {
      setState(() {
        _isNavBarVisible = true;
      });
      _navBarAnimationController.forward();
      debugPrint('Navbar reset to visible due to screen change');
    }
  }

  void _updateCurrentRoute() {
    final currentContext = _navigatorKey.currentContext;
    if (currentContext != null) {
      final route = ModalRoute.of(currentContext);
      if (route?.settings.name != null && route!.settings.name != _currentRoute) {
        debugPrint('Route changed from $_currentRoute to ${route.settings.name}');
        _resetNavBarVisibility();
        setState(() {
          _currentRoute = route.settings.name!;
        });
      }
    }
  }

  void _handleScroll(double scrollOffset, double scrollDelta) {
    if (scrollDelta.abs() < _scrollThreshold) return;

    final bool shouldShowNavBar = scrollDelta > 0
        ? scrollOffset <= 20 // Show when near top
        : true; // Always show when scrolling up

    if (shouldShowNavBar != _isNavBarVisible) {
      _isNavBarVisible = shouldShowNavBar;

      if (_isNavBarVisible) {
        _navBarAnimationController.forward();
      } else {
        _navBarAnimationController.reverse();
      }
    }

    // Track scroll offset for navigation bar visibility
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        body: Stack(
          children: [
            Navigator(
              key: _navigatorKey,
              initialRoute: AppRoutes.dashboardHome,
              observers: [
                _DashboardRouteObserver(
                  onRouteChanged: (route) {
                    if (mounted && _currentRoute != route) {
                      _resetNavBarVisibility();
                      setState(() => _currentRoute = route);
                    }
                  },
                ),
              ],
              onGenerateRoute: _generateRoute,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildAnimatedNavBar(),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePopInvoked(bool didPop, dynamic result) async {
    if (!didPop) {
      final navigator = _navigatorKey.currentState;
      if (navigator != null && navigator.canPop()) {
        navigator.pop();
        Future.delayed(
            const Duration(milliseconds: 100), _updateCurrentRoute);
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  Widget _buildAnimatedNavBar() {
    const double strictNavBarHeight = 80.0; // Strict 80px height as requested
    
    return AnimatedBuilder(
      animation: _navBarAnimation,
      builder: (context, child) {
        return Container(
          height: _navBarAnimation.value * strictNavBarHeight,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: Transform.translate(
            offset: Offset(0, (1 - _navBarAnimation.value) * strictNavBarHeight),
            child: SizedBox(
              height: strictNavBarHeight,
              child: DashboardNavBar(
                selectedIndex: _selectedIndex,
                onNavBarTap: _onNavBarTap,
                height: strictNavBarHeight, // Force exact 80px height
                scanButtonSize: 60.0, // Increase scan button to fit 80px height better
              ),
            ),
          ),
        );
      },
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.dashboardHome:
        return _createPageRoute(
          settings,
          ScrollablePageWrapper(
            onScroll: _handleScroll,
            child: DashboardScreen(
              token: '',
              onFaceScanTap: () => Navigator.of(context)
                  .pushNamed(AppRoutes.cameraScanGuidence),
            ),
          ),
        );
      case AppRoutes.dashboardExplore:
        return _createPageRoute(settings, const Placeholder());
      case AppRoutes.dashboardTodaysRoutine:
        return _createPageRoute(
          settings,
          ScrollablePageWrapper(
            onScroll: _handleScroll,
            child: const RoutineBlocProvider(
              child: DailyRoutineScreen(),
            ),
          ),
        );
      case AppRoutes.dashboardEditRoutine:
        return _createPageRoute(
          settings,
          ScrollablePageWrapper(
            onScroll: _handleScroll,
            child: const RoutineBlocProvider(
              child: EditRoutineScreen(),
            ),
          ),
        );
      case AppRoutes.dashboardAddRoutine:
        return _createPageRoute(
          settings,
          ScrollablePageWrapper(
            onScroll: _handleScroll,
            child: const RoutineBlocProvider(
              child: AddRoutineScreen(),
            ),
          ),
        );
      case AppRoutes.dashboardReminderSettings:
        return _createPageRoute(
          settings,
          ScrollablePageWrapper(
            onScroll: _handleScroll,
            child: BlocProvider(
              create: (context) => di.ServiceLocator.get<ReminderBloc>(),
              child: const ReminderSettings(),
            ),
          ),
        );
      case AppRoutes.dashboardAllProducts:
        return _createPageRoute(
          settings,
          ScrollablePageWrapper(
            onScroll: _handleScroll,
            child: const ProductsScreen(),
          ),
        );
      case AppRoutes.dashboardSettings:
        return _createPageRoute(
          settings,
          ScrollablePageWrapper(
            onScroll: _handleScroll,
            child: const MainSettingsScreen(),
          ),
        );
      case AppRoutes.dashboardSpecificProduct:
        final args = settings.arguments as Map<String, dynamic>?;
        return _createPageRoute(
          settings,
          ScrollablePageWrapper(
            onScroll: _handleScroll,
            child: ProductInfoScreen(productId: args?['productId'] ?? ''),
          ),
        );
      case AppRoutes.notificationsAndSettings:
        return _createPageRoute(
          settings,
          ScrollablePageWrapper(
            onScroll: _handleScroll,
            child: const NotificationsSettingsScreen(),
          ),
        );
      case AppRoutes.setupNotifications:
        return _createPageRoute(
          settings,
          ScrollablePageWrapper(
            onScroll: _handleScroll,
            child: const SetupNotificationsScreen(),
          ),
        );
      case AppRoutes.communityAndEngagement:
        return _createPageRoute(
          settings,
          ScrollablePageWrapper(
            onScroll: _handleScroll,
            child: const CommunitySettingsScreen(),
          ),
        );
      case AppRoutes.helpAndSupport:
        return _createPageRoute(
          settings,
          ScrollablePageWrapper(
            onScroll: _handleScroll,
            child: const HelpSupportScreen(),
          ),
        );
      default:
        return MaterialPageRoute(builder: (_) => const NotFoundScreen());
    }
  }

  MaterialPageRoute _createPageRoute(RouteSettings settings, Widget child) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => child,
    );
  }
}

class _DashboardRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final Function(String) onRouteChanged;

  _DashboardRouteObserver({required this.onRouteChanged});

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null && previousRoute.settings.name != null) {
      debugPrint('Route popped: returning to ${previousRoute.settings.name}');
      onRouteChanged(previousRoute.settings.name!);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      debugPrint('Route pushed: navigating to ${route.settings.name}');
      onRouteChanged(route.settings.name!);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null && newRoute.settings.name != null) {
      debugPrint('Route replaced: now showing ${newRoute.settings.name}');
      onRouteChanged(newRoute.settings.name!);
    }
  }
}