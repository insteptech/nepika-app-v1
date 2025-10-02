import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/community/screens/community_home_screen.dart';
import '../../features/community/screens/user_profile_screen.dart';
import '../../features/community/screens/post_detail_screen.dart';
import '../../features/community/screens/create_post_screen.dart';
import '../../features/dashboard/main.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../services/deep_link_service.dart';
import '../utils/shared_prefs_helper.dart';

/// App Router - Centralized routing configuration with deep linking support
/// Routes are designed to be consistent between internal navigation and external deep links
class AppRouter {
  static final DeepLinkService _deepLinkService = DeepLinkService();
  
  /// Router configuration
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: _handleRedirect,
    routes: [
      // Root route - redirects based on authentication
      GoRoute(
        path: '/',
        builder: (context, state) => const _LoadingScreen(),
      ),
      
      // Onboarding routes
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Dashboard route
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      
      // Community routes
      GoRoute(
        path: '/community',
        name: 'community',
        builder: (context, state) => const CommunityHomeScreen(),
        routes: [
          // Post detail route with postId parameter
          GoRoute(
            path: '/post/:postId',
            name: 'post-detail',
            builder: (context, state) {
              final postId = state.pathParameters['postId']!;
              final fromShare = state.uri.queryParameters['from_share'] == 'true';
              
              return PostDetailScreen(
                postId: postId,
                fromShare: fromShare,
              );
            },
          ),
          
          // User profile route with userId parameter
          GoRoute(
            path: '/profile/:userId',
            name: 'user-profile',
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              final fromShare = state.uri.queryParameters['from_share'] == 'true';
              
              return UserProfileScreen(
                userId: userId,
                fromShare: fromShare,
              );
            },
          ),
          
          // Create post route
          GoRoute(
            path: '/create',
            name: 'create-post',
            builder: (context, state) {
              final token = state.uri.queryParameters['token'];
              final userId = state.uri.queryParameters['userId'];
              
              return CreatePostScreen(
                token: token,
                userId: userId,
              );
            },
          ),
        ],
      ),
    ],
    
    // Error handling
    errorBuilder: (context, state) => _ErrorScreen(error: state.error.toString()),
  );

  /// Handle redirects based on authentication state
  static Future<String?> _handleRedirect(BuildContext context, GoRouterState state) async {
    try {
      await SharedPrefsHelper.init();
      
      final isAuthenticated = await SharedPrefsHelper.isUserLoggedIn();
      final hasCompletedOnboarding = await SharedPrefsHelper.hasCompletedOnboarding();
      
      final location = state.location;
      
      // Allow deep links to pass through without redirect
      if (_isDeepLink(location)) {
        if (!isAuthenticated) {
          // Store the deep link for after authentication
          await _deepLinkService.storePendingDeepLink(location);
          return '/onboarding?deep_link_pending=true';
        }
        return null; // Allow the deep link to proceed
      }
      
      // Handle normal app flow
      if (!isAuthenticated) {
        if (location != '/onboarding') {
          return '/onboarding';
        }
      } else if (!hasCompletedOnboarding) {
        if (location != '/onboarding') {
          return '/onboarding';
        }
      } else {
        // User is authenticated and onboarded
        if (location == '/' || location == '/onboarding') {
          // Check if there's a pending deep link
          final pendingDeepLink = await _deepLinkService.getPendingDeepLink();
          if (pendingDeepLink != null) {
            await _deepLinkService.clearPendingDeepLink();
            return pendingDeepLink;
          }
          return '/dashboard';
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('AppRouter: Error in redirect handler - $e');
      return '/onboarding';
    }
  }

  /// Check if the location is a deep link
  static bool _isDeepLink(String location) {
    return location.startsWith('/community/post/') || 
           location.startsWith('/community/profile/') ||
           (location.startsWith('/community') && location.contains('?from_share=true'));
  }

  /// Navigate to post detail
  static void navigateToPost(BuildContext context, String postId, {bool fromShare = false}) {
    final path = '/community/post/$postId${fromShare ? '?from_share=true' : ''}';
    context.go(path);
  }

  /// Navigate to user profile
  static void navigateToProfile(BuildContext context, String userId, {bool fromShare = false}) {
    final path = '/community/profile/$userId${fromShare ? '?from_share=true' : ''}';
    context.go(path);
  }

  /// Navigate to community home
  static void navigateToCommunity(BuildContext context) {
    context.go('/community');
  }

  /// Navigate to create post
  static void navigateToCreatePost(BuildContext context, {String? token, String? userId}) {
    var path = '/community/create';
    final params = <String>[];
    
    if (token != null) params.add('token=$token');
    if (userId != null) params.add('userId=$userId');
    
    if (params.isNotEmpty) {
      path += '?${params.join('&')}';
    }
    
    context.go(path);
  }

  /// Get the current route name
  static String getCurrentRouteName(BuildContext context) {
    final location = GoRouter.of(context).location;
    
    if (location.startsWith('/community/post/')) return 'post-detail';
    if (location.startsWith('/community/profile/')) return 'user-profile';
    if (location.startsWith('/community/create')) return 'create-post';
    if (location.startsWith('/community')) return 'community';
    if (location.startsWith('/dashboard')) return 'dashboard';
    if (location.startsWith('/onboarding')) return 'onboarding';
    
    return 'unknown';
  }

  /// Extract parameters from current route
  static Map<String, String> getCurrentRouteParams(BuildContext context) {
    final routeData = GoRouter.of(context).routerDelegate.currentConfiguration;
    final params = <String, String>{};
    
    if (routeData.matches.isNotEmpty) {
      final match = routeData.matches.last;
      params.addAll(match.pathParameters);
    }
    
    return params;
  }

  /// Generate shareable URL for post
  static String generatePostShareUrl(String postId) {
    return 'https://nepika.com/community/post/$postId';
  }

  /// Generate shareable URL for profile
  static String generateProfileShareUrl(String userId) {
    return 'https://nepika.com/community/profile/$userId';
  }

  /// Parse deep link and extract route information
  static DeepLinkInfo? parseDeepLink(String url) {
    try {
      final uri = Uri.parse(url);
      
      // Handle nepika.com URLs
      if (uri.host == 'nepika.com') {
        final pathSegments = uri.pathSegments;
        
        if (pathSegments.length >= 3 && pathSegments[0] == 'community') {
          if (pathSegments[1] == 'post') {
            return DeepLinkInfo(
              type: DeepLinkType.post,
              targetId: pathSegments[2],
              path: '/community/post/${pathSegments[2]}',
            );
          } else if (pathSegments[1] == 'profile') {
            return DeepLinkInfo(
              type: DeepLinkType.profile,
              targetId: pathSegments[2],
              path: '/community/profile/${pathSegments[2]}',
            );
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('AppRouter: Error parsing deep link - $e');
      return null;
    }
  }

  /// Initialize deep link handling
  static Future<void> initializeDeepLinking() async {
    await _deepLinkService.initialize();
  }

  /// Handle incoming deep link
  static Future<void> handleIncomingDeepLink(String url, BuildContext context) async {
    final deepLinkInfo = parseDeepLink(url);
    
    if (deepLinkInfo != null) {
      // Track deep link analytics
      await _deepLinkService.trackDeepLinkOpen(deepLinkInfo);
      
      // Navigate to the appropriate screen
      switch (deepLinkInfo.type) {
        case DeepLinkType.post:
          navigateToPost(context, deepLinkInfo.targetId, fromShare: true);
          break;
        case DeepLinkType.profile:
          navigateToProfile(context, deepLinkInfo.targetId, fromShare: true);
          break;
      }
    }
  }
}

/// Loading screen shown during redirect resolution
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}

/// Error screen for routing errors
class _ErrorScreen extends StatelessWidget {
  final String error;
  
  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Navigation Error',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Deep link information model
class DeepLinkInfo {
  final DeepLinkType type;
  final String targetId;
  final String path;
  final Map<String, String> parameters;

  const DeepLinkInfo({
    required this.type,
    required this.targetId,
    required this.path,
    this.parameters = const {},
  });
}

/// Types of deep links supported
enum DeepLinkType {
  post,
  profile,
}