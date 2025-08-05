
import 'package:nepika/presentation/settings/pages/components/community_and_engagement_page.dart';

import 'package:nepika/presentation/settings/pages/components/help_and_support_page.dart';
import 'package:nepika/presentation/settings/pages/components/notifications_and_settings_page.dart';
import 'package:nepika/presentation/settings/pages/components/setup_notifications_page.dart';
// import 'package:nepika/presentation/settings/pages/settings_page.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nepika/core/constants/routes.dart';
import 'package:nepika/presentation/pages/dashboard/set_reminder_page.dart';
import 'package:nepika/presentation/pages/pricing_and_error/not_found.dart';
import 'package:nepika/presentation/routine/pages/add_routine.dart';
import 'package:nepika/presentation/pages/dashboard/dashboard_page.dart';
import 'package:nepika/presentation/routine/pages/edit_routine.dart';
import 'package:nepika/presentation/pages/dashboard/product_info.dart';
import 'package:nepika/presentation/pages/dashboard/products_page.dart';
import 'package:nepika/presentation/routine/pages/daily_routine_page.dart';
import 'package:nepika/presentation/settings/pages/settings_page.dart';
// import 'package:nepika/presentation/pages/first_scan/camera_scan_screen.dart';
import 'widgets/dashboard_navbar.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String _currentRoute = AppRoutes.dashboardHome;
  Timer? _routeCheckTimer;

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
  };

  int get _selectedIndex => _routeToIndex[_currentRoute] ?? 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Periodic check for route changes (as backup)
    _routeCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _updateCurrentRoute();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routeCheckTimer?.cancel();
    super.dispose();
  }

  void _onNavBarTap(int index, String route) {
    if (route == AppRoutes.cameraScanGuidence) {
      Navigator.of(context).pushNamed(AppRoutes.cameraScanGuidence);
      return;
    }

    setState(() {
      _currentRoute = route;
    });
    _navigatorKey.currentState?.pushNamed(route);
  }

  void _updateCurrentRoute() {
    // Get the current route from the navigator
    final currentContext = _navigatorKey.currentContext;
    if (currentContext != null) {
      final route = ModalRoute.of(currentContext);
      if (route?.settings.name != null && route!.settings.name != _currentRoute) {
        setState(() {
          _currentRoute = route.settings.name!;
        });
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
                setState(() => _currentRoute = route);
              }
            }),
          ],
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case AppRoutes.dashboardHome:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.dashboardHome),
                  builder: (_) => DashboardPage(
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
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.dashboardTodaysRoutine),
                  builder: (_) => const TodaysRoutine(),
                );
              case AppRoutes.dashboardEditRoutine:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.dashboardEditRoutine),
                  builder: (_) => const EditRoutine(),
                );
              case AppRoutes.dashboardAddRoutine:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.dashboardAddRoutine),
                  builder: (_) => const AddRoutine(),
                );
              case AppRoutes.dashboardReminderSettings:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.dashboardReminderSettings),
                  builder: (_) => const ReminderSettings(),
                );
              case AppRoutes.dashboardAllProducts:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.dashboardAllProducts),
                  builder: (_) => const ProductsPage(),
                );
              case AppRoutes.dashboardSettings:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.dashboardSettings),
                  builder: (_) => const SettingsPage(),
                );
              case AppRoutes.dashboardSpecificProduct:
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.dashboardSpecificProduct),
                  builder: (_) => ProductInfoPage(productId: args?['productId'] ?? ''),
                );
              case AppRoutes.notificationsAndSettings:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.notificationsAndSettings),
                  builder: (_) => const NotificationsAndSettings(),
                );
              case AppRoutes.setupNotifications:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.setupNotifications),
                  builder: (_) => const SetupNotificationsPage(),
                );
              case AppRoutes.communityAndEngagement:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.communityAndEngagement),
                  builder: (_) => const CommunityAndEngagement(),
                );
              case AppRoutes.helpAndSupport:
                return MaterialPageRoute(
                  settings: RouteSettings(name: AppRoutes.helpAndSupport),
                  builder: (_) => const HelpAndSupport(),
                );
              default:
                return MaterialPageRoute(builder: (_) => const NotFound());
            }
          },
        ),
        bottomNavigationBar: DashboardNavBar(
          selectedIndex: _selectedIndex,
          onNavBarTap: _onNavBarTap,
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
      onRouteChanged(previousRoute.settings.name!);
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
    if (newRoute != null && newRoute.settings.name != null) {
      onRouteChanged(newRoute.settings.name!);
    }
  }
}