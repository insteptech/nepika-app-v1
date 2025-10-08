import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';

class AppSignatureService {
  static AppSignatureService? _instance;
  static AppSignatureService get instance => _instance ??= AppSignatureService._();
  
  AppSignatureService._();
  
  String? _cachedSignature;
  
  /// Get the app signature for SMS auto-fill
  Future<String?> getAppSignature() async {
    debugPrint('AppSignatureService: getAppSignature() called');
    debugPrint('AppSignatureService: Platform.isAndroid = ${Platform.isAndroid}');
    debugPrint('AppSignatureService: Platform.isIOS = ${Platform.isIOS}');
    
    if (_cachedSignature != null) {
      debugPrint('AppSignatureService: Using cached signature: $_cachedSignature');
      return _cachedSignature;
    }
    
    try {
      if (Platform.isAndroid) {
        debugPrint('AppSignatureService: Calling SmsAutoFill().getAppSignature...');
        final signature = await SmsAutoFill().getAppSignature;
        debugPrint('AppSignatureService: SmsAutoFill().getAppSignature returned: "$signature"');
        debugPrint('AppSignatureService: Signature type: ${signature.runtimeType}');
        debugPrint('AppSignatureService: Signature length: ${signature?.length ?? 0}');
        debugPrint('AppSignatureService: Signature isEmpty: ${signature?.isEmpty ?? true}');
        
        if (signature != null && signature.isNotEmpty) {
          _cachedSignature = signature;
          debugPrint('AppSignatureService: Successfully cached signature: $_cachedSignature');
        } else {
          debugPrint('AppSignatureService: Warning - Signature is null or empty!');
        }
        return signature;
      } else {
        debugPrint('AppSignatureService: iOS doesn\'t require app signature');
        return null; // iOS doesn't need app signature
      }
    } catch (e, stackTrace) {
      debugPrint('AppSignatureService: Error getting app signature: $e');
      debugPrint('AppSignatureService: Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// Check if app signature is available for current platform
  bool get isSignatureSupported => Platform.isAndroid;
  
  /// Get platform-specific information
  String get platformInfo {
    if (Platform.isAndroid) {
      return _cachedSignature != null 
          ? 'Android - Signature: $_cachedSignature'
          : 'Android - Signature not available';
    } else if (Platform.isIOS) {
      return 'iOS - Uses system SMS autofill';
    } else {
      return 'Unsupported platform';
    }
  }
  
  /// Clear cached signature (useful for testing)
  void clearCache() {
    _cachedSignature = null;
    debugPrint('AppSignatureService: Cleared cached signature');
  }
  
  /// Initialize and cache the signature
  Future<void> initialize() async {
    debugPrint('AppSignatureService: Initializing...');
    await getAppSignature();
    debugPrint('AppSignatureService: Initialized with signature: $_cachedSignature');
  }
}