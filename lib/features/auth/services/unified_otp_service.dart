import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'platform_otp_service_interface.dart';
import 'android_otp_service.dart';
import 'ios_otp_service.dart';
import 'sms_buffer_service.dart';

class UnifiedOtpService implements PlatformOtpServiceInterface {
  static UnifiedOtpService? _instance;
  static UnifiedOtpService get instance => _instance ??= UnifiedOtpService._();
  
  UnifiedOtpService._() {
    _initializePlatformService();
  }

  PlatformOtpServiceInterface? _platformService;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  
  Timer? _retryTimer;
  String? _currentPhoneNumber;
  
  // Current operation callbacks for retry mechanism
  Function(OtpResult)? _currentOnOtpReceived;
  Function()? _currentOnTimeout;
  Function(OtpError)? _currentOnError;
  int _currentTimeoutSeconds = 45;

  void _initializePlatformService() {
    if (Platform.isAndroid) {
      _platformService = AndroidOtpService();
      debugPrint('UnifiedOtpService: Initialized Android OTP service');
    } else if (Platform.isIOS) {
      _platformService = IosOtpService();
      debugPrint('UnifiedOtpService: Initialized iOS OTP service');
    } else {
      debugPrint('UnifiedOtpService: Unsupported platform');
    }
  }

  @override
  bool get isSupported => _platformService?.isSupported ?? false;

  @override
  String get platformName => _platformService?.platformName ?? 'Unknown';

  @override
  bool get isListening => _platformService?.isListening ?? false;

  @override
  Future<OtpPermissionStatus> checkPermissionStatus() async {
    if (_platformService == null) {
      return OtpPermissionStatus.unknown;
    }
    
    try {
      return await _platformService!.checkPermissionStatus();
    } catch (e) {
      debugPrint('UnifiedOtpService: Error checking permission status: $e');
      return OtpPermissionStatus.unknown;
    }
  }

  @override
  Future<OtpPermissionStatus> requestPermissions() async {
    if (_platformService == null) {
      return OtpPermissionStatus.unknown;
    }
    
    try {
      final status = await _platformService!.requestPermissions();
      
      // Set phone number for platform services
      if (_currentPhoneNumber != null) {
        _setPhoneNumberOnPlatformService(_currentPhoneNumber!);
      }
      
      return status;
    } catch (e) {
      debugPrint('UnifiedOtpService: Error requesting permissions: $e');
      return OtpPermissionStatus.unknown;
    }
  }

  @override
  Future<void> startListening({
    required Function(OtpResult) onOtpReceived,
    required Function() onTimeout,
    required Function(OtpError) onError,
    int timeoutSeconds = 45,
  }) async {
    if (_platformService == null) {
      onError(OtpError(
        message: 'Platform not supported',
        code: 'PLATFORM_NOT_SUPPORTED',
      ));
      return;
    }

    // Store callbacks for retry mechanism
    _currentOnOtpReceived = onOtpReceived;
    _currentOnTimeout = onTimeout;
    _currentOnError = onError;
    _currentTimeoutSeconds = timeoutSeconds;
    _retryCount = 0;

    await _attemptStartListening();
  }

