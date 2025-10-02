import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/features/error_pricing/screens/not_found_screen.dart';
import 'package:nepika/features/products/main.dart';
import 'package:nepika/features/settings/main.dart';
import 'package:nepika/features/routine/main.dart';
import 'package:nepika/features/notifications/bloc/notification_bloc.dart';
import 'package:nepika/features/notifications/bloc/notification_event.dart';

import 'screens/dashboard_screen.dart';
import 'screens/set_reminder_screen.dart';
import 'components/scrollable_page_wrapper.dart';
import 'widgets/dashboard_navbar.dart';

// Export BLoCs for dashboard feature independence
export 'bloc/dashboard_bloc.dart';
export 'bloc/dashboard_event.dart';
export 'bloc/dashboard_state.dart';
export 'bloc/auth/auth_bloc.dart';
export 'bloc/auth/auth_event.dart';
export 'bloc/auth/auth_state.dart';
export 'bloc/onboarding/onboarding_bloc.dart';
export 'bloc/onboarding/onboarding_event.dart';
export 'bloc/onboarding/onboarding_state.dart';
export 'utils/onboarding_validator.dart';
export 'utils/visibility_evaluator.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class DashboardWithNotifications extends StatelessWidget {
  const DashboardWithNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationBloc()..add(const ConnectToNotificationStream()),
      child: const Dashboard(),
    );
  }
}

class _DashboardState extends State<Dashboard> 
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String _currentRoute = AppRoutes.dashboardHome;
  
  // Navigation bar auto-hide functionality
  late AnimationController _navBarAnimationController;
  late Animation<double> _navBarAnimation;
  bool _isNavBarVisible = true;
  final double _scrollThreshold = 5.0;

  // Map routes to navbar indices
  static const Map<String, int> _routeToIndex = {
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
    _initializeNavBarAnimation();
  }

  void _initializeNavBarAnimation() {
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _navBarAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Try to get the NotificationBloc if available
    try {
      final notificationBloc = context.read<NotificationBloc>();
      
      switch (state) {
        case AppLifecycleState.resumed:
          // App is in foreground - connect to SSE
          notificationBloc.add(const ConnectToNotificationStream());
          break;
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
          // App is in background or inactive - disconnect to save battery
          notificationBloc.add(const DisconnectFromNotificationStream());
          break;
        case AppLifecycleState.detached:
          // App is being terminated
          notificationBloc.add(const DisconnectFromNotificationStream());
          break;
        case AppLifecycleState.hidden:
          // App is hidden - disconnect to save battery
          notificationBloc.add(const DisconnectFromNotificationStream());
          break;
      }
    } catch (e) {
      // NotificationBloc not found in context, which is fine for some routes
      // Do nothing
    }
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
    }
  }

  void _handleScroll(double scrollOffset, double scrollDelta) {
    if (scrollDelta.abs() < _scrollThreshold) return;
    
    final bool shouldShowNavBar = scrollDelta > 0 
        ? scrollOffset <= 20
        : true;
    
    if (shouldShowNavBar != _isNavBarVisible) {
      _isNavBarVisible = shouldShowNavBar;
      
      if (_isNavBarVisible) {
        _navBarAnimationController.forward();
      } else {
        _navBarAnimationController.reverse();
      }
    }
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
                _resetNavBarVisibility();
                setState(() => _currentRoute = route);
              }
            }),
          ],
          onGenerateRoute: _generateRoute,
        ),
        bottomNavigationBar: _buildAnimatedNavBar(),
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.dashboardHome:
        return _buildScrollableRoute(
          settings: RouteSettings(name: AppRoutes.dashboardHome),
          child: DashboardScreen(
            token: '',
            onFaceScanTap: () => Navigator.of(context).pushNamed(AppRoutes.cameraScanGuidence),
          ),
        );
      case AppRoutes.dashboardExplore:
        return MaterialPageRoute(
          settings: RouteSettings(name: AppRoutes.dashboardExplore),
          builder: (_) => const Placeholder(),
        );
      case AppRoutes.dashboardTodaysRoutine:
        return _buildScrollableRoute(
          settings: RouteSettings(name: AppRoutes.dashboardTodaysRoutine),
          child: const RoutineBlocProvider(
            child: DailyRoutineScreen(),
          ),
        );
      case AppRoutes.dashboardEditRoutine:
        return _buildScrollableRoute(
          settings: RouteSettings(name: AppRoutes.dashboardEditRoutine),
          child: const RoutineBlocProvider(
            child: EditRoutineScreen(),
          ),
        );
      case AppRoutes.dashboardAddRoutine:
        return _buildScrollableRoute(
          settings: RouteSettings(name: AppRoutes.dashboardAddRoutine),
          child: const RoutineBlocProvider(
            child: AddRoutineScreen(),
          ),
        );
      case AppRoutes.dashboardReminderSettings:
        return _buildScrollableRoute(
          settings: RouteSettings(name: AppRoutes.dashboardReminderSettings),
          child: const ReminderSettings(),
        );
      case AppRoutes.dashboardAllProducts:
        return _buildScrollableRoute(
          settings: RouteSettings(name: AppRoutes.dashboardAllProducts),
          child: const ProductsScreen(),
        );
      case AppRoutes.dashboardSettings:
        return _buildScrollableRoute(
          settings: RouteSettings(name: AppRoutes.dashboardSettings),
          child: const MainSettingsScreen(),
        );
      case AppRoutes.dashboardSpecificProduct:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildScrollableRoute(
          settings: RouteSettings(name: AppRoutes.dashboardSpecificProduct),
          child: ProductInfoScreen(productId: args?['productId'] ?? ''),
        );
      case AppRoutes.notificationsAndSettings:
        return _buildScrollableRoute(
          settings: RouteSettings(name: AppRoutes.notificationsAndSettings),
          child: const NotificationsSettingsScreen(),
        );
      case AppRoutes.setupNotifications:
        return _buildScrollableRoute(
          settings: RouteSettings(name: AppRoutes.setupNotifications),
          child: const SetupNotificationsScreen(),
        );
      case AppRoutes.communityAndEngagement:
        return _buildScrollableRoute(
          settings: RouteSettings(name: AppRoutes.communityAndEngagement),
          child: const CommunitySettingsScreen(),
        );
      case AppRoutes.helpAndSupport:
        return _buildScrollableRoute(
          settings: RouteSettings(name: AppRoutes.helpAndSupport),
          child: const HelpSupportScreen(),
        );
      default:
        return MaterialPageRoute(builder: (_) => const NotFoundScreen());
    }
  }

  MaterialPageRoute _buildScrollableRoute({
    required RouteSettings settings,
    required Widget child,
  }) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => ScrollablePageWrapper(
        onScroll: _handleScroll,
        child: child,
      ),
    );
  }

  Widget _buildAnimatedNavBar() {
    return AnimatedBuilder(
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
    );
  }
}

class _DashboardRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final Function(String) onRouteChanged;

  _DashboardRouteObserver({required this.onRouteChanged});

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute?.settings.name != null) {
      onRouteChanged(previousRoute!.settings.name!);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      onRouteChanged(route.settings.name!);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name != null) {
      onRouteChanged(newRoute!.settings.name!);
    }
  }
}