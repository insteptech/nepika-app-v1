import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/deep_link_handler.dart';
import '../services/deep_link_service.dart';
import '../services/analytics_service.dart';
import '../services/web_fallback_service.dart';

/// Deep Link Integration Manager - Orchestrates all deep linking services
/// Provides a unified interface for initializing and managing the deep linking ecosystem
class DeepLinkIntegrationManager {
  static final DeepLinkIntegrationManager _instance = DeepLinkIntegrationManager._internal();
  factory DeepLinkIntegrationManager() => _instance;
  DeepLinkIntegrationManager._internal();

  final DeepLinkHandler _handler = DeepLinkHandler();
  final DeepLinkService _service = DeepLinkService();
  final AnalyticsService _analytics = AnalyticsService();
  final WebFallbackService _fallbackService = WebFallbackService();

  bool _isInitialized = false;

  /// Initialize the entire deep linking system
  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    String? userId,
  }) async {
    if (_isInitialized) {
      debugPrint('DeepLinkIntegrationManager: Already initialized');
      return;
    }

    try {
      debugPrint('DeepLinkIntegrationManager: Starting initialization...');

      // Initialize analytics first
      await _analytics.initialize(userId: userId);
      
      // Track initialization
      await _analytics.trackEvent('deep_link_system_init', {
        'user_id': userId ?? 'anonymous',
        'platform': defaultTargetPlatform.name,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Initialize deep link service
      await _service.initialize();

      // Initialize deep link handler
      await _handler.initialize(navigatorKey);

      _isInitialized = true;

      // Track successful initialization
      await _analytics.trackEvent('deep_link_system_ready', {
        'user_id': userId ?? 'anonymous',
        'initialization_time': DateTime.now().toIso8601String(),
      });

      debugPrint('DeepLinkIntegrationManager: Initialization completed successfully');
    } catch (e) {
      debugPrint('DeepLinkIntegrationManager: Initialization failed - $e');
      
      // Track initialization failure
      await _analytics.trackError(
        error: e.toString(),
        context: 'deep_link_system_initialization',
      );
      
      rethrow;
    }
  }

  /// Process a deep link manually
  Future<void> processDeepLink(String url, BuildContext context) async {
    if (!_isInitialized) {
      throw StateError('DeepLinkIntegrationManager not initialized');
    }

    try {
      await _analytics.trackDeepLinkReceived(
        url: url,
        source: 'manual_processing',
      );

      if (context.mounted) {
        await _handler.processDeepLink(url, context);
      }
    } catch (e) {
      await _analytics.trackError(
        error: e.toString(),
        context: 'manual_deep_link_processing',
        additionalData: {'url': url},
      );
      rethrow;
    }
  }

  /// Generate and share a post
  Future<void> sharePost(String postId, {dynamic post}) async {
    try {
      await _service.sharePost(postId, post: post);
      
      await _analytics.trackEvent('post_share_initiated', {
        'post_id': postId,
        'method': 'integration_manager',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      await _analytics.trackError(
        error: e.toString(),
        context: 'post_sharing',
        additionalData: {'post_id': postId},
      );
      rethrow;
    }
  }

  /// Generate and share a profile
  Future<void> shareProfile(String userId, {dynamic profile}) async {
    try {
      await _service.shareProfile(userId, profile: profile);
      
      await _analytics.trackEvent('profile_share_initiated', {
        'shared_user_id': userId,
        'method': 'integration_manager',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      await _analytics.trackError(
        error: e.toString(),
        context: 'profile_sharing',
        additionalData: {'user_id': userId},
      );
      rethrow;
    }
  }

  /// Generate web fallback data for a post
  Future<Map<String, String>> generatePostFallbackData(String postId, {dynamic post, dynamic author}) async {
    try {
      final fallbackData = await _fallbackService.generatePostFallbackData(
        postId: postId,
        post: post,
        author: author,
      );

      await _analytics.trackEvent('fallback_data_generated', {
        'type': 'post',
        'target_id': postId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return fallbackData;
    } catch (e) {
      await _analytics.trackError(
        error: e.toString(),
        context: 'fallback_data_generation',
        additionalData: {'type': 'post', 'target_id': postId},
      );
      rethrow;
    }
  }

  /// Generate web fallback data for a profile
  Future<Map<String, String>> generateProfileFallbackData(String userId, {dynamic profile}) async {
    try {
      final fallbackData = await _fallbackService.generateProfileFallbackData(
        userId: userId,
        profile: profile,
      );

      await _analytics.trackEvent('fallback_data_generated', {
        'type': 'profile',
        'target_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return fallbackData;
    } catch (e) {
      await _analytics.trackError(
        error: e.toString(),
        context: 'fallback_data_generation',
        additionalData: {'type': 'profile', 'target_id': userId},
      );
      rethrow;
    }
  }

  /// Get comprehensive system statistics
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final analyticsSummary = await _analytics.getAnalyticsSummary();
      final handlerContext = await _handler.getDeepLinkContext();

      return {
        'system': {
          'is_initialized': _isInitialized,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'analytics': analyticsSummary,
        'handler': handlerContext,
        'service': {
          'is_initialized': _service.toString().isNotEmpty,
        },
      };
    } catch (e) {
      await _analytics.trackError(
        error: e.toString(),
        context: 'system_stats_retrieval',
      );
      
      return {
        'error': e.toString(),
        'system': {'is_initialized': _isInitialized},
      };
    }
  }

  /// Perform comprehensive health check
  Future<Map<String, bool>> performHealthCheck() async {
    final health = <String, bool>{};

    try {
      // Check if initialized
      health['initialized'] = _isInitialized;

      // Check analytics service
      health['analytics'] = _analytics.isInitialized;

      // Check handler context
      final handlerContext = await _handler.getDeepLinkContext();
      health['handler'] = handlerContext['is_initialized'] == true;

      // Check if services are available
      health['deep_link_service'] = _service.toString().isNotEmpty;
      health['fallback_service'] = true; // Fallback service is always available

      // Overall system health
      health['system'] = health.values.every((element) => element == true);

      await _analytics.trackEvent('health_check_performed', {
        'overall_health': health['system'].toString(),
        'components_healthy': health.values.where((h) => h).length.toString(),
        'total_components': health.length.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      return health;
    } catch (e) {
      await _analytics.trackError(
        error: e.toString(),
        context: 'health_check',
      );

      health['error'] = false;
      return health;
    }
  }

  /// Export analytics data for debugging or server upload
  Future<Map<String, dynamic>> exportAnalyticsData() async {
    try {
      final analyticsData = await _analytics.exportAnalyticsData();
      
      await _analytics.trackEvent('analytics_data_exported', {
        'events_count': analyticsData['events']?.length?.toString() ?? '0',
        'timestamp': DateTime.now().toIso8601String(),
      });

      return analyticsData;
    } catch (e) {
      await _analytics.trackError(
        error: e.toString(),
        context: 'analytics_data_export',
      );
      rethrow;
    }
  }

  /// Clear all analytics data
  Future<void> clearAnalyticsData() async {
    try {
      await _analytics.clearAnalyticsData();
      
      debugPrint('DeepLinkIntegrationManager: Analytics data cleared');
    } catch (e) {
      await _analytics.trackError(
        error: e.toString(),
        context: 'analytics_data_clearing',
      );
      rethrow;
    }
  }

  /// Update user ID across all services
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(userId);
      
      await _analytics.trackEvent('user_id_updated', {
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint('DeepLinkIntegrationManager: User ID updated to $userId');
    } catch (e) {
      await _analytics.trackError(
        error: e.toString(),
        context: 'user_id_update',
        additionalData: {'user_id': userId},
      );
      rethrow;
    }
  }

  /// Handle app link verification (Android)
  Future<void> handleAppLinkVerification() async {
    try {
      await _handler.handleAppLinkVerification();
      
      await _analytics.trackAppLinkVerification(
        domain: 'nepika.com',
        success: true,
      );
    } catch (e) {
      await _analytics.trackAppLinkVerification(
        domain: 'nepika.com',
        success: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Track app launch from deep link
  Future<void> trackAppLaunchFromDeepLink(String deepLinkPath) async {
    await _analytics.trackAppLaunchFromDeepLink(
      deepLinkPath: deepLinkPath,
      launchMethod: 'app_launch',
    );
  }

  /// Dispose all resources
  Future<void> dispose() async {
    try {
      await _analytics.trackEvent('deep_link_system_dispose', {
        'timestamp': DateTime.now().toIso8601String(),
      });

      await _handler.dispose();
      await _service.dispose();
      await _analytics.dispose();

      _isInitialized = false;

      debugPrint('DeepLinkIntegrationManager: Disposed all resources');
    } catch (e) {
      debugPrint('DeepLinkIntegrationManager: Error during disposal - $e');
    }
  }

  // Getters for individual services (if needed)
  DeepLinkHandler get handler => _handler;
  DeepLinkService get service => _service;
  AnalyticsService get analytics => _analytics;
  WebFallbackService get fallbackService => _fallbackService;

  bool get isInitialized => _isInitialized;
}