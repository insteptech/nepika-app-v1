import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/shared_prefs_helper.dart';
import '../utils/app_logger.dart';
import 'unified_fcm_service.dart';

/// Service to handle notification permission management and tracking
/// Specifically designed to solve iOS notification permission issues
class NotificationPermissionService {
  static final NotificationPermissionService _instance = NotificationPermissionService._internal();
  static NotificationPermissionService get instance => _instance;
  
  NotificationPermissionService._internal();

  final SharedPrefsHelper _prefsHelper = SharedPrefsHelper();

  /// Check if we should show notification permission dialog
  /// Returns true if:
  /// 1. Permission has not been prompted before (no record in local storage)
  /// 2. AND current permission is denied
  Future<bool> shouldShowPermissionDialog() async {
    try {
      AppLogger.info('Checking if notification permission dialog should be shown...', tag: 'NotificationPermission');
      
      // Check if user has been prompted before
      final hasBeenPrompted = await _prefsHelper.hasNotificationPermissionBeenPrompted();
      AppLogger.info('Has been prompted before: $hasBeenPrompted', tag: 'NotificationPermission');
      
      if (hasBeenPrompted) {
        // User has been prompted before, don't show dialog again
        AppLogger.info('User has been prompted before, not showing dialog', tag: 'NotificationPermission');
        return false;
      }

      // Check current permission status
      final isPermissionGranted = await _getCurrentPermissionStatus();
      AppLogger.info('Current permission status: $isPermissionGranted', tag: 'NotificationPermission');
      
      if (isPermissionGranted) {
        // Permission is already granted, mark as prompted and don't show dialog
        await _prefsHelper.setNotificationPermissionPrompted(true);
        await _prefsHelper.setNotificationPermissionGranted(true);
        AppLogger.info('Permission already granted, marking as prompted', tag: 'NotificationPermission');
        return false;
      }

      // Permission is denied and user hasn't been prompted - show dialog
      AppLogger.info('Permission denied and not prompted before - should show dialog', tag: 'NotificationPermission');
      return true;
    } catch (e) {
      AppLogger.error('Error checking permission dialog status: $e', tag: 'NotificationPermission');
      return false;
    }
  }

  /// Get current notification permission status
  Future<bool> _getCurrentPermissionStatus() async {
    try {
      if (Platform.isIOS) {
        // For iOS, check Firebase Messaging settings
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                         settings.authorizationStatus == AuthorizationStatus.provisional;
        AppLogger.info('iOS FCM permission status: ${settings.authorizationStatus}, granted: $isGranted', tag: 'NotificationPermission');
        return isGranted;
      } else if (Platform.isAndroid) {
        // For Android, check system permission
        final status = await Permission.notification.status;
        final isGranted = status.isGranted;
        AppLogger.info('Android permission status: $status, granted: $isGranted', tag: 'NotificationPermission');
        return isGranted;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error getting current permission status: $e', tag: 'NotificationPermission');
      return false;
    }
  }

  /// Request notification permission and track the response
  Future<bool> requestNotificationPermission() async {
    try {
      AppLogger.info('Requesting notification permission...', tag: 'NotificationPermission');
      
      // Mark as prompted regardless of result
      await _prefsHelper.setNotificationPermissionPrompted(true);
      
      bool isGranted = false;
      
      if (Platform.isIOS) {
        // Request permission via Firebase Messaging for iOS
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          announcement: false,
        );
        
        isGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                   settings.authorizationStatus == AuthorizationStatus.provisional;
        
        AppLogger.info('iOS permission request result: ${settings.authorizationStatus}, granted: $isGranted', tag: 'NotificationPermission');
        
        // For iOS, also initialize FCM service and generate token if permission granted
        if (isGranted) {
          try {
            await UnifiedFcmService.instance.initialize();
            
            // Generate and save token immediately after permission grant
            final token = await UnifiedFcmService.instance.generateTokenAndEnsureSaved();
            if (token != null) {
              AppLogger.success('FCM token generated and saved after iOS permission grant', tag: 'NotificationPermission');
            } else {
              AppLogger.warning('FCM token generation failed after iOS permission grant', tag: 'NotificationPermission');
            }
          } catch (e) {
            AppLogger.warning('FCM initialization failed after permission grant: $e', tag: 'NotificationPermission');
          }
        }
      } else if (Platform.isAndroid) {
        // Request permission via permission_handler for Android
        final status = await Permission.notification.request();
        isGranted = status.isGranted;
        
        AppLogger.info('Android permission request result: $status, granted: $isGranted', tag: 'NotificationPermission');
        
        // For Android, also initialize FCM service and generate token if permission granted
        if (isGranted) {
          try {
            await UnifiedFcmService.instance.initialize();
            
            // Generate and save token immediately after permission grant
            final token = await UnifiedFcmService.instance.generateTokenAndEnsureSaved();
            if (token != null) {
              AppLogger.success('FCM token generated and saved after Android permission grant', tag: 'NotificationPermission');
            } else {
              AppLogger.warning('FCM token generation failed after Android permission grant', tag: 'NotificationPermission');
            }
          } catch (e) {
            AppLogger.warning('FCM initialization failed after permission grant: $e', tag: 'NotificationPermission');
          }
        }
      }
      
      // Save the result to local storage
      await _prefsHelper.setNotificationPermissionGranted(isGranted);
      
      AppLogger.info('Permission request completed. Granted: $isGranted', tag: 'NotificationPermission');
      return isGranted;
    } catch (e) {
      AppLogger.error('Error requesting notification permission: $e', tag: 'NotificationPermission');
      await _prefsHelper.setNotificationPermissionGranted(false);
      return false;
    }
  }

  /// Reset permission tracking (useful for testing)
  Future<void> resetPermissionTracking() async {
    try {
      await _prefsHelper.setNotificationPermissionPrompted(false);
      await _prefsHelper.setNotificationPermissionGranted(false);
      AppLogger.info('Notification permission tracking reset', tag: 'NotificationPermission');
    } catch (e) {
      AppLogger.error('Error resetting permission tracking: $e', tag: 'NotificationPermission');
    }
  }

  /// Get current permission tracking status (for debugging)
  Future<Map<String, dynamic>> getPermissionStatus() async {
    try {
      final hasBeenPrompted = await _prefsHelper.hasNotificationPermissionBeenPrompted();
      final isGranted = await _prefsHelper.isNotificationPermissionGranted();
      final currentSystemStatus = await _getCurrentPermissionStatus();
      
      return {
        'hasBeenPrompted': hasBeenPrompted,
        'isGrantedInStorage': isGranted,
        'currentSystemStatus': currentSystemStatus,
        'shouldShowDialog': await shouldShowPermissionDialog(),
        'platform': Platform.isIOS ? 'iOS' : 'Android',
      };
    } catch (e) {
      AppLogger.error('Error getting permission status: $e', tag: 'NotificationPermission');
      return {'error': e.toString()};
    }
  }
}