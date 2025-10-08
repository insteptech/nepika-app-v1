import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:telephony/telephony.dart';

import 'platform_otp_service_interface.dart';
import 'otp_extraction_service.dart';
import 'sms_buffer_service.dart';

class AndroidOtpService implements PlatformOtpServiceInterface {
  static const int _defaultTimeoutSeconds = 45;
  static const String _permissionStateKey = 'android_sms_permission_state';
  
  Timer? _timeoutTimer;
  StreamSubscription? _smsSubscription;
  bool _isListening = false;
  String? _currentPhoneNumber;
  
  // Callback functions
  Function(OtpResult)? _onOtpReceived;
  Function()? _onTimeout;
  Function(OtpError)? _onError;

  @override
  bool get isSupported => Platform.isAndroid;

  @override
  String get platformName => 'Android';

  @override
  bool get isListening => _isListening;

  @override
  Future<OtpPermissionStatus> checkPermissionStatus() async {
    try {
      final smsStatus = await Permission.sms.status;
      final phoneStatus = await Permission.phone.status;
      
      debugPrint('AndroidOtpService: SMS permission: $smsStatus, Phone permission: $phoneStatus');
      
      if (smsStatus.isGranted) {
        await _savePermissionState(OtpPermissionStatus.granted);
        return OtpPermissionStatus.granted;
      } else if (smsStatus.isPermanentlyDenied) {
        await _savePermissionState(OtpPermissionStatus.permanentlyDenied);
        return OtpPermissionStatus.permanentlyDenied;
      } else if (smsStatus.isDenied) {
        await _savePermissionState(OtpPermissionStatus.denied);
        return OtpPermissionStatus.denied;
      } else if (smsStatus.isRestricted) {
        await _savePermissionState(OtpPermissionStatus.restricted);
        return OtpPermissionStatus.restricted;
      }
      
      return OtpPermissionStatus.unknown;
    } catch (e) {
      debugPrint('AndroidOtpService: Error checking permission status: $e');
      return OtpPermissionStatus.unknown;
    }
  }

