import 'package:flutter/material.dart';
import '../pages/user_search_page.dart';

/// Helper class for easy navigation to UserSearchPage
/// 
/// This integration class provides multiple ways to navigate to the UserSearchPage
/// without needing to pass any parameters. The page is completely self-contained.
/// 
/// Usage Examples:
/// 
/// 1. From an AppBar action:
/// ```dart
/// AppBar(
///   actions: [
///     IconButton(
///       icon: Icon(Icons.search),
///       onPressed: () => UserSearchPageIntegration.navigateTo(context),
///     ),
///   ],
/// )
/// ```
/// 
/// 2. From a FloatingActionButton:
/// ```dart
/// FloatingActionButton(
///   onPressed: () => UserSearchPageIntegration.navigateTo(context),
///   child: Icon(Icons.search),
/// )
/// ```
/// 
/// 3. From a Button or ListTile:
/// ```dart
/// ElevatedButton(
///   onPressed: () => UserSearchPageIntegration.navigateTo(context),
///   child: Text('Search Users'),
/// )
/// ```
/// 
/// 4. Using named routes in main.dart:
/// ```dart
/// MaterialApp(
///   routes: {
///     UserSearchPageIntegration.routeName: (context) => UserSearchPageIntegration.route(),
///   },
/// )
/// ```
class UserSearchPageIntegration extends StatelessWidget {
  const UserSearchPageIntegration({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserSearchPage();
  }

  /// Navigate to UserSearchPage from any screen
  /// 
  /// Example:
  /// ```dart
  /// UserSearchPageIntegration.navigateTo(context);
  /// ```
  static void navigateTo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserSearchPageIntegration(),
      ),
    );
  }

  /// Navigate to UserSearchPage and replace current screen
  /// 
  /// Example:
  /// ```dart
  /// UserSearchPageIntegration.navigateAndReplace(context);
  /// ```
  static void navigateAndReplace(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const UserSearchPageIntegration(),
      ),
    );
  }

  /// Route name for named navigation
  static const String routeName = '/user-search';
  
  /// Create route for named navigation
  /// 
  /// Add this to your main.dart routes:
  /// ```dart
  /// routes: {
  ///   UserSearchPageIntegration.routeName: (context) => UserSearchPageIntegration.route(),
  /// }
  /// ```
  static Route<dynamic> route() {
    return MaterialPageRoute(
      builder: (context) => const UserSearchPageIntegration(),
      settings: const RouteSettings(name: routeName),
    );
  }

  /// Navigate using named route
  /// 
  /// Example:
  /// ```dart
  /// UserSearchPageIntegration.navigateToNamed(context);
  /// ```
  static void navigateToNamed(BuildContext context) {
    Navigator.of(context).pushNamed(routeName);
  }
}
