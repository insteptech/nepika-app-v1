
import 'package:nepika/presentation/pages/products/product_info_page.dart';
import 'package:nepika/presentation/settings/pages/components/community_and_engagement_page.dart';

import 'package:nepika/presentation/settings/pages/components/help_and_support_page.dart';
import 'package:nepika/presentation/settings/pages/components/notifications_and_settings_page.dart';
import 'package:nepika/presentation/settings/pages/components/setup_notifications_page.dart';
// import 'package:nepika/presentation/settings/pages/settings_page.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/presentation/pages/dashboard/set_reminder_page.dart';
import 'package:nepika/presentation/pages/pricing_and_error/not_found.dart';
import 'package:nepika/presentation/routine/pages/add_routine.dart';
import 'package:nepika/presentation/pages/dashboard/dashboard_page.dart';
import 'package:nepika/presentation/routine/pages/edit_routine.dart';
// import 'package:nepika/presentation/pages/dashboard/product_info.dart';
// import 'package:nepika/presentation/pages/dashboard/products_page.dart';
import 'package:nepika/presentation/pages/products/products_page.dart';
import 'package:nepika/presentation/routine/pages/daily_routine_page.dart';
import 'package:nepika/presentation/settings/pages/settings_page.dart';
// import 'package:nepika/presentation/pages/first_scan/camera_scan_screen.dart';
import 'widgets/dashboard_navbar.dart';

// Lightweight wrapper to detect scroll events - optimized for performance
class ScrollablePageWrapper extends StatelessWidget {
  final Widget child;
  final Function(double scrollOffset, double scrollDelta) onScroll;

  const ScrollablePageWrapper({
    super.key,
    required this.child,
    required this.onScroll,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        // Respond to any scroll updates for more responsive navbar behavior
        if (notification is ScrollUpdateNotification && 
            !notification.metrics.outOfRange &&
            notification.scrollDelta != null &&
            notification.scrollDelta!.abs() > 1.0) { // Reduced threshold for better responsiveness
          
          onScroll(notification.metrics.pixels, notification.scrollDelta!);
        }
        return false; // Allow the notification to continue
      },
      child: child,
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver, TickerProviderStateMixin {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String _currentRoute = AppRoutes.dashboardHome;
  Timer? _routeCheckTimer;
  
  // Navigation bar auto-hide functionality - optimized
  late AnimationController _navBarAnimationController;
  late Animation<double> _navBarAnimation;
  bool _isNavBarVisible = true;
  double _lastScrollOffset = 0.0;
  double _scrollThreshold = 5.0;

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
    
    // Initialize navigation bar animation - optimized for instant snapping
    _navBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200), // Quick snapping animation
      vsync: this,
    );
    
