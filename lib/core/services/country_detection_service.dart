// import 'dart:async';
// import 'package:flutter/foundation.dart';

// /// Service for secure country detection with fallback mechanisms
// class CountryDetectionService {
//   static const String _defaultCountryCode = 'US';
  
//   /// Detects country using priority order: Locale -> Default
//   /// Note: SIM detection requires additional platform-specific implementation
//   static Future<String> detectCountryCode() async {
//     try {
//       // Priority 1: Try system locale
//       final localeCountry = _getLocaleCountryCode();
//       if (localeCountry != null && localeCountry.isNotEmpty) {
//         debugPrint('🌍 Country detected from locale: $localeCountry');
//         return localeCountry;
//       }
      
//       // Priority 2: Default fallback
//       debugPrint('🇺🇸 Using default country: $_defaultCountryCode');
//       return _defaultCountryCode;
      
//     } catch (e) {
//       debugPrint('⚠️ Country detection error: $e');
//       return _defaultCountryCode;
//     }
//   }
  
//   /// Gets country code from system locale
//   static String? _getLocaleCountryCode() {
//     try {
//       final locale = PlatformDispatcher.instance.locale;
//       final countryCode = locale.countryCode;
//       if (countryCode != null && countryCode.length == 2) {
//         return countryCode.toUpperCase();
//       }
//       return null;
//     } catch (e) {
//       debugPrint('Locale detection error: $e');
//       return null;
//     }
//   }
  
//   /// Validates if a country code is supported
//   static bool isSupportedCountry(String countryCode) {
//     final supportedCountries = [
//       'US', 'IN', 'GB', 'CN', 'FR', 'DE', 'JP', 'AU', 'KR', 'BR', 
//       'CA', 'MX', 'IT', 'ES', 'RU'
//     ];
//     return supportedCountries.contains(countryCode.toUpperCase());
//   }
// }