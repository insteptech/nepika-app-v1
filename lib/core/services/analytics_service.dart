import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routing/app_router.dart';

/// Analytics Service - Tracks deep link events and user interactions
/// Provides comprehensive analytics for deep linking performance and user behavior
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static const String _analyticsKey = 'deep_link_analytics';

  bool _isInitialized = false;
  String? _sessionId;
  String? _userId;

  /// Initialize analytics service
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) return;

    try {
      _userId = userId;
      _sessionId = _generateSessionId();
      
      // Track session start
      await trackEvent('session_start', {
        'session_id': _sessionId!,
        'user_id': _userId ?? 'anonymous',
        'platform': _getPlatform(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      _isInitialized = true;
      debugPrint('AnalyticsService: Initialized successfully');
    } catch (e) {
      debugPrint('AnalyticsService: Initialization failed - $e');
      rethrow;
    }
  }

  /// Track deep link received event
  Future<void> trackDeepLinkReceived({
    required String url,
    required String source,
    Map<String, String>? additionalData,
  }) async {
    await trackEvent('deep_link_received', {
      'url': url,
      'source': source,
      'session_id': _sessionId ?? 'unknown',
      'user_id': _userId ?? 'anonymous',
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Track deep link opened event
  Future<void> trackDeepLinkOpened({
    required DeepLinkInfo deepLinkInfo,
    required bool wasAuthenticated,
    Map<String, String>? additionalData,
  }) async {
    await trackEvent('deep_link_opened', {
      'type': deepLinkInfo.type.name,
      'target_id': deepLinkInfo.targetId,
      'path': deepLinkInfo.path,
      'was_authenticated': wasAuthenticated.toString(),
      'session_id': _sessionId ?? 'unknown',
      'user_id': _userId ?? 'anonymous',
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Track post shared event
  Future<void> trackPostShared({
    required String postId,
    required String method,
    Map<String, String>? additionalData,
  }) async {
    await trackEvent('post_shared', {
      'post_id': postId,
      'share_method': method,
      'session_id': _sessionId ?? 'unknown',
      'user_id': _userId ?? 'anonymous',
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Track profile shared event
  Future<void> trackProfileShared({
    required String userId,
    required String method,
    Map<String, String>? additionalData,
  }) async {
    await trackEvent('profile_shared', {
      'shared_user_id': userId,
      'share_method': method,
      'session_id': _sessionId ?? 'unknown',
      'user_id': _userId ?? 'anonymous',
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Track app link verification
  Future<void> trackAppLinkVerification({
    required String domain,
    required bool success,
    String? error,
  }) async {
    await trackEvent('app_link_verification', {
      'domain': domain,
      'success': success.toString(),
      'error': error ?? '',
      'session_id': _sessionId ?? 'unknown',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track fallback page view
  Future<void> trackFallbackPageView({
    required String type,
    required String targetId,
    required String userAgent,
    Map<String, String>? additionalData,
  }) async {
    await trackEvent('fallback_page_view', {
      'type': type,
      'target_id': targetId,
      'user_agent': userAgent,
      'session_id': _sessionId ?? 'unknown',
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Track app install conversion
  Future<void> trackAppInstallConversion({
    required String deepLinkPath,
    required String platform,
    Map<String, String>? additionalData,
  }) async {
    await trackEvent('app_install_conversion', {
      'deep_link_path': deepLinkPath,
      'platform': platform,
      'session_id': _sessionId ?? 'unknown',
      'user_id': _userId ?? 'anonymous',
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Track app launch from deep link
  Future<void> trackAppLaunchFromDeepLink({
    required String deepLinkPath,
    required String launchMethod,
    Map<String, String>? additionalData,
  }) async {
    await trackEvent('app_launch_from_deep_link', {
      'deep_link_path': deepLinkPath,
      'launch_method': launchMethod,
      'session_id': _sessionId ?? 'unknown',
      'user_id': _userId ?? 'anonymous',
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Track navigation events
  Future<void> trackNavigation({
    required String from,
    required String to,
    bool fromDeepLink = false,
    Map<String, String>? additionalData,
  }) async {
    await trackEvent('navigation', {
      'from': from,
      'to': to,
      'from_deep_link': fromDeepLink.toString(),
      'session_id': _sessionId ?? 'unknown',
      'user_id': _userId ?? 'anonymous',
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Track authentication flow from deep link
  Future<void> trackAuthenticationFlow({
    required String stage,
    required String deepLinkPath,
    bool success = false,
    String? error,
  }) async {
    await trackEvent('authentication_flow', {
      'stage': stage,
      'deep_link_path': deepLinkPath,
      'success': success.toString(),
      'error': error ?? '',
      'session_id': _sessionId ?? 'unknown',
      'user_id': _userId ?? 'anonymous',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track performance metrics
  Future<void> trackPerformance({
    required String metric,
    required double value,
    String? context,
    Map<String, String>? additionalData,
  }) async {
    await trackEvent('performance', {
      'metric': metric,
      'value': value.toString(),
      'context': context ?? '',
      'session_id': _sessionId ?? 'unknown',
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Track errors
  Future<void> trackError({
    required String error,
    required String context,
    String? stackTrace,
    Map<String, String>? additionalData,
  }) async {
    await trackEvent('error', {
      'error': error,
      'context': context,
      'stack_trace': stackTrace ?? '',
      'session_id': _sessionId ?? 'unknown',
      'user_id': _userId ?? 'anonymous',
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Generic event tracking
  Future<void> trackEvent(String eventName, Map<String, String> parameters) async {
    try {
      // TODO: When Firebase Analytics is available, send to Firebase
      // FirebaseAnalytics.instance.logEvent(
      //   name: eventName,
      //   parameters: parameters,
      // );

      // Store locally for debugging and fallback
      await _storeEventLocally(eventName, parameters);

      debugPrint('AnalyticsService: Tracked event - $eventName: $parameters');
    } catch (e) {
      debugPrint('AnalyticsService: Error tracking event - $e');
    }
  }

  /// Store event locally for offline analytics and debugging
  Future<void> _storeEventLocally(String eventName, Map<String, String> parameters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingEvents = prefs.getStringList(_analyticsKey) ?? [];

      final event = {
        'event': eventName,
        'parameters': parameters,
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': _sessionId,
      };

      existingEvents.add(jsonEncode(event));

      // Keep only last 1000 events to prevent storage bloat
      if (existingEvents.length > 1000) {
        existingEvents.removeRange(0, existingEvents.length - 1000);
      }

      await prefs.setStringList(_analyticsKey, existingEvents);
    } catch (e) {
      debugPrint('AnalyticsService: Error storing event locally - $e');
    }
  }

  /// Get analytics data for debugging
  Future<List<Map<String, dynamic>>> getAnalyticsData({int? limit}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final events = prefs.getStringList(_analyticsKey) ?? [];

      final decodedEvents = events
          .map((event) => jsonDecode(event) as Map<String, dynamic>)
          .toList();

      if (limit != null && decodedEvents.length > limit) {
        return decodedEvents.sublist(decodedEvents.length - limit);
      }

      return decodedEvents;
    } catch (e) {
      debugPrint('AnalyticsService: Error getting analytics data - $e');
      return [];
    }
  }

  /// Get analytics summary
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final events = await getAnalyticsData();
      final summary = <String, int>{};

      for (final event in events) {
        final eventName = event['event'] as String;
        summary[eventName] = (summary[eventName] ?? 0) + 1;
      }

      return {
        'total_events': events.length,
        'session_id': _sessionId,
        'user_id': _userId,
        'events_by_type': summary,
        'first_event': events.isNotEmpty ? events.first['timestamp'] : null,
        'last_event': events.isNotEmpty ? events.last['timestamp'] : null,
      };
    } catch (e) {
      debugPrint('AnalyticsService: Error getting analytics summary - $e');
      return {};
    }
  }

  /// Export analytics data for server upload
  Future<Map<String, dynamic>> exportAnalyticsData() async {
    try {
      final events = await getAnalyticsData();
      
      return {
        'session_id': _sessionId,
        'user_id': _userId,
        'platform': _getPlatform(),
        'app_version': '1.0.0', // TODO: Get from package info
        'events': events,
        'exported_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('AnalyticsService: Error exporting analytics data - $e');
      return {};
    }
  }

  /// Clear analytics data
  Future<void> clearAnalyticsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_analyticsKey);
      debugPrint('AnalyticsService: Cleared analytics data');
    } catch (e) {
      debugPrint('AnalyticsService: Error clearing analytics data - $e');
    }
  }

  /// Update user ID
  Future<void> setUserId(String userId) async {
    _userId = userId;
    
    await trackEvent('user_identified', {
      'user_id': userId,
      'session_id': _sessionId ?? 'unknown',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Helper methods

  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'sess_${timestamp}_$random';
  }

  String _getPlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }

  /// Get current session ID
  String? get sessionId => _sessionId;

  /// Get current user ID
  String? get userId => _userId;

  /// Check if analytics is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  Future<void> dispose() async {
    if (_sessionId != null) {
      await trackEvent('session_end', {
        'session_id': _sessionId!,
        'user_id': _userId ?? 'anonymous',
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    _isInitialized = false;
    _sessionId = null;
    _userId = null;
    
    debugPrint('AnalyticsService: Disposed');
  }
}