  Future<void> _attemptStartListening() async {
    if (_platformService == null) return;

    try {
      debugPrint('UnifiedOtpService: Starting listening attempt ${_retryCount + 1}/${_maxRetries + 1}');
      
      await _platformService!.startListening(
        onOtpReceived: (result) {
          debugPrint('UnifiedOtpService: OTP received successfully: ${result.otp}');
          _resetRetryState();
          _currentOnOtpReceived?.call(result);
        },
        onTimeout: () {
          debugPrint('UnifiedOtpService: Timeout occurred');
          _handleTimeoutWithRetry();
        },
        onError: (error) {
          debugPrint('UnifiedOtpService: Error occurred: ${error.message}');
          _handleErrorWithRetry(error);
        },
        timeoutSeconds: _currentTimeoutSeconds,
      );
      
    } catch (e) {
      debugPrint('UnifiedOtpService: Exception during start listening: $e');
      _handleErrorWithRetry(OtpError(
        message: 'Failed to start listening: $e',
        code: 'START_LISTENING_EXCEPTION',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  void _handleTimeoutWithRetry() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      debugPrint('UnifiedOtpService: Retrying after timeout (attempt $_retryCount/$_maxRetries)');
      
      _retryTimer = Timer(_retryDelay, () {
        _attemptStartListening();
      });
    } else {
      debugPrint('UnifiedOtpService: Max retries reached, calling timeout callback');
      _resetRetryState();
      _currentOnTimeout?.call();
    }
  }

  void _handleErrorWithRetry(OtpError error) {
    // Don't retry permission errors
    if (error.code == 'PERMISSION_DENIED' || error.code.contains('PERMISSION')) {
      debugPrint('UnifiedOtpService: Permission error, not retrying');
      _resetRetryState();
      _currentOnError?.call(error);
      return;
    }

    if (_retryCount < _maxRetries) {
      _retryCount++;
      debugPrint('UnifiedOtpService: Retrying after error (attempt $_retryCount/$_maxRetries): ${error.message}');
      
      _retryTimer = Timer(_retryDelay, () {
        _attemptStartListening();
      });
    } else {
      debugPrint('UnifiedOtpService: Max retries reached, calling error callback');
      _resetRetryState();
      _currentOnError?.call(error);
    }
  }

  void _resetRetryState() {
    _retryCount = 0;
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  @override
  void stopListening() {
    debugPrint('UnifiedOtpService: Stopping listening and resetting retry state');
    _resetRetryState();
    _platformService?.stopListening();
  }

  @override
  Future<OtpResult?> getCachedOtp() async {
    if (_currentPhoneNumber != null) {
      // Try platform service first
      final platformResult = await _platformService?.getCachedOtp();
      if (platformResult != null) {
        return platformResult;
      }
      
      // Try buffer service as fallback
      return await SmsBufferService.instance.getCachedOtp(_currentPhoneNumber!);
    }
    return null;
  }

  @override
  Future<void> clearCache() async {
    await _platformService?.clearCache();
    await SmsBufferService.instance.clearBuffer();
  }

  /// Set current phone number for OTP session
  void setPhoneNumber(String phoneNumber) {
    _currentPhoneNumber = phoneNumber;
    _setPhoneNumberOnPlatformService(phoneNumber);
    debugPrint('UnifiedOtpService: Set phone number: $phoneNumber');
  }

  void _setPhoneNumberOnPlatformService(String phoneNumber) {
    if (_platformService is AndroidOtpService) {
      (_platformService as AndroidOtpService).setCurrentPhoneNumber(phoneNumber);
    } else if (_platformService is IosOtpService) {
      (_platformService as IosOtpService).setCurrentPhoneNumber(phoneNumber);
    }
  }

  /// Process OTP manually detected by iOS system autofill
  void processDetectedOtp(String otp) {
    if (_platformService is IosOtpService) {
      (_platformService as IosOtpService).processDetectedOtp(otp);
    } else {
      debugPrint('UnifiedOtpService: processDetectedOtp called on non-iOS platform');
    }
  }

  /// Process SMS content manually
  void processSmsContent(String smsContent) {
    if (_platformService is IosOtpService) {
      (_platformService as IosOtpService).processSmsContent(smsContent);
    } else if (_platformService is AndroidOtpService) {
      // Could be used for additional SMS processing on Android
      debugPrint('UnifiedOtpService: SMS content processing on Android: $smsContent');
    }
  }

  /// Check if there are any cached OTPs available
  Future<bool> hasCachedOtp() async {
    return await SmsBufferService.instance.hasCachedOtp();
  }

  /// Get platform-specific guidance for user
  String getPlatformGuidance() {
    if (Platform.isIOS) {
      return 'On iOS, OTP codes will be automatically suggested by the system when you receive an SMS. Tap the suggestion above the keyboard to auto-fill.';
    } else if (Platform.isAndroid) {
      return 'On Android, we\'ll automatically detect and fill the OTP from your SMS messages. Make sure to grant SMS permission when prompted.';
    } else {
      return 'Platform-specific OTP auto-capture is not available. Please enter the OTP manually.';
    }
  }

  /// Get current retry information
  Map<String, dynamic> getRetryInfo() {
    return {
      'currentRetry': _retryCount,
      'maxRetries': _maxRetries,
      'isRetrying': _retryTimer != null,
      'retryDelay': _retryDelay.inSeconds,
    };
  }

  @override
  void dispose() {
    debugPrint('UnifiedOtpService: Disposing');
    _resetRetryState();
    _platformService?.dispose();
    _currentOnOtpReceived = null;
    _currentOnTimeout = null;
    _currentOnError = null;
  }
}