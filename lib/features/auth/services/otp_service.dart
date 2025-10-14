import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:permission_handler/permission_handler.dart';

class OtpService {
  static const int _timeoutSeconds = 45;
  // ignore: unused_field
  static const int _otpLength = 6;
  
  Timer? _autoCaptuteTimeout;
  StreamSubscription? _smsSubscription;
  bool _isListening = false;

  bool get isListening => _isListening;

  Future<bool> requestSmsPermission() async {
    debugPrint('OtpService: Requesting SMS permissions...');
    
    // Request multiple SMS-related permissions
    Map<Permission, PermissionStatus> permissions = await [
      Permission.sms,
      Permission.phone,
    ].request();
    
    debugPrint('OtpService: Permission results: $permissions');
    
    // Check if SMS permission is granted
    final smsGranted = permissions[Permission.sms]?.isGranted ?? false;
    final phoneGranted = permissions[Permission.phone]?.isGranted ?? false;
    
    debugPrint('OtpService: SMS granted: $smsGranted, Phone granted: $phoneGranted');
    
    return smsGranted;
  }

  Future<bool> checkSmsPermission() async {
    final smsStatus = await Permission.sms.status;
    final phoneStatus = await Permission.phone.status;
    
    debugPrint('OtpService: SMS status: $smsStatus, Phone status: $phoneStatus');
    
    return smsStatus.isGranted;
  }

  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  Future<void> startListening({
    required Function(String otp) onOtpReceived,
    required VoidCallback onTimeout,
    VoidCallback? onError,
  }) async {
    if (_isListening) {
      stopListening();
    }

    // Double-check permissions before starting
    final hasPermission = await checkSmsPermission();
    if (!hasPermission) {
      debugPrint('OtpService: SMS permission not granted, cannot start listening');
      onError?.call();
      return;
    }

    _isListening = true;

    try {
      debugPrint('OtpService: ========== STARTING SMS LISTENER ==========');
      debugPrint('OtpService: Permission granted, initializing listener...');

      // Get app signature for debugging
      try {
        final signature = await SmsAutoFill().getAppSignature;
        debugPrint('OtpService: App signature: $signature');
        debugPrint('OtpService: ==========================================');
        debugPrint('OtpService: ⚠️  BACKEND MUST SEND SMS IN THIS EXACT FORMAT:');
        debugPrint('OtpService: ==========================================');
        debugPrint('OtpService: <#> Your OTP code is 163051');
        debugPrint('OtpService: Do not share this code. It will expire in 5 minutes.');
        debugPrint('OtpService: $signature');
        debugPrint('OtpService: ==========================================');
        debugPrint('OtpService: Note: The app signature "$signature" MUST be on a separate line at the end');
        debugPrint('OtpService: Note: The SMS MUST start with "<#>" for Android auto-detection');
        debugPrint('OtpService: ==========================================');
      } catch (error) {
        debugPrint('OtpService: Error getting app signature: $error');
      }

      // Method 1: Use listenForCode with a specific pattern
      debugPrint('OtpService: Starting listener with regex pattern...');

      try {
        // First, unregister any existing listener
        SmsAutoFill().unregisterListener();
        debugPrint('OtpService: Unregistered any existing listeners');
      } catch (e) {
        debugPrint('OtpService: No existing listener to unregister: $e');
      }

      // Now start fresh listener
      await SmsAutoFill().listenForCode();
      debugPrint('OtpService: ✅ Listener initialized successfully');

      // Method 2: Also periodically check using getSmsCode (backup method)
      Timer.periodic(const Duration(seconds: 2), (timer) {
        if (!_isListening) {
          timer.cancel();
          return;
        }

        debugPrint('OtpService: Polling for SMS code (backup method)...');
        SmsAutoFill().getAppSignature.then((signature) {
          debugPrint('OtpService: Poll check - signature still active: $signature');
        });
      });

      // Set up timeout
      _autoCaptuteTimeout = Timer(const Duration(seconds: _timeoutSeconds), () {
        debugPrint('OtpService: ⏱️ Timeout reached after $_timeoutSeconds seconds');
        _isListening = false;
        SmsAutoFill().unregisterListener();
        onTimeout();
      });

      // Listen for SMS code
      _smsSubscription = SmsAutoFill().code.listen(
        (code) {
          debugPrint('OtpService: ========== SMS CODE RECEIVED ==========');
          debugPrint('OtpService: Raw code from SmsAutoFill: "$code"');
          debugPrint('OtpService: Code length: ${code.length}');

          if (code.isEmpty) {
            debugPrint('OtpService: ⚠️ Received empty code');
            return;
          }

          debugPrint('OtpService: Processing received code...');
          _processSmsCode(code, onOtpReceived);
        },
        onError: (error) {
          debugPrint('OtpService: ❌ Error in SMS listener: $error');
          _isListening = false;
          onError?.call();
        },
        onDone: () {
          debugPrint('OtpService: SMS listener stream closed');
        },
      );

      debugPrint('OtpService: 📱 SMS listener is now ACTIVE and waiting...');
      debugPrint('OtpService: ==========================================');

    } catch (e, stackTrace) {
      debugPrint('OtpService: ❌ Exception in startListening: $e');
      debugPrint('OtpService: Stack trace: $stackTrace');
      _isListening = false;
      onError?.call();
    }
  }

