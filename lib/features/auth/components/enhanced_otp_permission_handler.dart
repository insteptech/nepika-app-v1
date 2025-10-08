import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
// import '../services/unified_otp_service.dart';
import '../services/platform_otp_service_interface.dart';

class EnhancedOtpPermissionHandler {
  static Future<bool> showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.sms,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('Auto-fill OTP?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Platform.isIOS 
                  ? 'Let iOS automatically suggest your OTP code?'
                  : 'Automatically detect OTP from SMS?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.speed, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    const Text(
                      'Faster login • No typing required',
                      style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Manual'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(Platform.isIOS ? 'Enable' : 'Allow'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  static void showPermissionDeniedDialog(
    BuildContext context, 
    OtpPermissionStatus status,
    VoidCallback onRetry,
  ) {
    String title;
    String content;
    String retryButtonText;

    if (Platform.isIOS) {
      title = 'SMS AutoFill Not Available';
      content = 'iOS will automatically suggest OTP codes when available. No additional permissions are needed. You can enter the OTP manually if the suggestion doesn\'t appear.';
      retryButtonText = 'Try Again';
    } else {
      switch (status) {
        case OtpPermissionStatus.permanentlyDenied:
          title = 'SMS Permission Permanently Denied';
          content = 'SMS permission has been permanently denied. To enable auto-capture, please go to Settings and grant SMS permission manually.';
          retryButtonText = 'Open Settings';
          break;
        case OtpPermissionStatus.restricted:
          title = 'SMS Permission Restricted';
          content = 'SMS permission is restricted on this device. Auto-capture may not be available. You can still enter the OTP manually.';
          retryButtonText = 'Try Again';
          break;
        default:
          title = 'SMS Permission Required';
          content = 'To automatically capture OTP from SMS, we need permission to access your messages. This helps you avoid typing the OTP manually.';
          retryButtonText = 'Grant Permission';
      }
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                status == OtpPermissionStatus.permanentlyDenied 
                    ? Icons.settings 
                    : Icons.sms_failed,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(content),
              if (!Platform.isIOS) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.security, size: 16, color: Colors.green),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'We only read SMS to detect OTP codes. Your privacy is protected.',
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Enter Manually'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (status == OtpPermissionStatus.permanentlyDenied) {
                  openAppSettings();
                } else {
                  onRetry();
                }
              },
              child: Text(retryButtonText),
            ),
          ],
        );
      },
    );
  }

  static void showRetryDialog(
    BuildContext context,
    int currentRetry,
    int maxRetries,
    VoidCallback onRetry,
    VoidCallback onCancel,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Retrying Auto-capture'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Attempting to start OTP auto-capture...\n'
                'Retry $currentRetry of $maxRetries',
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: currentRetry / maxRetries,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onCancel();
              },
              child: const Text('Cancel'),
            ),
            if (currentRetry < maxRetries)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: const Text('Retry Now'),
              ),
          ],
        );
      },
    );
  }

  static void showSuccessDialog(BuildContext context, String otp) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.flash_on, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('Auto-filled: $otp'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showErrorDialog(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Auto-capture failed: $error')),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static Future<bool> handlePermissionRequest(BuildContext context) async {
    debugPrint('EnhancedOtpPermissionHandler: Checking SMS permission status for SMS AutoFill');
    
    // Check SMS permission directly
    final smsStatus = await Permission.sms.status;
    debugPrint('EnhancedOtpPermissionHandler: SMS permission status: $smsStatus');
    
    if (smsStatus.isGranted) {
      debugPrint('EnhancedOtpPermissionHandler: SMS permission already granted');
      return true;
    }

    debugPrint('EnhancedOtpPermissionHandler: Requesting SMS permission');
    final grantedStatus = await Permission.sms.request();
    
    if (grantedStatus.isGranted) {
      debugPrint('EnhancedOtpPermissionHandler: SMS permission granted successfully');
      return true;
    }

    debugPrint('EnhancedOtpPermissionHandler: SMS permission request failed with status: $grantedStatus');
    
    // Don't show dialog automatically - let the caller handle it
    return false;
  }

  static Widget buildPlatformIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Platform.isIOS ? Colors.blue.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Platform.isIOS ? Colors.blue.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Platform.isIOS ? Icons.phone_iphone : Icons.android,
            size: 14,
            color: Platform.isIOS ? Colors.blue[600] : Colors.green[600],
          ),
          const SizedBox(width: 4),
          Text(
            Platform.isIOS ? 'iOS AutoFill' : 'Android SMS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Platform.isIOS ? Colors.blue[600] : Colors.green[600],
            ),
          ),
        ],
      ),
    );
  }
}