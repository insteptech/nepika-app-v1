import 'dart:async';

enum OtpPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unknown
}

enum OtpCaptureMethod {
  smsListener,
  textContentType,
  manual,
  cached
}

class OtpResult {
  final String otp;
  final OtpCaptureMethod method;
  final DateTime timestamp;

  OtpResult({
    required this.otp,
    required this.method,
    required this.timestamp,
  });
}

class OtpError {
  final String message;
  final String code;
  final Exception? exception;

  OtpError({
    required this.message,
    required this.code,
    this.exception,
  });
}

abstract class PlatformOtpServiceInterface {
  /// Check if OTP auto-capture is supported on current platform
  bool get isSupported;
  
  /// Get current platform name
  String get platformName;
  
  /// Check permission status for SMS reading
  Future<OtpPermissionStatus> checkPermissionStatus();
  
  /// Request SMS reading permissions
  Future<OtpPermissionStatus> requestPermissions();
  
  /// Start listening for OTP with comprehensive error handling
  Future<void> startListening({
    required Function(OtpResult) onOtpReceived,
    required Function() onTimeout,
    required Function(OtpError) onError,
    int timeoutSeconds = 45,
  });
  
  /// Stop listening for OTP
  void stopListening();
  
  /// Get cached OTP if available (for late permission scenarios)
  Future<OtpResult?> getCachedOtp();
  
  /// Clear cached OTP
  Future<void> clearCache();
  
  /// Check if currently listening
  bool get isListening;
  
  /// Dispose resources
  void dispose();
}