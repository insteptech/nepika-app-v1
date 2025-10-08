import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'platform_otp_service_interface.dart';
import 'otp_extraction_service.dart';
import 'sms_buffer_service.dart';

class IosOtpService implements PlatformOtpServiceInterface {
  static const int _defaultTimeoutSeconds = 45;
  static const String _permissionStateKey = 'ios_sms_permission_state';
  
  Timer? _timeoutTimer;
  bool _isListening = false;
  String? _currentPhoneNumber;
  
  // Callback functions
  Function(OtpResult)? _onOtpReceived;
  Function()? _onTimeout;
  Function(OtpError)? _onError;

  @override
  bool get isSupported => Platform.isIOS;

  @override
  String get platformName => 'iOS';

  @override
  bool get isListening => _isListening;

  @override
  Future<OtpPermissionStatus> checkPermissionStatus() async {
    try {
      // On iOS, SMS AutoFill doesn't require explicit permissions
      // The system handles it automatically through TextContentType.oneTimeCode
      debugPrint('IosOtpService: iOS SMS AutoFill is system-managed, no explicit permissions needed');
      
      await _savePermissionState(OtpPermissionStatus.granted);
      return OtpPermissionStatus.granted;
    } catch (e) {
      debugPrint('IosOtpService: Error checking permission status: $e');
      return OtpPermissionStatus.unknown;
    }
  }

  @override
  Future<OtpPermissionStatus> requestPermissions() async {
    try {
      debugPrint('IosOtpService: iOS uses system-managed SMS AutoFill');
      
      // iOS doesn't require explicit permission request for SMS AutoFill
      // The system will automatically suggest OTP codes when detected
      await _savePermissionState(OtpPermissionStatus.granted);
      
      // Check for cached OTP
      await _checkForCachedOtp();
      
      return OtpPermissionStatus.granted;
    } catch (e) {
      debugPrint('IosOtpService: Error in permission handling: $e');
      return OtpPermissionStatus.unknown;
    }
  }

  @override
  Future<void> startListening({
    required Function(OtpResult) onOtpReceived,
    required Function() onTimeout,
    required Function(OtpError) onError,
    int timeoutSeconds = _defaultTimeoutSeconds,
  }) async {
    if (_isListening) {
      stopListening();
    }

    _onOtpReceived = onOtpReceived;
    _onTimeout = onTimeout;
    _onError = onError;

    _isListening = true;
    
    try {
      debugPrint('IosOtpService: Starting iOS SMS AutoFill monitoring...');
      
      // Start timeout timer
      _timeoutTimer = Timer(Duration(seconds: timeoutSeconds), () {
        debugPrint('IosOtpService: Timeout reached after $timeoutSeconds seconds');
        _handleTimeout();
      });

      // Check for cached OTP immediately
      await _checkForCachedOtp();
      
      debugPrint('IosOtpService: iOS SMS monitoring active (system-managed)');
      debugPrint('IosOtpService: Make sure OTP input fields use TextContentType.oneTimeCode');
      
    } catch (e) {
      debugPrint('IosOtpService: Error starting SMS monitoring: $e');
      _isListening = false;
      _onError?.call(OtpError(
        message: 'Failed to start SMS monitoring: $e',
        code: 'START_LISTENING_ERROR',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Manually process OTP when detected by iOS system autofill
  void processDetectedOtp(String otp) {
    if (!_isListening) return;
    
    debugPrint('IosOtpService: Processing iOS system-detected OTP: "$otp"');
    
    // Validate the OTP
    if (otp.length == 6 && RegExp(r'^\d{6}$').hasMatch(otp)) {
      debugPrint('IosOtpService: Valid OTP detected via iOS system autofill');
      
      // Buffer the OTP
      if (_currentPhoneNumber != null) {
        SmsBufferService.instance.bufferSms(
          _currentPhoneNumber!,
          otp,
          'iOS System AutoFill detected OTP',
        );
      }
      
      final result = OtpResult(
        otp: otp,
        method: OtpCaptureMethod.textContentType,
        timestamp: DateTime.now(),
      );
      
      _handleOtpFound(result);
    } else {
      debugPrint('IosOtpService: Invalid OTP format detected: "$otp"');
    }
  }

  /// Process SMS content manually (for when SMS content is available)
  void processSmsContent(String smsContent) {
    if (!_isListening) return;
    
    debugPrint('IosOtpService: Processing SMS content: "$smsContent"');
    
    // Extract OTP from SMS content
    final extractionResult = OtpExtractionService.extractOtp(smsContent);
    
    if (extractionResult.isValid) {
      debugPrint('IosOtpService: Successfully extracted OTP from SMS: ${extractionResult.otp}');
      
      // Buffer the SMS
      if (_currentPhoneNumber != null) {
        SmsBufferService.instance.bufferSms(
          _currentPhoneNumber!,
          extractionResult.otp!,
          smsContent,
        );
      }
      
      final result = OtpResult(
        otp: extractionResult.otp!,
        method: OtpCaptureMethod.textContentType,
        timestamp: DateTime.now(),
      );
      
      _handleOtpFound(result);
    } else {
      debugPrint('IosOtpService: No valid OTP found in SMS content');
    }
  }

  void _handleOtpFound(OtpResult result) {
    if (!_isListening) return;
    
    debugPrint('IosOtpService: OTP found - cleaning up and notifying');
    _cleanup();
    _onOtpReceived?.call(result);
  }

  void _handleTimeout() {
    if (!_isListening) return;
    
    debugPrint('IosOtpService: Handling timeout');
    _cleanup();
    _onTimeout?.call();
  }

  @override
  void stopListening() {
    debugPrint('IosOtpService: Stopping SMS monitoring');
    _cleanup();
  }

  @override
  Future<OtpResult?> getCachedOtp() async {
    if (_currentPhoneNumber != null) {
      return await SmsBufferService.instance.getCachedOtp(_currentPhoneNumber!);
    }
    return null;
  }

  @override
  Future<void> clearCache() async {
    await SmsBufferService.instance.clearBuffer();
  }

  void setCurrentPhoneNumber(String phoneNumber) {
    _currentPhoneNumber = phoneNumber;
    debugPrint('IosOtpService: Set current phone number: $phoneNumber');
  }

  Future<void> _checkForCachedOtp() async {
    if (_currentPhoneNumber != null) {
      final cachedResult = await getCachedOtp();
      if (cachedResult != null && _isListening) {
        debugPrint('IosOtpService: Found cached OTP: ${cachedResult.otp}');
        _handleOtpFound(cachedResult);
      }
    }
  }

  Future<void> _savePermissionState(OtpPermissionStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_permissionStateKey, status.toString());
    } catch (e) {
      debugPrint('IosOtpService: Error saving permission state: $e');
    }
  }

  void _cleanup() {
    _isListening = false;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  @override
  void dispose() {
    debugPrint('IosOtpService: Disposing');
    _cleanup();
    _onOtpReceived = null;
    _onTimeout = null;
    _onError = null;
  }
}