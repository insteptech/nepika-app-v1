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
      debugPrint('OtpService: Starting SMS listener with permissions verified');
      
      // Get app signature for debugging and SMS format verification
      try {
        final signature = await SmsAutoFill().getAppSignature;
        debugPrint('OtpService: App signature: $signature');
        debugPrint('OtpService: Expected SMS format: "Your OTP code is: 123456. This code will expire in 5 minutes."');
        debugPrint('OtpService: Note: App signature ($signature) not required for your SMS format');
      } catch (error) {
        debugPrint('OtpService: Error getting app signature: $error');
      }
      
      // Initialize SmsAutoFill listener with multiple approaches
      debugPrint('OtpService: Initializing SmsAutoFill listener...');
      
      // Try without regex first (most compatible)
      SmsAutoFill().listenForCode;
      debugPrint('OtpService: SmsAutoFill listener initialized without regex (broad detection)');
      
      // Also try with a simpler regex pattern
      try {
        SmsAutoFill().listenForCode(smsCodeRegexPattern: r'\d{6}');
        debugPrint('OtpService: SmsAutoFill listener also set with simple 6-digit regex');
      } catch (e) {
        debugPrint('OtpService: Could not set regex pattern: $e');
      }
      
      // Set up timeout
      _autoCaptuteTimeout = Timer(const Duration(seconds: _timeoutSeconds), () {
        debugPrint('OtpService: Timeout reached after $_timeoutSeconds seconds');
        _isListening = false;
        SmsAutoFill().unregisterListener();
        onTimeout();
      });

      // Listen for SMS using both methods for better compatibility
      _smsSubscription = SmsAutoFill().code.listen(
        (code) {
          debugPrint('OtpService: ✅ SMS DETECTED! Received code from SmsAutoFill: "$code"');
          if (code.isEmpty) {
            debugPrint('OtpService: ⚠️ Received empty code from SmsAutoFill');
          } else {
            _processSmsCode(code, onOtpReceived);
          }
        },
        onError: (error) {
          debugPrint('OtpService: ❌ Error listening for SMS code: $error');
          _isListening = false;
          onError?.call();
        },
      );
      
      debugPrint('OtpService: 📱 SMS listener active - waiting for incoming SMS...');
      debugPrint('OtpService: 📋 Expected format: "Your OTP code is: 123456. This code will expire in 5 minutes."');
      debugPrint('OtpService: ⚠️ TROUBLESHOOTING TIPS:');
      debugPrint('OtpService: 1. Try sending SMS from a verified/branded sender ID');
      debugPrint('OtpService: 2. Ensure SMS contains only alphanumeric characters');
      debugPrint('OtpService: 3. Some SMS gateways may not work with auto-detection');
      debugPrint('OtpService: 4. Test by manually sending SMS from another phone to this number');
      
      // Note: getIncomingSms is not available in current sms_autofill version
      // The main listener above should handle SMS detection
      
      debugPrint('OtpService: SMS listener setup complete, waiting for SMS...');
      
    } catch (e) {
      debugPrint('OtpService: Exception in startListening: $e');
      _isListening = false;
      onError?.call();
    }
  }

  void stopListening() {
    _cleanup();
  }

  void _processSmsCode(String code, Function(String) onOtpReceived) {
    if (code.isNotEmpty && code.length >= 4) {
      final extractedOtp = _extractOtp(code);
      
      if (extractedOtp != null) {
        debugPrint('OtpService: Successfully extracted OTP: $extractedOtp');
        _cleanup();
        onOtpReceived(extractedOtp);
      } else {
        debugPrint('OtpService: No valid 6-digit OTP found in SMS: "$code"');
      }
    } else {
      debugPrint('OtpService: Received code too short: "$code" (length: ${code.length})');
    }
  }

  String? _extractOtp(String smsCode) {
    debugPrint('OtpService: Extracting OTP from SMS: "$smsCode"');
    
    // Try different OTP patterns specifically designed for your SMS format
    final patterns = [
      r'Your OTP code is:\s*(\d{6})', // Exact match for your format: "Your OTP code is: 123456"
      r'OTP code is:\s*(\d{6})',      // Partial match: "OTP code is: 123456"
      r'code is:\s*(\d{6})',          // Even shorter match: "code is: 123456"
      r'(?:OTP|code)[\s:]+(\d{6})',   // OTP or code followed by space/colon and 6 digits
      r'\b(\d{6})\b',                 // 6 digits with word boundaries (most reliable)
      r'(\d{6})',                     // Any 6 consecutive digits (fallback)
    ];
    
    for (String pattern in patterns) {
      final RegExp otpRegExp = RegExp(pattern, caseSensitive: false);
      final Match? match = otpRegExp.firstMatch(smsCode);
      if (match != null) {
        String? extractedCode = match.group(1) ?? match.group(0);
        if (extractedCode != null && extractedCode.length == 6) {
          debugPrint('OtpService: Found OTP using pattern "$pattern": $extractedCode');
          return extractedCode;
        }
      }
    }
    
    debugPrint('OtpService: No 6-digit OTP found in SMS');
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