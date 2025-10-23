import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import '../utils/app_logger.dart';
import '../../firebase_options.dart';

/// Background message handler for FCM
/// This must be a top-level function for Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Initialize Firebase if not already done
    try {
      Firebase.app(); // Check if already initialized
    } catch (e) {
      // Not initialized, initialize now
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    AppLogger.info(
      'Background message received: ${message.messageId}',
      tag: 'FCM_BG',
    );

    // Log message details
    if (message.notification != null) {
      AppLogger.info(
        'Background notification - Title: ${message.notification?.title}, '
        'Body: ${message.notification?.body}',
        tag: 'FCM_BG',
      );
    }

    if (message.data.isNotEmpty) {
      AppLogger.info(
        'Background message data: ${message.data}',
        tag: 'FCM_BG',
      );
    }

    // You can perform background processing here
    // Note: This runs in a separate isolate, so you have limited capabilities
    // - No UI updates
    // - Limited local storage access
    // - No navigation
    
    // Example: Save notification for later processing
    await _processBackgroundNotification(message);

  } catch (e, stackTrace) {
    AppLogger.error(
      'Background message handler failed',
      tag: 'FCM_BG',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

/// Process background notification
/// This can include saving data, updating local storage, etc.
Future<void> _processBackgroundNotification(RemoteMessage message) async {
  try {
    // Example processing:
    // 1. Save notification to local storage for later display
    // 2. Update app badge count
    // 3. Perform data synchronization
    // 4. Send analytics events
    
    AppLogger.info(
      'Background notification processed: ${message.messageId}',
      tag: 'FCM_BG',
    );
  } catch (e) {
    AppLogger.error(
      'Background notification processing failed',
      tag: 'FCM_BG',
      error: e,
    );
  }
}