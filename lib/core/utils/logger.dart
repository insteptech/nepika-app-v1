import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class Logger {
  static const String _tag = 'NepikaApp';
  static bool _enabledInRelease = false;

  static void setReleaseLogging(bool enabled) {
    _enabledInRelease = enabled;
  }

  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Only log in debug mode or if explicitly enabled in release
    if (!kDebugMode && !_enabledInRelease) return;

    final tagString = tag ?? _tag;
    final levelString = level.name.toUpperCase();
    final timestamp = DateTime.now().toIso8601String();
    
    String logMessage = '[$timestamp] [$tagString] [$levelString] $message';
    
    if (error != null) {
      logMessage += '\nError: $error';
    }
    
    if (stackTrace != null) {
      logMessage += '\nStackTrace: $stackTrace';
    }

    // Use different logging methods based on level
    switch (level) {
      case LogLevel.debug:
        developer.log(logMessage, name: tagString, level: 500);
        break;
      case LogLevel.info:
        developer.log(logMessage, name: tagString, level: 800);
        break;
      case LogLevel.warning:
        developer.log(logMessage, name: tagString, level: 900);
        break;
      case LogLevel.error:
        developer.log(logMessage, name: tagString, level: 1000, error: error, stackTrace: stackTrace);
        break;
    }
  }

  // Convenient methods for specific domains
  static void network(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: '${_tag}_Network', error: error, stackTrace: stackTrace);
  }

  static void bloc(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: '${_tag}_Bloc', error: error, stackTrace: stackTrace);
  }

  static void repository(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: '${_tag}_Repository', error: error, stackTrace: stackTrace);
  }

  static void useCase(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: '${_tag}_UseCase', error: error, stackTrace: stackTrace);
  }
}