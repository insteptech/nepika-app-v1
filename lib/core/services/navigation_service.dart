import 'package:flutter/material.dart';
import '../config/constants/routes.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> dashboardNavigatorKey = GlobalKey<NavigatorState>();
  
  static NavigatorState? get navigator => navigatorKey.currentState;

  // Pending navigation storage for when navigator isn't ready yet
  static String? _pendingRoute;
  static Object? _pendingArguments;
  
  // Duplicate navigation prevention
  static String? _lastNavigatedRoute;
  static DateTime? _lastNavigationTime;
  static const Duration _navigationCooldown = Duration(seconds: 2);

  /// Check if we should skip this navigation to prevent duplicates
  static bool _shouldSkipDuplicateNavigation(String routeName) {
    if (_lastNavigatedRoute == routeName && _lastNavigationTime != null) {
      final elapsed = DateTime.now().difference(_lastNavigationTime!);
      if (elapsed < _navigationCooldown) {
        debugPrint('⚠️ NavigationService: Skipping duplicate navigation to $routeName (last: ${elapsed.inMilliseconds}ms ago)');
        return true;
      }
    }
    return false;
  }

  /// Record that we navigated to a route
  static void _recordNavigation(String routeName) {
    _lastNavigatedRoute = routeName;
    _lastNavigationTime = DateTime.now();
    debugPrint('📍 NavigationService: Recorded navigation to $routeName');
  }

  /// Check and execute any pending navigation (call this from dashboard init)
  static void executePendingNavigation() {
    if (_pendingRoute != null && navigator != null) {
      final route = _pendingRoute!;
      final args = _pendingArguments;
      
      // Clear pending before navigation to prevent re-execution
      _pendingRoute = null;
      _pendingArguments = null;
      
      // Check for duplicate
      if (_shouldSkipDuplicateNavigation(route)) {
        return;
      }
      
      debugPrint('🚀 NavigationService: Executing pending navigation to $route');
      _recordNavigation(route);
      navigator!.pushNamed(route, arguments: args);
    }
  }

  /// Check if there's pending navigation
  static bool get hasPendingNavigation => _pendingRoute != null;

  static void navigateCameraScam() {
    if (navigator == null) {
      debugPrint('❌ NavigationService: Navigator not available');
      return;
    }

    // Clear the entire navigation stack and go to login
    navigator!.pushNamed(
      AppRoutes.cameraScanGuidence,
      // (route) => false, // Remove all previous routes
    );
    
    debugPrint('🚪 NavigationService: Navigated to login and cleared stack');
  }
  static void navigateToLogin() {
    if (navigator == null) {
      debugPrint('❌ NavigationService: Navigator not available');
      return;
    }

    // Clear the entire navigation stack and go to login
    navigator!.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false, // Remove all previous routes
    );
    
    debugPrint('🚪 NavigationService: Navigated to login and cleared stack');
  }

  static void navigateToLoginWithReplacement() {
    if (navigator == null) {
      debugPrint('❌ NavigationService: Navigator not available');
      return;
    }

    // Replace current route with login
    navigator!.pushReplacementNamed(AppRoutes.login);
    debugPrint('🚪 NavigationService: Replaced current route with login');
  }

  static Future<T?> navigateTo<T extends Object?>(String routeName, {Object? arguments}) {
    if (navigator == null) {
      debugPrint('⏳ NavigationService: Navigator not available, storing pending navigation to $routeName');
      // Store for later execution when navigator becomes available
      _pendingRoute = routeName;
      _pendingArguments = arguments;
      return Future.value(null);
    }
    
    // Check for duplicate navigation
    if (_shouldSkipDuplicateNavigation(routeName)) {
      return Future.value(null);
    }

    _recordNavigation(routeName);
    return navigator!.pushNamed<T>(routeName, arguments: arguments);
  }

  static void goBack<T extends Object?>([T? result]) {
    if (navigator == null) {
      debugPrint('❌ NavigationService: Navigator not available');
      return;
    }

    navigator!.pop<T>(result);
  }

  static bool canGoBack() {
    if (navigator == null) {
      debugPrint('❌ NavigationService: Navigator not available');
      return false;
    }

    return navigator!.canPop();
  }
}