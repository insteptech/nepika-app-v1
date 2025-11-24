import 'package:flutter/material.dart';
import '../services/notification_permission_service.dart';
import '../utils/app_logger.dart';
import '../utils/shared_prefs_helper.dart';

/// Dialog to request notification permissions from users
/// Designed with iOS notification permission issues in mind
class NotificationPermissionDialog extends StatelessWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const NotificationPermissionDialog({
    super.key,
    this.onPermissionGranted,
    this.onPermissionDenied,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.notifications_outlined,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Stay Updated!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              'Get notified about new posts, comments, and community updates. You can change this anytime in settings.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                // Not Now button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleNotNow(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Not Now',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Allow button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAllow(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      // foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Allow',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotNow(BuildContext context) async {
    try {
      AppLogger.info('User selected "Not Now" for notifications', tag: 'NotificationPermission');
      
      // Mark as prompted but not granted without actually requesting permission
      final prefsHelper = SharedPrefsHelper();
      await prefsHelper.setNotificationPermissionPrompted(true);
      await prefsHelper.setNotificationPermissionGranted(false);
      
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      onPermissionDenied?.call();
    } catch (e) {
      AppLogger.error('Error handling "Not Now" selection: $e', tag: 'NotificationPermission');
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleAllow(BuildContext context) async {
    try {
      AppLogger.info('User selected "Allow" for notifications', tag: 'NotificationPermission');
      
      // Close dialog first to prevent UI blocking
      Navigator.of(context).pop();
      
      // Request permission
      final permissionService = NotificationPermissionService.instance;
      final isGranted = await permissionService.requestNotificationPermission();
      
      if (isGranted) {
        AppLogger.info('Notification permission granted', tag: 'NotificationPermission');
        onPermissionGranted?.call();
        
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Notifications enabled! You\'ll receive updates about community activity.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        AppLogger.info('Notification permission denied', tag: 'NotificationPermission');
        onPermissionDenied?.call();
        
        // Show info message about settings
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('You can enable notifications anytime in Settings → Notifications.'),
              backgroundColor: Theme.of(context).colorScheme.surface,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error handling "Allow" selection: $e', tag: 'NotificationPermission');
      onPermissionDenied?.call();
    }
  }
}

/// Utility class to show notification permission dialog
class NotificationPermissionHelper {
  /// Show notification permission dialog if needed
  /// Returns true if dialog was shown, false if not needed
  static Future<bool> showPermissionDialogIfNeeded(BuildContext context) async {
    try {
      final permissionService = NotificationPermissionService.instance;
      final shouldShow = await permissionService.shouldShowPermissionDialog();
      
      if (shouldShow && context.mounted) {
        AppLogger.info('Showing notification permission dialog', tag: 'NotificationPermission');
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const NotificationPermissionDialog(),
        );
        
        return true;
      } else {
        AppLogger.info('Notification permission dialog not needed', tag: 'NotificationPermission');
        return false;
      }
    } catch (e) {
      AppLogger.error('Error showing notification permission dialog: $e', tag: 'NotificationPermission');
      return false;
    }
  }
}