  @override
  Future<OtpPermissionStatus> requestPermissions() async {
    try {
      debugPrint('AndroidOtpService: Requesting SMS and phone permissions...');
      
      Map<Permission, PermissionStatus> permissions = await [
        Permission.sms,
        Permission.phone,
      ].request();
      
      final smsGranted = permissions[Permission.sms]?.isGranted ?? false;
      final phoneGranted = permissions[Permission.phone]?.isGranted ?? false;
      
      debugPrint('AndroidOtpService: Permission results - SMS: $smsGranted, Phone: $phoneGranted');
      
      if (smsGranted) {
        await _savePermissionState(OtpPermissionStatus.granted);
        
        // Check for cached OTP after permission grant
        await _checkForCachedOtp();
        
        return OtpPermissionStatus.granted;
      }
      
      final status = await checkPermissionStatus();
      await _savePermissionState(status);
      return status;
    } catch (e) {
      debugPrint('AndroidOtpService: Error requesting permissions: $e');
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

    // Check permissions first
    final permissionStatus = await checkPermissionStatus();
    if (permissionStatus != OtpPermissionStatus.granted) {
      debugPrint('AndroidOtpService: SMS permission not granted, cannot start listening');
      _onError?.call(OtpError(
        message: 'SMS permission not granted',
        code: 'PERMISSION_DENIED',
      ));
      return;
    }

    _isListening = true;
    
    try {
      debugPrint('AndroidOtpService: Starting comprehensive SMS listening...');
      
      // Start timeout timer
      _timeoutTimer = Timer(Duration(seconds: timeoutSeconds), () {
        debugPrint('AndroidOtpService: Timeout reached after $timeoutSeconds seconds');
        _handleTimeout();
      });

      // Start SMS AutoFill listener
      await _startSmsAutoFill();
      
      debugPrint('AndroidOtpService: SMS listener active');
      
    } catch (e) {
      debugPrint('AndroidOtpService: Error starting SMS listening: $e');
      _isListening = false;
      _onError?.call(OtpError(
        message: 'Failed to start SMS listening: $e',
        code: 'START_LISTENING_ERROR',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  Future<void> _startSmsAutoFill() async {
    try {
      debugPrint('AndroidOtpService: Starting SmsAutoFill listener...');
      
      // Get app signature for debugging
      try {
        final signature = await SmsAutoFill().getAppSignature;
        debugPrint('AndroidOtpService: App signature: $signature');
      } catch (e) {
        debugPrint('AndroidOtpService: Could not get app signature: $e');
      }
      
      // Multiple SMS listening strategies for better compatibility
      await _setupMultipleSmsListeners();
      
      // Primary SMS code listener
      _smsSubscription = SmsAutoFill().code.listen(
        (code) {
          debugPrint('🔥🔥 AndroidOtpService: SMS RECEIVED VIA PRIMARY LISTENER! 🔥🔥');
          debugPrint('📱 Raw SMS content: "$code"');
          debugPrint('📏 SMS length: ${code?.length ?? 0}');
          debugPrint('❓ SMS is empty: ${code?.isEmpty ?? true}');
          debugPrint('🔍 SMS contains "OTP": ${code?.contains("OTP") ?? false}');
          debugPrint('🔍 SMS contains "code": ${code?.contains("code") ?? false}');
          debugPrint('🔍 SMS contains "<#>": ${code?.contains("<#>") ?? false}');
          debugPrint('🔍 SMS contains app signature: ${code?.contains("pRsNh+4imYr") ?? false}');
          
          if (code != null && code.isNotEmpty) {
            _processSmsCode(code, OtpCaptureMethod.smsListener);
          } else {
            debugPrint('⚠️ AndroidOtpService: Received null or empty SMS code');
          }
        },
        onError: (error) {
          debugPrint('❌ AndroidOtpService: SmsAutoFill error: $error');
          debugPrint('❌ Error type: ${error.runtimeType}');
          // Try alternative methods on error
          _tryAlternativeListening();
        },
        onDone: () {
          debugPrint('✅ AndroidOtpService: SmsAutoFill stream completed');
        },
      );
      
      debugPrint('AndroidOtpService: SmsAutoFill listener started successfully');
    } catch (e) {
      debugPrint('AndroidOtpService: Error starting SmsAutoFill: $e');
    }
  }

  Future<void> _setupMultipleSmsListeners() async {
    debugPrint('AndroidOtpService: Setting up multiple SMS listening strategies...');
    
    // Strategy 1: No regex pattern (broadest)
    try {
      SmsAutoFill().listenForCode();
      debugPrint('AndroidOtpService: ✅ Strategy 1 - No regex pattern activated');
    } catch (e) {
      debugPrint('AndroidOtpService: ❌ Strategy 1 failed: $e');
    }
    
    // Strategy 2: With generic OTP pattern
    try {
      SmsAutoFill().listenForCode(smsCodeRegexPattern: r'(\d{4,8})');
      debugPrint('AndroidOtpService: ✅ Strategy 2 - Generic digit pattern activated');
    } catch (e) {
      debugPrint('AndroidOtpService: ❌ Strategy 2 failed: $e');
    }
    
    // Strategy 3: With specific app signature pattern
    try {
      SmsAutoFill().listenForCode(smsCodeRegexPattern: r'<#>.*?(\d{6}).*?pRsNh\+4imYr');
      debugPrint('AndroidOtpService: ✅ Strategy 3 - App signature pattern activated');
    } catch (e) {
      debugPrint('AndroidOtpService: ❌ Strategy 3 failed: $e');
    }
    
    // Strategy 4: Enhanced SMS detection  
    debugPrint('AndroidOtpService: All SMS listening strategies activated');
  }

  void _tryAlternativeListening() {
    debugPrint('AndroidOtpService: Trying alternative SMS listening methods...');
    
    // Restart with different pattern
    try {
      SmsAutoFill().listenForCode(smsCodeRegexPattern: r'(\d{6})');
      debugPrint('AndroidOtpService: Alternative listener started with 6-digit pattern');
    } catch (e) {
      debugPrint('AndroidOtpService: Alternative listener failed: $e');
    }
    
    // Start periodic buffer checking as last resort
    _startPeriodicBufferCheck();
  }
  
  void _startPeriodicBufferCheck() {
    if (_currentPhoneNumber == null) return;
    
    debugPrint('AndroidOtpService: Starting periodic SMS buffer check...');
    
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isListening) {
        timer.cancel();
        return;
      }
      
      _checkSmsBuffer();
    });
  }
  
  Future<void> _checkSmsBuffer() async {
    if (_currentPhoneNumber == null) return;
    
    try {
      final cachedOtp = await SmsBufferService.instance.getCachedOtp(_currentPhoneNumber!);
      if (cachedOtp != null && _isListening) {
        debugPrint('AndroidOtpService: 🎯 Found OTP in buffer: ${cachedOtp.otp}');
        
        if (_onOtpReceived != null) {
          _isListening = false;
          _onOtpReceived!(cachedOtp);
        }
      }
    } catch (e) {
      debugPrint('AndroidOtpService: Error checking SMS buffer: $e');
    }
  }


  void _processSmsCode(String code, OtpCaptureMethod method) {
    if (!_isListening) return;
    
    debugPrint('AndroidOtpService: Processing SMS code: "$code"');
    
    // Try to extract OTP from the code
    final extractionResult = OtpExtractionService.extractOtp(code);
    
    if (extractionResult.isValid) {
      debugPrint('AndroidOtpService: Successfully extracted OTP: ${extractionResult.otp}');
      
      final result = OtpResult(
        otp: extractionResult.otp!,
        method: method,
        timestamp: DateTime.now(),
      );
      
      _handleOtpFound(result);
    } else {
      debugPrint('AndroidOtpService: No valid OTP found in code: "$code"');
    }
  }


  void _handleOtpFound(OtpResult result) {
    if (!_isListening) return;
    
    debugPrint('AndroidOtpService: OTP found - cleaning up and notifying');
    _cleanup();
    _onOtpReceived?.call(result);
  }

  void _handleTimeout() {
    if (!_isListening) return;
    
    debugPrint('AndroidOtpService: Handling timeout');
    _cleanup();
    _onTimeout?.call();
  }

  @override
  void stopListening() {
    debugPrint('AndroidOtpService: Stopping SMS listening');
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
    debugPrint('AndroidOtpService: Set current phone number: $phoneNumber');
  }

  Future<void> _checkForCachedOtp() async {
    if (_currentPhoneNumber != null) {
      final cachedResult = await getCachedOtp();
      if (cachedResult != null && _isListening) {
        debugPrint('AndroidOtpService: Found cached OTP after permission grant: ${cachedResult.otp}');
        _handleOtpFound(cachedResult);
      }
    }
  }

  Future<void> _savePermissionState(OtpPermissionStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_permissionStateKey, status.toString());
    } catch (e) {
      debugPrint('AndroidOtpService: Error saving permission state: $e');
    }
  }

  void _cleanup() {
    _isListening = false;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _smsSubscription?.cancel();
    _smsSubscription = null;
    
    try {
      SmsAutoFill().unregisterListener();
    } catch (e) {
      debugPrint('AndroidOtpService: Error during cleanup: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('AndroidOtpService: Disposing');
    _cleanup();
    _onOtpReceived = null;
    _onTimeout = null;
    _onError = null;
  }
}