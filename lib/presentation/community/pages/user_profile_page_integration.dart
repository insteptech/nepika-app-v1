import 'package:flutter/material.dart';
import 'user_profile.dart';

/// Integration helper for UserProfilePage
/// 
/// This class provides easy navigation methods to the UserProfilePage
/// with proper argument passing and error handling.
class UserProfilePageIntegration {
  
  /// Navigate to UserProfilePage with the given userId
  /// 
  /// Usage:
  /// ```dart
  /// UserProfilePageIntegration.navigateTo(context, 'user123');
  /// ```
  static Future<void> navigateTo(BuildContext context, String userId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserProfilePage(),
        settings: RouteSettings(
          arguments: {'userId': userId},
        ),
      ),
    );
  }

  /// Navigate to UserProfilePage and replace the current route
  /// 
  /// Usage:
  /// ```dart
  /// UserProfilePageIntegration.navigateAndReplace(context, 'user123');
  /// ```
  static Future<void> navigateAndReplace(BuildContext context, String userId) async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const UserProfilePage(),
        settings: RouteSettings(
          arguments: {'userId': userId},
        ),
      ),
    );
  }

  /// Navigate to UserProfilePage using named routes
  /// 
  /// Usage:
  /// ```dart
  /// UserProfilePageIntegration.navigateToNamed(context, 'user123');
  /// ```
  static Future<void> navigateToNamed(BuildContext context, String userId) async {
    await Navigator.of(context).pushNamed(
      '/user-profile',
      arguments: {'userId': userId},
    );
  }

  /// Create a direct widget instance for embedding
  /// 
  /// Usage:
  /// ```dart
  /// Widget profileWidget = UserProfilePageIntegration.createWidget('user123');
  /// ```
  static Widget createWidget(String userId) {
    return Builder(
      builder: (context) {
        // Simulate route arguments for direct widget usage
        return Navigator(
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => const UserProfilePage(),
              settings: RouteSettings(
                arguments: {'userId': userId},
              ),
            );
          },
        );
      },
    );
  }
}

/// Example usage in your app:
/// 
/// ```dart
/// // From a button or list item
/// ElevatedButton(
///   onPressed: () => UserProfilePageIntegration.navigateTo(context, 'user123'),
///   child: Text('View Profile'),
/// )
/// 
/// // From a user search result
/// ListTile(
///   title: Text(user.name),
///   onTap: () => UserProfilePageIntegration.navigateTo(context, user.id),
/// )
/// 
/// // From community feed user avatar
/// GestureDetector(
///   onTap: () => UserProfilePageIntegration.navigateTo(context, post.userId),
///   child: CircleAvatar(backgroundImage: NetworkImage(post.userAvatar)),
/// )
/// ```
