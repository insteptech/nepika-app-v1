import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_logger.dart';

/// Android-specific notification service for handling notification issues
/// This service addresses common Android notification problems
class AndroidNotificationService {
  static final AndroidNotificationService _instance = AndroidNotificationService._internal();
  static AndroidNotificationService get instance => _instance;
  
  AndroidNotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  
  /// Initialize Android notification service with comprehensive setup
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.info('Android notification service already initialized', tag: 'AndroidNotify');
      return;
    }
    
    if (!Platform.isAndroid) {
      AppLogger.info('Not Android platform, skipping Android notification service', tag: 'AndroidNotify');
      return;
    }
    
    try {
      AppLogger.info('Initializing Android notification service...', tag: 'AndroidNotify');
      
      // Initialize with Android-specific settings
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initializationSettings = InitializationSettings(
        android: androidSettings,
      );
      
      await _localNotifications.initialize(initializationSettings);
      
      // Create essential notification channels
      await _createNotificationChannels();
      
      // Request Android 13+ permissions
      await _requestAndroidNotificationPermissions();
      
      // Verify notification permissions
      await _verifyNotificationSetup();
      
      _isInitialized = true;
      AppLogger.success('Android notification service initialized successfully', tag: 'AndroidNotify');
      
    } catch (e) {
      AppLogger.error('Failed to initialize Android notification service', tag: 'AndroidNotify', error: e);
      rethrow;
    }
  }
  
  /// Create comprehensive notification channels for Android
  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) {
      AppLogger.error('Android plugin not available for notification channels', tag: 'AndroidNotify');
      return;
    }
    
    // Main notification channel (same as FCM default)
    const AndroidNotificationChannel mainChannel = AndroidNotificationChannel(
      'nepika_notifications',
      'Nepika Notifications',
      description: 'Main app notifications and updates',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
      enableLights: true,
      ledColor: null, // Use system default
    );
    
    // High priority channel for urgent notifications
    const AndroidNotificationChannel urgentChannel = AndroidNotificationChannel(
      'nepika_urgent',
      'Urgent Notifications',
      description: 'High priority urgent notifications',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
      enableLights: true,
    );
    
    // Reminders channel
    const AndroidNotificationChannel remindersChannel = AndroidNotificationChannel(
      'nepika_reminders',
      'Reminders',
      description: 'Skincare routine reminders',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );
    
    // Create all channels
    await androidPlugin.createNotificationChannel(mainChannel);
    await androidPlugin.createNotificationChannel(urgentChannel);
    await androidPlugin.createNotificationChannel(remindersChannel);
    
    AppLogger.success('Android notification channels created', tag: 'AndroidNotify');
  }
  
  /// Request Android 13+ notification permissions with comprehensive handling
  Future<bool> _requestAndroidNotificationPermissions() async {
    try {
      AppLogger.info('Requesting Android notification permissions...', tag: 'AndroidNotify');
      
      // Check current permission status
      PermissionStatus currentStatus = await Permission.notification.status;
      AppLogger.info('Current notification permission: $currentStatus', tag: 'AndroidNotify');
      
      if (currentStatus.isGranted) {
        AppLogger.success('Notification permission already granted', tag: 'AndroidNotify');
        return true;
      }
      
      if (currentStatus.isDenied) {
        // Request permission
        PermissionStatus requestResult = await Permission.notification.request();
        AppLogger.info('Permission request result: $requestResult', tag: 'AndroidNotify');
        
        if (requestResult.isGranted) {
          AppLogger.success('Notification permission granted after request', tag: 'AndroidNotify');
          return true;
        } else if (requestResult.isPermanentlyDenied) {
          AppLogger.error('Notification permission permanently denied - user needs to enable in settings', tag: 'AndroidNotify');
          return false;
        } else {
          AppLogger.warning('Notification permission denied by user', tag: 'AndroidNotify');
          return false;
        }
      }
      
      if (currentStatus.isPermanentlyDenied) {
        AppLogger.error('Notification permission permanently denied - cannot request again', tag: 'AndroidNotify');
        return false;
      }
      
      return false;
    } catch (e) {
      AppLogger.error('Error requesting Android notification permissions', tag: 'AndroidNotify', error: e);
      return false;
    }
  }
  
  /// Verify Android notification setup is working correctly
  Future<Map<String, bool>> _verifyNotificationSetup() async {
    final verification = <String, bool>{};
    
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Check if notifications are enabled
        verification['notifications_enabled'] = await androidPlugin.areNotificationsEnabled() ?? false;
        
        // Check exact alarm permissions (for scheduling)
        verification['exact_alarms_allowed'] = await androidPlugin.canScheduleExactNotifications() ?? false;
        
        AppLogger.info('Android notification verification: $verification', tag: 'AndroidNotify');
      } else {
        verification['android_plugin_available'] = false;
        AppLogger.error('Android notification plugin not available', tag: 'AndroidNotify');
      }
    } catch (e) {
      AppLogger.error('Error verifying Android notification setup', tag: 'AndroidNotify', error: e);
      verification['verification_error'] = false;
    }
    
    return verification;
  }
  
  /// Show test notification to verify Android setup
  Future<bool> showTestNotification() async {
    if (!_isInitialized) {
      AppLogger.error('Android notification service not initialized', tag: 'AndroidNotify');
      return false;
    }
    
    try {
      AppLogger.info('Showing Android test notification...', tag: 'AndroidNotify');
      
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'nepika_notifications',
        'Nepika Notifications',
        channelDescription: 'Main app notifications and updates',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        enableLights: true,
        autoCancel: true,
        ongoing: false,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ticker: 'Nepika Test',
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.message,
      );
      
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );
      
      final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      
      await _localNotifications.show(
        notificationId,
        '🧪 Android Test Notification',
        'If you see this, Android notifications are working correctly!',
        platformDetails,
      );
      
      AppLogger.success('Android test notification sent', tag: 'AndroidNotify');
      return true;
    } catch (e) {
      AppLogger.error('Failed to show Android test notification', tag: 'AndroidNotify', error: e);
      return false;
    }
  }
  
  /// Get comprehensive Android notification status
  Future<Map<String, dynamic>> getAndroidNotificationStatus() async {
    final status = <String, dynamic>{};
    
    try {
      status['service_initialized'] = _isInitialized;
      status['platform'] = 'Android';
      
      // Permission status
      final permissionStatus = await Permission.notification.status;
      status['permission_status'] = permissionStatus.toString();
      status['permission_granted'] = permissionStatus.isGranted;
      
      // Android plugin checks
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        status['android_plugin_available'] = true;
        status['notifications_enabled'] = await androidPlugin.areNotificationsEnabled();
        status['exact_alarms_allowed'] = await androidPlugin.canScheduleExactNotifications();
      } else {
        status['android_plugin_available'] = false;
      }
      
      AppLogger.info('Android notification status: $status', tag: 'AndroidNotify');
    } catch (e) {
      status['status_error'] = e.toString();
      AppLogger.error('Error getting Android notification status', tag: 'AndroidNotify', error: e);
    }
    
    return status;
  }
  
  /// Open Android notification settings for the app
  Future<bool> openNotificationSettings() async {
    try {
      AppLogger.info('Opening Android notification settings...', tag: 'AndroidNotify');
      
      final bool opened = await Permission.notification.shouldShowRequestRationale
          ? await openAppSettings()
          : await Permission.notification.request().then((status) => status.isGranted);
      
      if (opened) {
        AppLogger.success('Android notification settings opened', tag: 'AndroidNotify');
      } else {
        AppLogger.warning('Failed to open Android notification settings', tag: 'AndroidNotify');
      }
      
      return opened;
    } catch (e) {
      AppLogger.error('Error opening Android notification settings', tag: 'AndroidNotify', error: e);
      return false;
    }
  }
}