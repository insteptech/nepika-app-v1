/// ⚠️ DEPRECATED: This file is deprecated and will be removed in future versions.
/// Use UnifiedFcmService.instance instead from:
/// lib/core/services/unified_fcm_service.dart
/// 
/// Migration Guide:
/// - Replace FcmManager.instance.initialize() with UnifiedFcmService.instance.initialize()
/// - Replace FcmManager.instance.getToken() with UnifiedFcmService.instance.currentToken
/// - Use proper Firebase configuration from firebase_options.dart
/// - All FCM functionality is now centralized in UnifiedFcmService
library;

import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nepika/core/utils/app_logger.dart';

/// Centralized FCM Manager
/// Handles Firebase initialization, token management, and notification setup
class FcmManager {
  static final FcmManager _instance = FcmManager._internal();
  static FcmManager get instance => _instance;

  FcmManager._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Check if FCM is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase and FCM
  /// This should be called only once during app startup
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.warning('FCM already initialized, skipping', tag: 'FCM');
      return;
    }

    try {
      // Initialize Firebase (uses platform-specific config files)
      try {
        Firebase.app(); // Check if already initialized
        AppLogger.info('Firebase already initialized', tag: 'FCM');
      } catch (e) {
        // Not initialized, initialize now
        await Firebase.initializeApp();
        AppLogger.success('Firebase initialized successfully', tag: 'FCM');
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permissions
      await _requestPermissions();

      // Set auto-init
      await FirebaseMessaging.instance.setAutoInitEnabled(true);

      _isInitialized = true;
      AppLogger.success('FCM initialization complete', tag: 'FCM');
    } catch (e, stackTrace) {
      AppLogger.error(
        'FCM initialization failed',
        tag: 'FCM',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    AppLogger.success('Local notifications initialized', tag: 'FCM');
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    AppLogger.info('Notification tapped: ${response.payload}', tag: 'FCM');
    // Navigation logic can be handled here via NavigationService
  }

  /// Request notification permissions
  Future<NotificationSettings> _requestPermissions() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    AppLogger.info(
      'Notification permission status: ${settings.authorizationStatus}',
      tag: 'FCM',
    );

    return settings;
  }

  /// Get FCM token from device
  /// Returns null if token cannot be retrieved
  /// IMPORTANT: Does NOT generate fallback tokens
  Future<String?> getToken() async {
    if (!_isInitialized) {
      AppLogger.error('FCM not initialized, cannot get token', tag: 'FCM');
      return null;
    }

    try {
      // Try to get token with retries
      String? token;
      const maxAttempts = 3;
      const delayBetweenAttempts = Duration(seconds: 2);

      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        token = await FirebaseMessaging.instance.getToken();

        if (token != null && token.isNotEmpty) {
          AppLogger.success(
            'FCM token retrieved (attempt $attempt): ${token.substring(0, 20)}...',
            tag: 'FCM',
          );
          return token;
        }

        if (attempt < maxAttempts) {
          AppLogger.warning(
            'FCM token not available, retrying in ${delayBetweenAttempts.inSeconds}s (attempt $attempt/$maxAttempts)',
            tag: 'FCM',
          );
          await Future.delayed(delayBetweenAttempts);
        }
      }

      // If we get here, all attempts failed
      AppLogger.error(
        'Failed to retrieve FCM token after $maxAttempts attempts',
        tag: 'FCM',
      );
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error getting FCM token',
        tag: 'FCM',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Delete FCM token (useful for logout)
  Future<void> deleteToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
      AppLogger.success('FCM token deleted', tag: 'FCM');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error deleting FCM token',
        tag: 'FCM',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Show local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'nepika_notifications',
        'Nepika Notifications',
        channelDescription: 'App notifications and reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        details,
        payload: payload,
      );

      AppLogger.success('Local notification shown: $title', tag: 'FCM');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error showing notification',
        tag: 'FCM',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidImpl = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidImpl?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    return false;
  }
}
