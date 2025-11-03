import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_logger.dart';

/// Local Notification Service for scheduling reminder notifications
/// Handles timezone conversion, recurring notifications, and notification management
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  static LocalNotificationService get instance => _instance;

  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  static const String _channelId = 'nepika_reminders';
  static const String _channelName = 'Reminder Notifications';
  static const String _channelDescription = 'Skincare routine reminder notifications';

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.info('LocalNotificationService already initialized', tag: 'Notifications');
      return;
    }

    try {
      AppLogger.info('Initializing LocalNotificationService...', tag: 'Notifications');

      // Initialize timezone data
      await _initializeTimezone();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permissions
      await _requestPermissions();

      _isInitialized = true;
      AppLogger.success('LocalNotificationService initialized successfully', tag: 'Notifications');
    } catch (e, stackTrace) {
      AppLogger.error(
        'LocalNotificationService initialization failed',
        tag: 'Notifications',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Initialize timezone data
  Future<void> _initializeTimezone() async {
    tz.initializeTimeZones();
    
    // Set local timezone
    final String timeZoneName = await _getLocalTimeZone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    
    AppLogger.info('Timezone initialized: $timeZoneName', tag: 'Notifications');
  }

  /// Get the device's local timezone
  Future<String> _getLocalTimeZone() async {
    try {
      // For mobile platforms, we can use the system timezone
      if (Platform.isAndroid || Platform.isIOS) {
        final DateTime now = DateTime.now();
        final String timeZoneName = now.timeZoneName;
        final int offsetHours = now.timeZoneOffset.inHours;
        final int offsetMinutes = now.timeZoneOffset.inMinutes % 60;
        
        AppLogger.info('Device timezone: $timeZoneName, offset: ${offsetHours}h ${offsetMinutes}m', tag: 'Notifications');
        
        // Enhanced timezone mapping with more comprehensive coverage
        final timezoneMap = {
          // India
          'IST': 'Asia/Kolkata',
          // US Timezones
          'PST': 'America/Los_Angeles',
          'PDT': 'America/Los_Angeles',
          'EST': 'America/New_York',
          'EDT': 'America/New_York',
          'MST': 'America/Denver',
          'MDT': 'America/Denver',
          // European Timezones
          'GMT': 'Europe/London',
          'BST': 'Europe/London',
          'CET': 'Europe/Paris',
          'CEST': 'Europe/Paris',
          'EET': 'Europe/Helsinki',
          'EEST': 'Europe/Helsinki',
          // Australian Timezones
          'AEST': 'Australia/Sydney',
          'AEDT': 'Australia/Sydney',
          'AWST': 'Australia/Perth',
          // Asian Timezones
          'JST': 'Asia/Tokyo',
          'KST': 'Asia/Seoul',
          'CST_CN': 'Asia/Shanghai', // China Standard Time (renamed to avoid US CST conflict)
          'SGT': 'Asia/Singapore',
          // Middle East
          'GST': 'Asia/Dubai',
          // US Central Time (separate from CST_CN)
          'CST_US': 'America/Chicago',
          'CDT_US': 'America/Chicago',
        };
        
        if (timezoneMap.containsKey(timeZoneName)) {
          final ianaTimezone = timezoneMap[timeZoneName]!;
          AppLogger.info('Mapped timezone $timeZoneName to $ianaTimezone', tag: 'Notifications');
          return ianaTimezone;
        }
        
        // Try to determine timezone from offset if abbreviation mapping fails
        final offsetBasedTimezone = _getTimezoneFromOffset(offsetHours, offsetMinutes);
        if (offsetBasedTimezone != null) {
          AppLogger.info('Determined timezone from offset: $offsetBasedTimezone', tag: 'Notifications');
          return offsetBasedTimezone;
        }
        
        // Fallback to UTC if we can't determine the timezone
        AppLogger.warning('Unknown timezone $timeZoneName, using UTC', tag: 'Notifications');
        return 'UTC';
      }
      
      return 'UTC';
    } catch (e) {
      AppLogger.warning('Could not determine local timezone, using UTC: $e', tag: 'Notifications');
      return 'UTC';
    }
  }

  /// Get timezone from UTC offset
  String? _getTimezoneFromOffset(int hours, int minutes) {
    final totalMinutes = hours * 60 + minutes;
    
    // Common timezone offsets (in minutes from UTC)
    final offsetMap = {
      -480: 'America/Los_Angeles', // UTC-8 (PST)
      -420: 'America/Denver',      // UTC-7 (MST)
      -360: 'America/Chicago',     // UTC-6 (CST)
      -300: 'America/New_York',    // UTC-5 (EST)
      0: 'Europe/London',          // UTC+0 (GMT)
      60: 'Europe/Paris',          // UTC+1 (CET)
      120: 'Europe/Helsinki',      // UTC+2 (EET)
      330: 'Asia/Kolkata',         // UTC+5:30 (IST)
      480: 'Asia/Shanghai',        // UTC+8 (CST)
      540: 'Asia/Tokyo',           // UTC+9 (JST)
      600: 'Australia/Sydney',     // UTC+10 (AEST)
    };
    
    return offsetMap[totalMinutes];
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true, // Request alert permission
      requestBadgePermission: true, // Request badge permission
      requestSoundPermission: true, // Request sound permission
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _handleBackgroundNotificationTap,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _createAndroidNotificationChannel();
    }

    // Set up foreground notification presentation for iOS
    if (Platform.isIOS) {
      await _setupForegroundNotificationPresentation();
    }

    AppLogger.success('Local notifications initialized', tag: 'Notifications');
  }

  /// Set up foreground notification presentation for iOS
  Future<void> _setupForegroundNotificationPresentation() async {
    final IOSFlutterLocalNotificationsPlugin? iosPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      
      AppLogger.info('iOS foreground notification presentation configured', tag: 'Notifications');
    }
  }

  /// Create Android notification channel for reminders
  Future<void> _createAndroidNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      AppLogger.info('Android notification channel created', tag: 'Notifications');
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    try {
      bool permissionsGranted = true;

      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        permissionsGranted = status.isGranted;
        AppLogger.info('Android notification permission: $status', tag: 'Notifications');
      } else if (Platform.isIOS) {
        final bool? result = await _localNotifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        permissionsGranted = result ?? false;
        AppLogger.info('iOS notification permission: $result', tag: 'Notifications');
      }

      if (!permissionsGranted) {
        AppLogger.warning('Notification permissions not granted', tag: 'Notifications');
      }

      return permissionsGranted;
    } catch (e) {
      AppLogger.error('Failed to request notification permissions', tag: 'Notifications', error: e);
      return false;
    }
  }

  /// Request exact alarm permission (Android 12+)
  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) {
      return true; // iOS doesn't need this permission
    }

    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Check if exact alarms are already permitted
        final bool canSchedule = await androidPlugin.canScheduleExactNotifications() ?? false;
        
        if (canSchedule) {
          AppLogger.info('Exact alarm permission already granted', tag: 'Notifications');
          return true;
        }

        // Request exact alarm permission
        AppLogger.info('Requesting exact alarm permission...', tag: 'Notifications');
        await androidPlugin.requestExactAlarmsPermission();
        
        // Check again after request
        final bool canScheduleAfterRequest = await androidPlugin.canScheduleExactNotifications() ?? false;
        AppLogger.info('Exact alarm permission after request: $canScheduleAfterRequest', tag: 'Notifications');
        
        return canScheduleAfterRequest;
      }

      return false;
    } catch (e) {
      AppLogger.error('Failed to request exact alarm permission', tag: 'Notifications', error: e);
      return false;
    }
  }

  /// Convert 12-hour time format to 24-hour format
  String _convert12HourTo24Hour(String time12Hour) {
    final timeRegex = RegExp(r'^(\d{1,2}):(\d{2}) (AM|PM)$');
    final match = timeRegex.firstMatch(time12Hour.trim());
    
    if (match == null) {
      AppLogger.warning('Invalid time format: $time12Hour, expected HH:MM AM/PM', tag: 'Notifications');
      return '08:00:00'; // Default to 8 AM
    }
    
    int hour = int.parse(match.group(1)!);
    final minute = match.group(2)!;
    final period = match.group(3)!;
    
    // Convert to 24-hour format
    if (period == 'AM') {
      if (hour == 12) hour = 0; // 12 AM = 00
    } else { // PM
      if (hour != 12) hour += 12; // Add 12 except for 12 PM
    }
    
    final time24Hour = '${hour.toString().padLeft(2, '0')}:$minute:00';
    AppLogger.info('Converted $time12Hour to $time24Hour', tag: 'Notifications');
    return time24Hour;
  }

  /// Schedule a reminder notification
  Future<bool> scheduleReminder({
    required String reminderId,
    required String reminderName,
    required String time24Hour, // Format: "HH:MM:SS" or "HH:MM AM/PM"
    required String reminderDays, // "Daily", "Weekdays", "Weekly"
    required String reminderType, // "Morning Routine", "Night Routine"
    required bool isEnabled,
  }) async {
    if (!_isInitialized) {
      AppLogger.warning('LocalNotificationService not initialized', tag: 'Notifications');
      return false;
    }

    if (!isEnabled) {
      AppLogger.info('Reminder is disabled, skipping notification scheduling', tag: 'Notifications');
      return true;
    }

    try {
      AppLogger.info('Scheduling reminder: $reminderName at $time24Hour', tag: 'Notifications');

      // Check for exact alarm permission on Android
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          final bool canSchedule = await androidPlugin.canScheduleExactNotifications() ?? false;
          if (!canSchedule) {
            AppLogger.error('Cannot schedule exact notifications - permission not granted', tag: 'Notifications');
            throw Exception('exact_alarms_not_permitted');
          }
        }
      }

      // Convert time to 24-hour format if needed
      String convertedTime = time24Hour;
      if (time24Hour.contains('AM') || time24Hour.contains('PM')) {
        convertedTime = _convert12HourTo24Hour(time24Hour);
      }

      // Parse the time
      final timeParts = convertedTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Schedule based on reminder frequency
      switch (reminderDays.toLowerCase()) {
        case 'daily':
          await _scheduleDailyReminder(reminderId, reminderName, reminderType, hour, minute);
          break;
        case 'weekdays':
          await _scheduleWeekdaysReminder(reminderId, reminderName, reminderType, hour, minute);
          break;
        case 'weekly':
        case 'weekends':
          await _scheduleWeekendsReminder(reminderId, reminderName, reminderType, hour, minute);
          break;
        default:
          AppLogger.warning('Unknown reminder frequency: $reminderDays', tag: 'Notifications');
          return false;
      }

      AppLogger.success('Reminder scheduled successfully: $reminderName', tag: 'Notifications');
      return true;
    } catch (e) {
      AppLogger.error('Failed to schedule reminder', tag: 'Notifications', error: e);
      return false;
    }
  }

  /// Schedule daily reminder
  Future<void> _scheduleDailyReminder(
    String reminderId,
    String reminderName,
    String reminderType,
    int hour,
    int minute,
  ) async {
    final int notificationId = _generateNotificationId(reminderId);
    final tz.TZDateTime scheduledDate = _getNextScheduledDate(hour, minute);

    await _localNotifications.zonedSchedule(
      notificationId,
      reminderName,
      'Time for your $reminderType!',
      scheduledDate,
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      payload: 'reminder:$reminderId',
    );

    AppLogger.info('Daily reminder scheduled for ${scheduledDate.toString()}', tag: 'Notifications');
  }

  /// Schedule weekdays reminder (Monday to Friday)
  Future<void> _scheduleWeekdaysReminder(
    String reminderId,
    String reminderName,
    String reminderType,
    int hour,
    int minute,
  ) async {
    // Schedule for each weekday (Monday = 1, Friday = 5)
    for (int weekday = 1; weekday <= 5; weekday++) {
      final int notificationId = _generateNotificationId('${reminderId}_$weekday');
      final tz.TZDateTime scheduledDate = _getNextWeekdayDate(weekday, hour, minute);

      await _localNotifications.zonedSchedule(
        notificationId,
        reminderName,
        'Time for your $reminderType!',
        scheduledDate,
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // Repeat weekly on this day
        payload: 'reminder:$reminderId',
      );
    }

    AppLogger.info('Weekdays reminder scheduled', tag: 'Notifications');
  }

  /// Schedule weekends reminder (Saturday and Sunday)
  Future<void> _scheduleWeekendsReminder(
    String reminderId,
    String reminderName,
    String reminderType,
    int hour,
    int minute,
  ) async {
    // Schedule for Saturday (6) and Sunday (7)
    for (int weekday in [6, 7]) {
      final int notificationId = _generateNotificationId('${reminderId}_$weekday');
      final tz.TZDateTime scheduledDate = _getNextWeekdayDate(weekday, hour, minute);

      await _localNotifications.zonedSchedule(
        notificationId,
        reminderName,
        'Time for your $reminderType!',
        scheduledDate,
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // Repeat weekly on this day
        payload: 'reminder:$reminderId',
      );
    }

    AppLogger.info('Weekends reminder scheduled', tag: 'Notifications');
  }

  /// Get the next scheduled date for daily reminders
  tz.TZDateTime _getNextScheduledDate(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // If the scheduled time has already passed today, schedule for tomorrow
    // Add a 2-minute buffer to avoid immediate scheduling issues
    final bufferTime = now.add(const Duration(minutes: 2));
    if (scheduledDate.isBefore(bufferTime)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      AppLogger.info('Scheduled time has passed today, scheduling for tomorrow: ${scheduledDate.toString()}', tag: 'Notifications');
    } else {
      AppLogger.info('Scheduling for today: ${scheduledDate.toString()}', tag: 'Notifications');
    }

    return scheduledDate;
  }

  /// Get the next scheduled date for a specific weekday
  tz.TZDateTime _getNextWeekdayDate(int targetWeekday, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // Calculate days until target weekday
    int daysUntilTarget = (targetWeekday - now.weekday) % 7;
    
    // If it's the same weekday but time has passed, schedule for next week
    if (daysUntilTarget == 0 && scheduledDate.isBefore(now)) {
      daysUntilTarget = 7;
    }

    scheduledDate = scheduledDate.add(Duration(days: daysUntilTarget));
    return scheduledDate;
  }

  /// Generate notification ID from reminder ID
  int _generateNotificationId(String reminderId) {
    // Use hashCode to generate a consistent integer ID
    return reminderId.hashCode.abs() % 2147483647; // Ensure it's within int32 range
  }

  /// Notification details
  NotificationDetails get _notificationDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
      interruptionLevel: InterruptionLevel.active,
    ),
  );

  /// Cancel a reminder notification
  Future<bool> cancelReminder(String reminderId) async {
    try {
      // Cancel main notification
      final int notificationId = _generateNotificationId(reminderId);
      await _localNotifications.cancel(notificationId);

      // Cancel weekday-specific notifications if they exist
      for (int weekday = 1; weekday <= 7; weekday++) {
        final int weekdayNotificationId = _generateNotificationId('${reminderId}_$weekday');
        await _localNotifications.cancel(weekdayNotificationId);
      }

      AppLogger.info('Reminder cancelled: $reminderId', tag: 'Notifications');
      return true;
    } catch (e) {
      AppLogger.error('Failed to cancel reminder', tag: 'Notifications', error: e);
      return false;
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllReminders() async {
    try {
      await _localNotifications.cancelAll();
      AppLogger.info('All reminders cancelled', tag: 'Notifications');
    } catch (e) {
      AppLogger.error('Failed to cancel all reminders', tag: 'Notifications', error: e);
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    AppLogger.info('Reminder notification tapped: ${response.payload}', tag: 'Notifications');
    
    if (response.payload != null && response.payload!.startsWith('reminder:')) {
      final reminderId = response.payload!.substring(9); // Remove 'reminder:' prefix
      // Navigate to reminder or routine screen
      // TODO: Implement navigation based on your app's navigation structure
      AppLogger.info('Should navigate to reminder: $reminderId', tag: 'Notifications');
    }
  }

  /// Handle background notification tap
  @pragma('vm:entry-point')
  static void _handleBackgroundNotificationTap(NotificationResponse response) {
    AppLogger.info('Background reminder notification tapped: ${response.payload}', tag: 'Notifications');
  }

  /// Get all pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      // For iOS, we'll assume notifications are enabled if we can initialize
      // A more robust check would require additional iOS-specific implementation
      return true;
    }
    return false;
  }

  /// Get service status for debugging
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'localTimeZone': tz.local.name,
      'currentTime': tz.TZDateTime.now(tz.local).toString(),
      'deviceTimeZoneName': DateTime.now().timeZoneName,
      'deviceTimeZoneOffset': DateTime.now().timeZoneOffset.toString(),
    };
  }

  /// Show immediate notification (for testing)
  Future<bool> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) {
      AppLogger.warning('LocalNotificationService not initialized', tag: 'Notifications');
      return false;
    }

    try {
      await _localNotifications.show(
        999998, // Immediate notification ID
        title,
        body,
        _notificationDetails,
        payload: 'immediate_test_notification',
      );

      AppLogger.info('Immediate notification shown: $title', tag: 'Notifications');
      return true;
    } catch (e) {
      AppLogger.error('Failed to show immediate notification', tag: 'Notifications', error: e);
      return false;
    }
  }

  /// Test notification scheduling (for debugging)
  Future<bool> testNotification({
    required String title,
    required String body,
    int delaySeconds = 5,
  }) async {
    if (!_isInitialized) {
      AppLogger.warning('LocalNotificationService not initialized', tag: 'Notifications');
      return false;
    }

    try {
      // Try immediate notification first for quick testing
      if (delaySeconds <= 0) {
        return await showImmediateNotification(title: title, body: body);
      }

      final tz.TZDateTime scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: delaySeconds));
      
      await _localNotifications.zonedSchedule(
        999999, // Test notification ID
        title,
        body,
        scheduledDate,
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'test_notification',
      );

      AppLogger.info('Test notification scheduled for ${scheduledDate.toString()}', tag: 'Notifications');
      return true;
    } catch (e) {
      AppLogger.error('Failed to schedule test notification', tag: 'Notifications', error: e);
      return false;
    }
  }

  /// Comprehensive diagnostic function
  Future<Map<String, dynamic>> runDiagnostics() async {
    final diagnostics = <String, dynamic>{};
    
    try {
      // Basic service status
      diagnostics['serviceInitialized'] = _isInitialized;
      diagnostics['platform'] = Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Unknown';
      diagnostics['timezone'] = tz.local.name;
      diagnostics['currentTime'] = tz.TZDateTime.now(tz.local).toString();
      
      // Permission checks
      if (Platform.isAndroid) {
        diagnostics['androidNotificationsEnabled'] = await areNotificationsEnabled();
        try {
          final exactAlarmPermission = await requestExactAlarmPermission();
          diagnostics['androidExactAlarmPermission'] = exactAlarmPermission;
        } catch (e) {
          diagnostics['androidExactAlarmPermissionError'] = e.toString();
        }
      }
      
      if (Platform.isIOS) {
        try {
          final iosPlugin = _localNotifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
          if (iosPlugin != null) {
            final permissions = await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
            diagnostics['iOSPermissions'] = permissions;
          }
        } catch (e) {
          diagnostics['iOSPermissionError'] = e.toString();
        }
      }
      
      // Pending notifications
      try {
        final pending = await getPendingNotifications();
        diagnostics['pendingNotifications'] = pending.length;
        diagnostics['pendingNotificationDetails'] = pending.map((p) => {
          'id': p.id,
          'title': p.title,
          'body': p.body,
          'payload': p.payload,
        }).toList();
      } catch (e) {
        diagnostics['pendingNotificationsError'] = e.toString();
      }
      
      AppLogger.info('Diagnostics completed: $diagnostics', tag: 'Notifications');
      return diagnostics;
    } catch (e) {
      diagnostics['error'] = e.toString();
      AppLogger.error('Diagnostics failed', tag: 'Notifications', error: e);
      return diagnostics;
    }
  }
}