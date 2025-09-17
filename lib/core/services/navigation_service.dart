import 'package:flutter/material.dart';
import '../config/constants/routes.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static NavigatorState? get navigator => navigatorKey.currentState;

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
      debugPrint('❌ NavigationService: Navigator not available');
      return Future.value(null);
    }

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