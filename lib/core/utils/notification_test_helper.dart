import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationTestHelper {
  static final FlutterLocalNotificationsPlugin _plugin = 
      FlutterLocalNotificationsPlugin();

  /// Test local notification display
  static Future<void> testLocalNotification() async {
    print('🧪 Testing local notification...');
    
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notifications for debugging',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.show(
        999,
        'Test Notification',
        'This is a test notification to verify local notifications work',
        platformDetails,
      );
      print('✅ Test notification sent successfully');
    } catch (e) {
      print('❌ Test notification failed: $e');
    }
  }

  /// Check all notification-related permissions
  static Future<void> checkNotificationPermissions() async {
    print('🔍 Checking notification permissions...');
    
    // Check Firebase Messaging permissions
    final NotificationSettings fcmSettings = 
        await FirebaseMessaging.instance.getNotificationSettings();
    print('FCM Authorization Status: ${fcmSettings.authorizationStatus}');
    print('FCM Alert Setting: ${fcmSettings.alert}');
    print('FCM Badge Setting: ${fcmSettings.badge}');
    print('FCM Sound Setting: ${fcmSettings.sound}');
    
    // Check system notification permission (Android 13+)
    final PermissionStatus notificationStatus = 
        await Permission.notification.status;
    print('System Notification Permission: $notificationStatus');
    
    // Check if notifications are enabled for the app
    final bool? areNotificationsEnabled = 
        await _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()?.areNotificationsEnabled();
    print('Local Notifications Enabled: $areNotificationsEnabled');
  }

  /// Request all necessary notification permissions
  static Future<void> requestAllNotificationPermissions() async {
    print('📱 Requesting notification permissions...');
    
    // Request Firebase Messaging permissions
    final NotificationSettings fcmSettings = 
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      announcement: false,
    );
    
    print('FCM Permission Result: ${fcmSettings.authorizationStatus}');
    
    // Request system notification permission (Android 13+)
    final PermissionStatus notificationResult = 
        await Permission.notification.request();
    print('System Notification Permission Result: $notificationResult');
    
    // Check final status
    await checkNotificationPermissions();
  }

  /// Get current FCM token and log details
  static Future<void> debugFcmToken() async {
    print('🔑 Getting FCM token details...');
    
    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print('✅ FCM Token: ${token.substring(0, 20)}...');
        print('Full Token Length: ${token.length}');
      } else {
        print('❌ FCM Token is null');
      }
      
      // Check APNS token (iOS)
      try {
        final String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) {
          print('✅ APNS Token: ${apnsToken.substring(0, 20)}...');
        } else {
          print('ℹ️ APNS Token not available (normal for simulators)');
        }
      } catch (e) {
        print('⚠️ APNS Token check failed: $e');
      }
      
    } catch (e) {
      print('❌ FCM Token retrieval failed: $e');
    }
  }

  /// Complete notification system diagnostic
  static Future<void> runFullDiagnostic() async {
    print('\n🔬 === NOTIFICATION DIAGNOSTIC START ===');
    await checkNotificationPermissions();
    print('\n');
    await debugFcmToken();
    print('\n');
    await testLocalNotification();
    print('🔬 === NOTIFICATION DIAGNOSTIC END ===\n');
  }
}