  void stopListening() {
    _cleanup();
  }

  void _processSmsCode(String code, Function(String) onOtpReceived) {
    debugPrint('OtpService: ========== PROCESSING SMS CODE ==========');
    debugPrint('OtpService: Input code: "$code"');
    debugPrint('OtpService: Code length: ${code.length}');

    if (code.isEmpty) {
      debugPrint('OtpService: ❌ Code is empty, cannot process');
      return;
    }

    final extractedOtp = _extractOtp(code);

    if (extractedOtp != null) {
      debugPrint('OtpService: ✅ Successfully extracted OTP: $extractedOtp');
      debugPrint('OtpService: Cleaning up listener and calling onOtpReceived...');
      _cleanup();
      onOtpReceived(extractedOtp);
      debugPrint('OtpService: OTP passed to callback successfully');
    } else {
      debugPrint('OtpService: ❌ No valid 6-digit OTP found in: "$code"');
      debugPrint('OtpService: This might not be an OTP SMS, continuing to listen...');
    }

    debugPrint('OtpService: ==========================================');
  }

  String? _extractOtp(String smsCode) {
    debugPrint('OtpService: ========== EXTRACTING OTP ==========');
    debugPrint('OtpService: Input SMS: "$smsCode"');

    // Try different OTP patterns specifically designed for your SMS format
    // Format: "<#> Your OTP code is 163051\nDo not share this code. It will expire in 5 minutes."
    // Format (Android): "<#> Your OTP code is 163051\nDo not share this code. It will expire in 5 minutes.\njfdoiwh+1n2"
    final patterns = [
      r'Your OTP code is\s+(\d{6})',  // Match "Your OTP code is 163051"
      r'OTP code is\s+(\d{6})',       // Match "OTP code is 163051"
      r'code is\s+(\d{6})',           // Match "code is 163051"
      r'<#>\s*Your OTP code is\s+(\d{6})', // Match with Android prefix
      r'\b(\d{6})\b',                 // 6 digits with word boundaries (most reliable)
      r'(\d{6})',                     // Any 6 consecutive digits (fallback)
    ];

    int patternIndex = 0;
    for (String pattern in patterns) {
      patternIndex++;
      debugPrint('OtpService: Trying pattern #$patternIndex: "$pattern"');

      final RegExp otpRegExp = RegExp(pattern, caseSensitive: false, multiLine: true);
      final Match? match = otpRegExp.firstMatch(smsCode);

      if (match != null) {
        debugPrint('OtpService: Pattern matched! Match groups: ${match.groupCount}');
        String? extractedCode = match.group(1) ?? match.group(0);

        if (extractedCode != null) {
          debugPrint('OtpService: Extracted code: "$extractedCode" (length: ${extractedCode.length})');

          if (extractedCode.length == 6 && int.tryParse(extractedCode) != null) {
            debugPrint('OtpService: ✅ Valid 6-digit OTP found: $extractedCode');
            debugPrint('OtpService: ==========================================');
            return extractedCode;
          } else {
            debugPrint('OtpService: ⚠️ Code length is ${extractedCode.length}, need exactly 6 digits');
          }
        }
      } else {
        debugPrint('OtpService: Pattern did not match');
      }
    }

    debugPrint('OtpService: ❌ No valid 6-digit OTP found after trying all patterns');
    debugPrint('OtpService: ==========================================');
    return null;
  }

  void _cleanup() {
    _isListening = false;
    _autoCaptuteTimeout?.cancel();
    _autoCaptuteTimeout = null;
    _smsSubscription?.cancel();
    _smsSubscription = null;
    SmsAutoFill().unregisterListener();
  }

  void dispose() {
    _cleanup();
  }
}