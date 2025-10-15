/// ⚠️ DEPRECATED: This file is deprecated and will be removed in future versions.
/// Use UnifiedFcmService.instance instead from:
/// lib/core/services/unified_fcm_service.dart
/// 
/// Migration Guide:
/// - Replace FcmUtil.init() with UnifiedFcmService.instance.initialize()
/// - Replace FcmUtil.getDeviceFcmToken() with UnifiedFcmService.instance.currentToken
/// - Use proper Firebase configuration from firebase_options.dart
/// - All FCM functionality is now centralized in UnifiedFcmService
library;

import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmUtil {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // -----------------------------
    // 🔥 1. Initialize Firebase
    // -----------------------------
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyDY1ecvnLO94Q7NUFT3liol-WDbUT7wBXM',
          appId: '1:1075434774461:ios:3431aedde55c9f4f05bcd4',
          messagingSenderId: '1075434774461',
          projectId: 'nepika-ai',
          storageBucket: 'nepika-ai.firebasestorage.app',
        ),
      );
      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('❌ Firebase init error: $e');
      return;
    }

    // -----------------------------
    // 🔔 2. Initialize Local Notifications
    // -----------------------------
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('🔔 Notification tapped: ${response.payload}');
        // Handle navigation or app logic here if needed
      },
    );

    // -----------------------------
    // 🧾 3. Request Permissions (iOS)
    // -----------------------------
    try {
      if (Platform.isIOS) {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        print('📱 iOS Permission: ${settings.authorizationStatus}');
      }
    } catch (e) {
      print('⚠️ Permission request failed: $e');
    }

    // -----------------------------
    // 🔁 4. Token Management
    // -----------------------------
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      print('🔁 FCM Token refreshed: ${token.substring(0, 15)}...');
      // Send to backend if needed
    });

    final token = await getDeviceFcmToken();
    print('📲 Device FCM Token: $token');

    // -----------------------------
    // 📬 5. Foreground Message Handling
    // -----------------------------
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔥 === Foreground Message ===');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
      _showNotification(message);
    });

    // -----------------------------
    // 🚀 6. Background Tap Handling
    // -----------------------------
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 Notification tapped (background): ${message.data}');
      _handleMessageTap(message);
    });

    // -----------------------------
    // 💤 7. Terminated App Launch
    // -----------------------------
    final initialMsg = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMsg != null) {
      print('🚀 App launched via terminated FCM');
      _handleMessageTap(initialMsg);
    }

    // -----------------------------
    // ⚡ 8. Auto-init Enable
    // -----------------------------
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    print('✅ FCM auto-init enabled');
  }

  // ==========================================
  // 🧩 LOCAL NOTIFICATION HANDLER
  // ==========================================
  static Future<void> _showNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final data = message.data;

      String? title = notification?.title ?? data['title'];
      String? body = notification?.body ?? data['body'];

      title ??= 'Nepika';
      body ??= 'You have a new notification';

      print('🔔 Showing local notification: "$title" - "$body"');

      const androidDetails = AndroidNotificationDetails(
        'nepika_notifications',
        'Nepika Notifications',
        channelDescription: 'App notifications and reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      );

      const details =
          NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _localNotificationsPlugin.show(
        message.hashCode,
        title,
        body,
        details,
        payload: message.data.toString(),
      );

      print('✅ Notification displayed successfully');
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  // ==========================================
  // 🧭 MESSAGE TAP HANDLER
  // ==========================================
  static void _handleMessageTap(RemoteMessage message) {
    print('🧭 Notification tapped: ${message.data}');
    // Example navigation logic
    // if (message.data['screen'] == 'dashboard') {
    //   NavigationService.navigateTo('/dashboard');
    // }
  }

  // ==========================================
  // 🔑 GET DEVICE TOKEN (Robust)
  // ==========================================
  static Future<String?> getDeviceFcmToken() async {
    try {
      String? token;
      for (int attempt = 1; attempt <= 3; attempt++) {
        token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) break;
        await Future.delayed(Duration(seconds: 2));
      }
      return token ?? 'fcm-fallback-${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      print('❌ Token generation error: $e');
      return 'fcm-error-${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
