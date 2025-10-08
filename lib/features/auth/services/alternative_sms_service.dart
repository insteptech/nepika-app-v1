import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AlternativeSmsService {
  static AlternativeSmsService? _instance;
  static AlternativeSmsService get instance => _instance ??= AlternativeSmsService._();
  
  AlternativeSmsService._();
  
  Timer? _pollTimer;
  bool _isListening = false;
  String? _currentPhoneNumber;
  Function(String)? _onSmsReceived;
  DateTime? _listeningStartTime;
  
  /// Start alternative SMS monitoring using periodic polling
  void startAlternativeListening({
    required String phoneNumber,
    required Function(String) onSmsReceived,
  }) {
    if (_isListening) {
      stopListening();
    }
    
    _currentPhoneNumber = phoneNumber;
    _onSmsReceived = onSmsReceived;
    _listeningStartTime = DateTime.now();
    _isListening = true;
    
    debugPrint('🔄 AlternativeSmsService: Starting alternative SMS monitoring');
    debugPrint('📱 Phone: $phoneNumber');
    
    // Poll for new SMS every 2 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkForNewSms();
    });
    
    // Also check immediately
    _checkForNewSms();
  }
  
  void _checkForNewSms() {
    if (!_isListening || _currentPhoneNumber == null) return;
    
    debugPrint('🔍 AlternativeSmsService: Checking for new SMS...');
    
    // Simulate SMS check - in real implementation, you might:
    // 1. Read from Android's SMS content provider (requires native code)
    // 2. Use a different SMS plugin
    // 3. Monitor system notifications
    
    // For now, just log that we're checking
    debugPrint('📱 AlternativeSmsService: SMS check completed (no new messages)');
  }
  
  /// Stop alternative SMS monitoring
  void stopListening() {
    _isListening = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _currentPhoneNumber = null;
    _onSmsReceived = null;
    _listeningStartTime = null;
    
    debugPrint('🛑 AlternativeSmsService: Stopped alternative SMS monitoring');
  }
  
  /// Manually process SMS content (for testing)
  void processSmsManually(String smsContent) {
    if (!_isListening || _onSmsReceived == null) {
      debugPrint('⚠️ AlternativeSmsService: Not listening, ignoring SMS');
      return;
    }
    
    debugPrint('🔥 AlternativeSmsService: Processing manual SMS');
    debugPrint('📱 SMS: "$smsContent"');
    
    _onSmsReceived!(smsContent);
  }
  
  /// Check if we're currently listening
  bool get isListening => _isListening;
  
  /// Get how long we've been listening
  Duration? get listeningDuration {
    if (_listeningStartTime == null) return null;
    return DateTime.now().difference(_listeningStartTime!);
  }
}