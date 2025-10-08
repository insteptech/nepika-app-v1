import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'platform_otp_service_interface.dart';

class SmsBufferEntry {
  final String phoneNumber;
  final String otp;
  final DateTime timestamp;
  final String smsContent;

  SmsBufferEntry({
    required this.phoneNumber,
    required this.otp,
    required this.timestamp,
    required this.smsContent,
  });

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'otp': otp,
        'timestamp': timestamp.toIso8601String(),
        'smsContent': smsContent,
      };

  factory SmsBufferEntry.fromJson(Map<String, dynamic> json) => SmsBufferEntry(
        phoneNumber: json['phoneNumber'],
        otp: json['otp'],
        timestamp: DateTime.parse(json['timestamp']),
        smsContent: json['smsContent'],
      );
}

class SmsBufferService {
  static const String _bufferKey = 'nepika_sms_buffer';
  static const Duration _bufferRetention = Duration(minutes: 10);
  static const int _maxBufferSize = 5;

  static SmsBufferService? _instance;
  static SmsBufferService get instance => _instance ??= SmsBufferService._();
  
  SmsBufferService._();

  /// Buffer SMS for late permission scenarios
  Future<void> bufferSms(String phoneNumber, String otp, String smsContent) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bufferedSms = await _getBufferedSms();
      
      // Add new entry
      bufferedSms.add(SmsBufferEntry(
        phoneNumber: phoneNumber,
        otp: otp,
        timestamp: DateTime.now(),
        smsContent: smsContent,
      ));
      
      // Clean old entries and limit size
      final cleanedSms = _cleanBuffer(bufferedSms);
      
      // Save to storage
      final jsonList = cleanedSms.map((e) => e.toJson()).toList();
      await prefs.setString(_bufferKey, jsonEncode(jsonList));
      
      debugPrint('SmsBufferService: Buffered SMS for $phoneNumber with OTP: $otp');
    } catch (e) {
      debugPrint('SmsBufferService: Error buffering SMS: $e');
    }
  }

  /// Retrieve cached OTP for specific phone number
  Future<OtpResult?> getCachedOtp(String phoneNumber) async {
    try {
      final bufferedSms = await _getBufferedSms();
      
      // Find matching SMS for phone number (clean phone number for comparison)
      final cleanPhoneNumber = _cleanPhoneNumber(phoneNumber);
      
      for (final entry in bufferedSms.reversed) { // Check most recent first
        final cleanEntryPhone = _cleanPhoneNumber(entry.phoneNumber);
        
        if (cleanEntryPhone == cleanPhoneNumber) {
          debugPrint('SmsBufferService: Found cached OTP for $phoneNumber: ${entry.otp}');
          
          // Remove from buffer after retrieval
          await _removeBufferEntry(entry);
          
          return OtpResult(
            otp: entry.otp,
            method: OtpCaptureMethod.cached,
            timestamp: entry.timestamp,
          );
        }
      }
      
      debugPrint('SmsBufferService: No cached OTP found for $phoneNumber');
      return null;
    } catch (e) {
      debugPrint('SmsBufferService: Error retrieving cached OTP: $e');
      return null;
    }
  }

  /// Check if there's any cached OTP for any phone number
  Future<bool> hasCachedOtp() async {
    final bufferedSms = await _getBufferedSms();
    return bufferedSms.isNotEmpty;
  }

  /// Clear all buffered SMS
  Future<void> clearBuffer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bufferKey);
      debugPrint('SmsBufferService: Buffer cleared');
    } catch (e) {
      debugPrint('SmsBufferService: Error clearing buffer: $e');
    }
  }

  /// Get all buffered SMS entries
  Future<List<SmsBufferEntry>> _getBufferedSms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_bufferKey);
      
      if (jsonString == null) return [];
      
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => SmsBufferEntry.fromJson(json)).toList();
    } catch (e) {
      debugPrint('SmsBufferService: Error reading buffered SMS: $e');
      return [];
    }
  }

  /// Remove specific buffer entry
  Future<void> _removeBufferEntry(SmsBufferEntry entryToRemove) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bufferedSms = await _getBufferedSms();
      
      bufferedSms.removeWhere((entry) => 
        entry.phoneNumber == entryToRemove.phoneNumber &&
        entry.timestamp == entryToRemove.timestamp
      );
      
      final jsonList = bufferedSms.map((e) => e.toJson()).toList();
      await prefs.setString(_bufferKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('SmsBufferService: Error removing buffer entry: $e');
    }
  }

  /// Clean old entries and limit buffer size
  List<SmsBufferEntry> _cleanBuffer(List<SmsBufferEntry> entries) {
    final now = DateTime.now();
    
    // Remove old entries
    entries.removeWhere((entry) => 
      now.difference(entry.timestamp) > _bufferRetention
    );
    
    // Sort by timestamp (newest first) and limit size
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (entries.length > _maxBufferSize) {
      entries = entries.take(_maxBufferSize).toList();
    }
    
    return entries;
  }

  /// Clean phone number for comparison (remove spaces, dashes, country codes)
  String _cleanPhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    
    // Remove common country codes if present
    if (cleaned.startsWith('91') && cleaned.length > 10) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith('1') && cleaned.length == 11) {
      cleaned = cleaned.substring(1);
    }
    
    // Take last 10 digits for comparison
    if (cleaned.length > 10) {
      cleaned = cleaned.substring(cleaned.length - 10);
    }
    
    return cleaned;
  }
}