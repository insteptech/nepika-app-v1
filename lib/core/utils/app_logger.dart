import 'package:flutter/foundation.dart';

/// Centralized logging utility for the app
/// Only logs in debug mode to avoid performance impact in production
class AppLogger {
  static const bool _enableLogging = kDebugMode;

  /// Log debug information
  static void debug(String message, {String? tag}) {
    if (_enableLogging) {
      final logTag = tag != null ? '[$tag]' : '';
      debugPrint('🔵 DEBUG $logTag: $message');
    }
  }

  /// Log informational messages
  static void info(String message, {String? tag}) {
    if (_enableLogging) {
      final logTag = tag != null ? '[$tag]' : '';
      debugPrint('ℹ️  INFO $logTag: $message');
    }
  }

  /// Log warnings
  static void warning(String message, {String? tag}) {
    if (_enableLogging) {
      final logTag = tag != null ? '[$tag]' : '';
      debugPrint('⚠️  WARNING $logTag: $message');
    }
  }

  /// Log errors
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (_enableLogging) {
      final logTag = tag != null ? '[$tag]' : '';
      debugPrint('❌ ERROR $logTag: $message');
      if (error != null) {
        debugPrint('   Error details: $error');
      }
      if (stackTrace != null) {
        debugPrint('   Stack trace: $stackTrace');
      }
    }
  }

  /// Log FCM-specific messages
  static void fcm(String message, {bool isError = false}) {
    if (_enableLogging) {
      final prefix = isError ? '❌ FCM ERROR' : '🔔 FCM';
      debugPrint('$prefix: $message');
    }
  }

  /// Log success messages
  static void success(String message, {String? tag}) {
    if (_enableLogging) {
      final logTag = tag != null ? '[$tag]' : '';
      debugPrint('✅ SUCCESS $logTag: $message');
    }
  }
}