    _navBarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _navBarAnimationController,
      curve: Curves.easeInOut, // Smooth but quick animation
    ));
    
    // Start with navbar visible
    _navBarAnimationController.forward();
    
    // Periodic check for route changes (as backup)
    _routeCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _updateCurrentRoute();
    });
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

    // Always reset navbar to visible state on navigation
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
    // Get the current route from the navigator
    final currentContext = _navigatorKey.currentContext;
    if (currentContext != null) {
      final route = ModalRoute.of(currentContext);
      if (route?.settings.name != null && route!.settings.name != _currentRoute) {
        // Always reset navbar visibility when route changes
        debugPrint('Route changed from $_currentRoute to ${route.settings.name}');
        _resetNavBarVisibility();
        
        setState(() {
          _currentRoute = route.settings.name!;
        });
      }
    }
  }

  // Simplified scroll handling with instant snapping behavior
  void _handleScroll(double scrollOffset, double scrollDelta) {
    // Only process scroll events that exceed threshold for smoother performance
    if (scrollDelta.abs() < _scrollThreshold) return;
    
    bool shouldShowNavBar;
    
    // Simple logic: scrolling down hides navbar, scrolling up shows it
    if (scrollDelta > 0) {
      // Scrolling down - hide navbar if we're not at the top
      shouldShowNavBar = scrollOffset <= 20; // Show when near top
    } else {
      // Scrolling up - always show navbar
      shouldShowNavBar = true;
    }
    
    // Update navbar state immediately if changed
    if (shouldShowNavBar != _isNavBarVisible) {
      _isNavBarVisible = shouldShowNavBar;
      
      if (_isNavBarVisible) {
        _navBarAnimationController.forward();
      } else {
        _navBarAnimationController.reverse();
      }
    }
    
    _lastScrollOffset = scrollOffset;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final navigator = _navigatorKey.currentState;
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
            Future.delayed(const Duration(milliseconds: 100), _updateCurrentRoute);
          } else {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        body: Navigator(
          key: _navigatorKey,
          initialRoute: AppRoutes.dashboardHome,
          observers: [
            _DashboardRouteObserver(onRouteChanged: (route) {
              if (mounted && _currentRoute != route) {
                // Reset navbar visibility on any route change
                _resetNavBarVisibility();
                setState(() => _currentRoute = route);
              }
            }),
          ],
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case AppRoutes.dashboardHome:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.dashboardHome),
                  builder: (_) => ScrollablePageWrapper(
                    onScroll: _handleScroll,
                    child: DashboardPage(
                      token: '',
                      onFaceScanTap: () => Navigator.of(context).pushNamed(AppRoutes.cameraScanGuidence),
                    ),
                  ),
                );
              case AppRoutes.dashboardExplore:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.dashboardExplore),
                  builder: (_) => const Placeholder(),
                );
              case AppRoutes.dashboardTodaysRoutine:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.dashboardTodaysRoutine),
                  builder: (_) => ScrollablePageWrapper(
                    onScroll: _handleScroll,
                    child: const TodaysRoutine(),
                  ),
                );
              case AppRoutes.dashboardEditRoutine:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.dashboardEditRoutine),
                  builder: (_) => ScrollablePageWrapper(
                    onScroll: _handleScroll,
                    child: const EditRoutine(),
                  ),
                );
              case AppRoutes.dashboardAddRoutine:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.dashboardAddRoutine),
                  builder: (_) => ScrollablePageWrapper(
                    onScroll: _handleScroll,
                    child: const AddRoutine(),
                  ),
                );
              case AppRoutes.dashboardReminderSettings:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.dashboardReminderSettings),
                  builder: (_) => ScrollablePageWrapper(
                    onScroll: _handleScroll,
                    child: const ReminderSettings(),
                  ),
                );
              case AppRoutes.dashboardAllProducts:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.dashboardAllProducts),
                  builder: (_) => ScrollablePageWrapper(
                    onScroll: _handleScroll,
                    child: const ProductsPage(),
                  ),
                );
              case AppRoutes.dashboardSettings:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.dashboardSettings),
                  builder: (_) => ScrollablePageWrapper(
                    onScroll: _handleScroll,
                    child: const SettingsPage(),
                  ),
                );
              case AppRoutes.dashboardSpecificProduct:
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.dashboardSpecificProduct),
                  builder: (_) => ScrollablePageWrapper(
                    onScroll: _handleScroll,
                    child: ProductInfoPage(productId: args?['productId'] ?? ''),
                  ),
                );
              case AppRoutes.notificationsAndSettings:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.notificationsAndSettings),
                  builder: (_) => ScrollablePageWrapper(
                    onScroll: _handleScroll,
                    child: const NotificationsAndSettings(),
                  ),
                );
              case AppRoutes.setupNotifications:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.setupNotifications),
                  builder: (_) => ScrollablePageWrapper(
                    onScroll: _handleScroll,
                    child: const SetupNotificationsPage(),
                  ),
                );
              case AppRoutes.communityAndEngagement:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.communityAndEngagement),
                  builder: (_) => ScrollablePageWrapper(
                    onScroll: _handleScroll,
                    child: const CommunityAndEngagement(),
                  ),
                );
              case AppRoutes.helpAndSupport:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.helpAndSupport),
                  builder: (_) => ScrollablePageWrapper(
                    onScroll: _handleScroll,
                    child: const HelpAndSupport(),
                  ),
                );
              default:
                return MaterialPageRoute(builder: (_) => const NotFound());
            }
          },
        ),
        bottomNavigationBar: AnimatedBuilder(
          animation: _navBarAnimation,
          builder: (context, child) {
            return SizedBox(
              height: _navBarAnimation.value * kBottomNavigationBarHeight + 50,
              child: ClipRect(
                child: Transform.translate(
                  offset: Offset(0, (1 - _navBarAnimation.value) * kBottomNavigationBarHeight),
                  child: DashboardNavBar(
                    selectedIndex: _selectedIndex,
                    onNavBarTap: _onNavBarTap,
                  ),
                ),
              ),
            );
          },
        ),
      ),
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