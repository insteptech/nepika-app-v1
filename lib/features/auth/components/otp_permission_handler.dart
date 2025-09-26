import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/otp_service.dart';

class OtpPermissionHandler {
  static Future<bool> showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Auto-capture OTP?'),
          content: const Text(
            'Would you like to automatically capture the OTP from the SMS we\'re sending? This will require SMS permission.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Enter Manually'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Auto-capture'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  static void showPermissionDeniedDialog(BuildContext context, VoidCallback onRetry) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('SMS Permission Required'),
          content: const Text(
            'To automatically capture OTP from SMS, we need permission to access your messages. You can still enter the OTP manually if you prefer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Enter Manually'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Grant Permission'),
            ),
          ],
        );
      },
    );
  }

  static void showPermissionPermanentlyDeniedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Permanently Denied'),
          content: const Text(
            'SMS permission has been permanently denied. To enable auto-capture, please go to Settings and grant SMS permission manually.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> handlePermissionRequest(BuildContext context) async {
    final otpService = OtpService();
    
    debugPrint('OtpPermissionHandler: Checking current SMS permission status');
    final hasPermission = await otpService.checkSmsPermission();
    if (hasPermission) {
      debugPrint('OtpPermissionHandler: SMS permission already granted');
      return true;
    }

    debugPrint('OtpPermissionHandler: Requesting SMS permission');
    final granted = await otpService.requestSmsPermission();
    if (granted) {
      debugPrint('OtpPermissionHandler: SMS permission granted successfully');
      return true;
    }

    debugPrint('OtpPermissionHandler: SMS permission request failed');
    final permissionStatus = await Permission.sms.status;
    debugPrint('OtpPermissionHandler: Current permission status: $permissionStatus');
    
    // Check if context is still mounted before using it
    if (!context.mounted) {
      debugPrint('OtpPermissionHandler: Context no longer mounted');
      return false;
    }
    
    if (permissionStatus.isPermanentlyDenied) {
      debugPrint('OtpPermissionHandler: Permission permanently denied, showing settings dialog');
      showPermissionPermanentlyDeniedDialog(context);
    } else {
      debugPrint('OtpPermissionHandler: Permission denied, showing retry dialog');
      showPermissionDeniedDialog(context, () {
        handlePermissionRequest(context);
      });
    }

    return false;
  }
}