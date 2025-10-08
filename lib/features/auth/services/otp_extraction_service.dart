import 'package:flutter/foundation.dart';

class OtpExtractionResult {
  final String? otp;
  final String patternUsed;
  final double confidence;

  OtpExtractionResult({
    required this.otp,
    required this.patternUsed,
    required this.confidence,
  });

  bool get isValid => otp != null && otp!.length == 6;
}

class OtpExtractionService {
  static const List<OtpPattern> _patterns = [
    // Highest confidence - New NEPIKA SMS format with <#> prefix
    OtpPattern(
      pattern: r'<#>\s*Your OTP code is\s*(\d{6})',
      confidence: 1.0,
      description: 'NEPIKA SMS Retriever format',
    ),
    
    // Very high confidence - NEPIKA format variations
    OtpPattern(
      pattern: r'Your OTP code is\s*(\d{6})',
      confidence: 0.99,
      description: 'NEPIKA SMS format without prefix',
    ),
    
    OtpPattern(
      pattern: r'Your OTP code is:\s*(\d{6})',
      confidence: 0.98,
      description: 'NEPIKA SMS format with colon',
    ),
    
    // Catch any format with "OTP" and 6 digits
    OtpPattern(
      pattern: r'OTP.*?(\d{6})',
      confidence: 0.95,
      description: 'OTP followed by 6 digits',
    ),
    
    OtpPattern(
      pattern: r'(\d{6}).*?OTP',
      confidence: 0.9,
      description: '6 digits followed by OTP',
    ),
    
    // Generic code patterns
    OtpPattern(
      pattern: r'code.*?(\d{6})',
      confidence: 0.85,
      description: 'Code followed by 6 digits',
    ),
    
    OtpPattern(
      pattern: r'(\d{6}).*?code',
      confidence: 0.8,
      description: '6 digits followed by code',
    ),
    
    // Very broad fallback - any 6 consecutive digits
    OtpPattern(
      pattern: r'\b(\d{6})\b',
      confidence: 0.7,
      description: 'Any 6 digits with word boundaries',
    ),
    
    // Last resort - any 6 digits anywhere
    OtpPattern(
      pattern: r'(\d{6})',
      confidence: 0.6,
      description: 'Any 6 consecutive digits',
    ),
    
    OtpPattern(
      pattern: r'code is:\s*(\d{6})',
      confidence: 0.9,
      description: 'Code is format',
    ),
    
    OtpPattern(
      pattern: r'verification code is:\s*(\d{6})',
      confidence: 0.9,
      description: 'Verification code format',
    ),
    
    // Medium confidence patterns
    OtpPattern(
      pattern: r'(?:OTP|code|pin)[\s:]+(\d{6})',
      confidence: 0.85,
      description: 'OTP/code/pin followed by 6 digits',
    ),
    
    OtpPattern(
      pattern: r'(\d{6})[\s]+is your (?:OTP|code|verification)',
      confidence: 0.8,
      description: '6 digits is your OTP/code',
    ),
    
    OtpPattern(
      pattern: r'Use\s+(\d{6})\s+to',
      confidence: 0.8,
      description: 'Use 6-digit code to',
    ),
    
    OtpPattern(
      pattern: r'(\d{6})\s+is your verification',
      confidence: 0.8,
      description: '6 digits is verification',
    ),
    
    // Carrier-specific patterns
    OtpPattern(
      pattern: r'Dear Customer.*?(\d{6})',
      confidence: 0.75,
      description: 'Dear Customer format',
    ),
    
    OtpPattern(
      pattern: r'Hi.*?(\d{6})',
      confidence: 0.7,
      description: 'Hi greeting format',
    ),
    
    // Generic fallback patterns
    OtpPattern(
      pattern: r'\b(\d{6})\b',
      confidence: 0.6,
      description: '6 digits with word boundaries',
    ),
    
    OtpPattern(
      pattern: r'(\d{6})',
      confidence: 0.5,
      description: 'Any 6 consecutive digits',
    ),
  ];

