import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'deep_link_service.dart';
import '../routing/app_router.dart';
import 'analytics_service.dart';

/// Deep Link Handler - Manages incoming deep links and app state
/// Handles the complete flow from receiving a link to navigating to the appropriate screen
class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  final DeepLinkService _deepLinkService = DeepLinkService();
  final AnalyticsService _analytics = AnalyticsService();
  
  bool _isInitialized = false;
  StreamSubscription<String>? _linkSubscription;
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize deep link handling
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_isInitialized) return;

    try {
      _navigatorKey = navigatorKey;
      
      // Initialize the deep link service
      await _deepLinkService.initialize();
      
      // Listen for incoming deep links
      _setupDeepLinkListener();
      
      // Handle initial link when app is launched from a link
      await _handleInitialLink();
      
      _isInitialized = true;
      debugPrint('DeepLinkHandler: Initialized successfully');
    } catch (e) {
      debugPrint('DeepLinkHandler: Initialization failed - $e');
      rethrow;
    }
  }

  /// Setup listener for incoming deep links
  void _setupDeepLinkListener() {
    _linkSubscription?.cancel();
    
    // Listen to deep link service stream
    _linkSubscription = _deepLinkService.deepLinkStream?.listen((url) {
      _handleIncomingLink(url);
    });

    // Listen to platform channel for app links
    _setupPlatformChannelListener();
  }

  /// Setup platform channel listener for app links
  void _setupPlatformChannelListener() {
    try {
      // For Android App Links and iOS Universal Links
      const platform = MethodChannel('com.assisted.nepika/deep_links');
      
      platform.setMethodCallHandler((call) async {
        if (call.method == 'routeUpdated') {
          final url = call.arguments as String?;
          if (url != null) {
            await _handleIncomingLink(url);
          }
        }
      });
    } catch (e) {
      debugPrint('DeepLinkHandler: Error setting up platform channel - $e');
    }
  }

  /// Handle initial link when app is launched from a link
  Future<void> _handleInitialLink() async {
    try {
      // This would be implemented with Firebase Dynamic Links or platform-specific code
      // For now, we'll check if there's a pending deep link stored
      final pendingLink = await _deepLinkService.getPendingDeepLink();
      if (pendingLink != null) {
        await _handleIncomingLink(pendingLink);
        await _deepLinkService.clearPendingDeepLink();
      }
    } catch (e) {
      debugPrint('DeepLinkHandler: Error handling initial link - $e');
    }
  }

  /// Handle incoming deep link
  Future<void> _handleIncomingLink(String url) async {
    try {
      debugPrint('DeepLinkHandler: Processing incoming link - $url');
      
      // Check if we can handle this URL
      if (!_deepLinkService.canHandleUrl(url)) {
        debugPrint('DeepLinkHandler: Cannot handle URL - $url');
        return;
      }

      // Parse the deep link
      final deepLinkInfo = AppRouter.parseDeepLink(url);
      if (deepLinkInfo == null) {
        debugPrint('DeepLinkHandler: Failed to parse deep link - $url');
        return;
      }

      // Track analytics
      final isAuthenticated = await _isUserAuthenticated();
      await _analytics.trackDeepLinkOpened(
        deepLinkInfo: deepLinkInfo,
        wasAuthenticated: isAuthenticated,
      );

      // Get the current context
      final context = _navigatorKey?.currentContext;
      if (context == null) {
        debugPrint('DeepLinkHandler: No navigator context available');
        // Store the link for later processing
        await _deepLinkService.storePendingDeepLink(url);
        return;
      }

      // Navigate to the appropriate screen
      if (context.mounted) {
        await _navigateToDeepLink(context, deepLinkInfo);
      }
      
    } catch (e) {
      debugPrint('DeepLinkHandler: Error handling incoming link - $e');
    }
  }

  /// Navigate to the appropriate screen based on deep link info
  Future<void> _navigateToDeepLink(BuildContext context, DeepLinkInfo deepLinkInfo) async {
    try {
      switch (deepLinkInfo.type) {
        case DeepLinkType.post:
          await _handlePostDeepLink(context, deepLinkInfo);
          break;
        
        case DeepLinkType.profile:
          await _handleProfileDeepLink(context, deepLinkInfo);
          break;
      }
    } catch (e) {
      debugPrint('DeepLinkHandler: Error navigating to deep link - $e');
      if (context.mounted) {
        _showDeepLinkError(context, 'Failed to open link');
      }
    }
  }

  /// Handle post deep link navigation
  Future<void> _handlePostDeepLink(BuildContext context, DeepLinkInfo deepLinkInfo) async {
    try {
      final postId = deepLinkInfo.targetId;
      
      // Check if user is authenticated
      if (!await _isUserAuthenticated()) {
        if (context.mounted) {
          await _handleUnauthenticatedAccess(context, deepLinkInfo);
        }
        return;
      }

      // Navigate to post detail screen
      if (context.mounted) {
        AppRouter.navigateToPost(context, postId, fromShare: true);
        
        // Show a toast indicating the post was opened from a link
        _showDeepLinkSuccess(context, 'Opened post from shared link');
      }
      
    } catch (e) {
      debugPrint('DeepLinkHandler: Error handling post deep link - $e');
      if (context.mounted) {
        _showDeepLinkError(context, 'Failed to open post');
      }
    }
  }

  /// Handle profile deep link navigation
  Future<void> _handleProfileDeepLink(BuildContext context, DeepLinkInfo deepLinkInfo) async {
    try {
      final userId = deepLinkInfo.targetId;
      
      // Check if user is authenticated
      if (!await _isUserAuthenticated()) {
        if (context.mounted) {
          await _handleUnauthenticatedAccess(context, deepLinkInfo);
        }
        return;
      }

      // Navigate to user profile screen
      if (context.mounted) {
        AppRouter.navigateToProfile(context, userId, fromShare: true);
        
        // Show a toast indicating the profile was opened from a link
        _showDeepLinkSuccess(context, 'Opened profile from shared link');
      }
      
    } catch (e) {
      debugPrint('DeepLinkHandler: Error handling profile deep link - $e');
      if (context.mounted) {
        _showDeepLinkError(context, 'Failed to open profile');
      }
    }
  }

  /// Handle access when user is not authenticated
  Future<void> _handleUnauthenticatedAccess(BuildContext context, DeepLinkInfo deepLinkInfo) async {
    try {
      // Store the deep link for after authentication
      await _deepLinkService.storePendingDeepLink(deepLinkInfo.path);
      
      // Show dialog asking user to sign in
      if (context.mounted) {
        final shouldSignIn = await _showSignInDialog(context, deepLinkInfo);
        
        if (shouldSignIn && context.mounted) {
          // Navigate to onboarding/sign in
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/onboarding',
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('DeepLinkHandler: Error handling unauthenticated access - $e');
    }
  }

  /// Show sign in dialog for unauthenticated users
  Future<bool> _showSignInDialog(BuildContext context, DeepLinkInfo deepLinkInfo) async {
    final contentType = deepLinkInfo.type == DeepLinkType.post ? 'post' : 'profile';
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In Required'),
        content: Text('Sign in to NEPIKA to view this $contentType.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign In'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Check if user is authenticated
  Future<bool> _isUserAuthenticated() async {
    try {
      // This would check with your authentication service
      // For now, we'll use a simple check
      return true; // Placeholder
    } catch (e) {
      debugPrint('DeepLinkHandler: Error checking authentication - $e');
      return false;
    }
  }

  /// Show success message for deep link
  void _showDeepLinkSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error message for deep link
  void _showDeepLinkError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            // Could implement retry logic here
          },
        ),
      ),
    );
  }

  /// Process a deep link URL manually (for testing or custom scenarios)
  Future<void> processDeepLink(String url, BuildContext context) async {
    await _handleIncomingLink(url);
  }

  /// Get deep link information for the current context
  Future<Map<String, dynamic>> getDeepLinkContext() async {
    try {
      final analyticsData = await _deepLinkService.getAnalyticsData();
      
      return {
        'is_initialized': _isInitialized,
        'has_navigator_key': _navigatorKey != null,
        'analytics_entries': analyticsData.length,
        'service_initialized': _deepLinkService.toString().isNotEmpty,
      };
    } catch (e) {
      debugPrint('DeepLinkHandler: Error getting context - $e');
      return {'error': e.toString()};
    }
  }

  /// Handle app link verification for Android
  Future<void> handleAppLinkVerification() async {
    try {
      // This would handle Android App Link verification
      // The verification is primarily handled by the Android system
      // but we can provide feedback about the verification status
      debugPrint('DeepLinkHandler: App link verification handled');
    } catch (e) {
      debugPrint('DeepLinkHandler: Error in app link verification - $e');
    }
  }

  /// Create a custom deep link for internal navigation
  String createInternalDeepLink({
    required String type,
    required String id,
    Map<String, String>? parameters,
  }) {
    var path = 'nepika://community/$type/$id';
    
    if (parameters != null && parameters.isNotEmpty) {
      final query = parameters.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      path += '?$query';
    }
    
    return path;
  }

  /// Dispose resources
  Future<void> dispose() async {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _navigatorKey = null;
    _isInitialized = false;
    
    await _deepLinkService.dispose();
    
    debugPrint('DeepLinkHandler: Disposed');
  }
}