  /// Extract OTP from SMS content with confidence scoring
  static OtpExtractionResult extractOtp(String smsContent) {
    debugPrint('🔍🔍 OtpExtractionService: STARTING OTP EXTRACTION 🔍🔍');
    debugPrint('📱 Original SMS: "$smsContent"');
    debugPrint('📏 SMS Length: ${smsContent.length}');
    
    // Clean the SMS content
    final cleanedContent = _cleanSmsContent(smsContent);
    debugPrint('🧹 Cleaned SMS: "$cleanedContent"');
    
    OtpExtractionResult? bestResult;
    int patternIndex = 0;
    
    for (final pattern in _patterns) {
      patternIndex++;
      debugPrint('🎯 Testing pattern $patternIndex/${_patterns.length}: "${pattern.description}"');
      debugPrint('🔧 Pattern regex: "${pattern.pattern}"');
      
      final result = _tryPattern(cleanedContent, pattern);
      if (result.isValid) {
        debugPrint('✅ MATCH FOUND! OTP: "${result.otp}" | Confidence: ${result.confidence}');
        
        // Keep the highest confidence result
        if (bestResult == null || result.confidence > bestResult.confidence) {
          bestResult = result;
          debugPrint('🏆 New best result! OTP: "${bestResult.otp}"');
        }
        
        // If we found a very high confidence match, use it immediately
        if (result.confidence >= 0.95) {
          debugPrint('🚀 High confidence match found, stopping search');
          break;
        }
      } else {
        debugPrint('❌ No match for pattern $patternIndex');
      }
    }
    
    if (bestResult != null) {
      debugPrint('🎉🎉 FINAL RESULT 🎉🎉');
      debugPrint('💎 OTP: "${bestResult.otp}"');
      debugPrint('📝 Pattern: "${bestResult.patternUsed}"');
      debugPrint('📊 Confidence: ${bestResult.confidence}');
      return bestResult;
    }
    
    debugPrint('😞 NO OTP FOUND IN SMS - All ${_patterns.length} patterns failed');
    debugPrint('🔍 Consider adding more patterns if this is a valid OTP SMS');
    return OtpExtractionResult(
      otp: null,
      patternUsed: 'none',
      confidence: 0.0,
    );
  }

  /// Try extracting OTP using a specific pattern
  static OtpExtractionResult _tryPattern(String content, OtpPattern pattern) {
    try {
      final RegExp otpRegExp = RegExp(pattern.pattern, caseSensitive: false);
      final Match? match = otpRegExp.firstMatch(content);
      
      if (match != null) {
        String? extractedCode = match.group(1) ?? match.group(0);
        if (extractedCode != null && extractedCode.length == 6 && _isValidOtp(extractedCode)) {
          return OtpExtractionResult(
            otp: extractedCode,
            patternUsed: pattern.description,
            confidence: pattern.confidence,
          );
        }
      }
    } catch (e) {
      debugPrint('OtpExtractionService: Error applying pattern "${pattern.description}": $e');
    }
    
    return OtpExtractionResult(
      otp: null,
      patternUsed: pattern.description,
      confidence: 0.0,
    );
  }

  /// Clean SMS content for better pattern matching
  static String _cleanSmsContent(String content) {
    return content
        .replaceAll('\n', ' ') // Replace newlines with spaces
        .replaceAll('\r', ' ') // Replace carriage returns
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize multiple spaces
        .trim(); // Remove leading/trailing spaces
  }

  /// Validate if the extracted string is a valid OTP
  static bool _isValidOtp(String otp) {
    // Must be exactly 6 digits
    if (otp.length != 6) return false;
    
    // Must contain only digits
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) return false;
    
    // Additional validation rules
    // In debug mode, allow test OTPs for development
    if (kDebugMode) {
      debugPrint('OtpExtractionService: Debug mode - accepting OTP: $otp');
      return true;
    }
    
    // In production, reject obvious invalid patterns
    if (otp == '000000' || otp == '111111' || otp == '123456') {
      debugPrint('OtpExtractionService: Rejected common invalid OTP: $otp');
      return false;
    }
    
    return true;
  }

  /// Get all available patterns for debugging
  static List<OtpPattern> get availablePatterns => _patterns;
}

class OtpPattern {
  final String pattern;
  final double confidence;
  final String description;

  const OtpPattern({
    required this.pattern,
    required this.confidence,
    required this.description,
  });
}