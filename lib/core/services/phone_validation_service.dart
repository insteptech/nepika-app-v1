// import 'package:flutter/foundation.dart';
// import '../models/country_data.dart';

// /// Service for secure phone number validation and formatting
// class PhoneValidationService {
  
//   /// Validates and formats a phone number for a specific country
//   static ValidationResult validateAndFormat({
//     required String phoneNumber,
//     required String countryCode,
//   }) {
//     try {
//       // Find country data
//       final country = CountryData.findByCode(countryCode);
//       if (country == null) {
//         return ValidationResult(
//           isValid: false,
//           errorMessage: 'Unsupported country code',
//         );
//       }
      
//       // Sanitize and extract digits only
//       final digitsOnly = sanitizeToDigitsOnly(phoneNumber);
      
//       // Validate length
//       if (digitsOnly.length < country.minLength || digitsOnly.length > country.maxLength) {
//         return ValidationResult(
//           isValid: false,
//           errorMessage: 'Phone number must be ${country.minLength}-${country.maxLength} digits',
//         );
//       }
      
//       // Additional country-specific validation
//       if (!_isValidForCountry(digitsOnly, country)) {
//         return ValidationResult(
//           isValid: false,
//           errorMessage: 'Invalid phone number format for ${country.name}',
//         );
//       }
      
//       // Generate E.164 format
//       final e164Format = '${country.dialCode}$digitsOnly';
      
//       return ValidationResult(
//         isValid: true,
//         e164Format: e164Format,
//         nationalFormat: _formatNational(digitsOnly, country),
//         countryCode: country.code,
//       );
      
//     } catch (e) {
//       debugPrint('Phone validation error: $e');
//       return ValidationResult(
//         isValid: false,
//         errorMessage: 'Unable to validate phone number',
//       );
//     }
//   }
  
//   /// Formats a phone number for display purposes
//   static String formatForDisplay(String phoneNumber, String countryCode) {
//     try {
//       final result = validateAndFormat(
//         phoneNumber: phoneNumber,
//         countryCode: countryCode,
//       );
      
//       return result.nationalFormat ?? phoneNumber;
//     } catch (e) {
//       return phoneNumber;
//     }
//   }
  
//   /// Sanitizes phone input to prevent injection attacks
//   static String sanitizeInput(String input) {
//     // Remove all characters except digits, spaces, parentheses, hyphens, and plus
//     return input.replaceAll(RegExp(r'[^0-9\s\(\)\-\+]'), '');
//   }
  
//   /// Extracts digits only from phone input
//   static String sanitizeToDigitsOnly(String input) {
//     return input.replaceAll(RegExp(r'[^0-9]'), '');
//   }
  
//   /// Country-specific validation rules
//   static bool _isValidForCountry(String digitsOnly, CountryData country) {
//     switch (country.code) {
//       case 'US':
//       case 'CA':
//         // North America: First digit cannot be 0 or 1
//         return digitsOnly.isNotEmpty && 
//                !['0', '1'].contains(digitsOnly[0]) &&
//                digitsOnly.length == 10;
      
//       case 'IN':
//         // India: Mobile numbers start with 6, 7, 8, 9
//         return digitsOnly.isNotEmpty && 
//                ['6', '7', '8', '9'].contains(digitsOnly[0]) &&
//                digitsOnly.length == 10;
      
//       case 'GB':
//         // UK: Mobile numbers start with 7
//         return digitsOnly.isNotEmpty && 
//                digitsOnly[0] == '7' &&
//                (digitsOnly.length == 10 || digitsOnly.length == 11);
      
//       case 'CN':
//         // China: Mobile numbers start with 1
//         return digitsOnly.isNotEmpty && 
//                digitsOnly[0] == '1' &&
//                digitsOnly.length == 11;
      
//       default:
//         // For other countries, just check length
//         return digitsOnly.length >= country.minLength && 
//                digitsOnly.length <= country.maxLength;
//     }
//   }
  
//   /// Format phone number in national format
//   static String _formatNational(String digitsOnly, CountryData country) {
//     switch (country.code) {
//       case 'US':
//       case 'CA':
//         // Format: (XXX) XXX-XXXX
//         if (digitsOnly.length == 10) {
//           return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
//         }
//         break;
      
//       case 'IN':
//         // Format: XXXXX XXXXX
//         if (digitsOnly.length == 10) {
//           return '${digitsOnly.substring(0, 5)} ${digitsOnly.substring(5)}';
//         }
//         break;
      
//       case 'GB':
//         // Format: XXXX XXXXXX
//         if (digitsOnly.length == 10) {
//           return '${digitsOnly.substring(0, 4)} ${digitsOnly.substring(4)}';
//         }
//         break;
      
//       case 'CN':
//         // Format: XXX XXXX XXXX
//         if (digitsOnly.length == 11) {
//           return '${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3, 7)} ${digitsOnly.substring(7)}';
//         }
//         break;
//     }
    
//     // Default formatting
//     return digitsOnly;
//   }
// }

// /// Result class for phone validation
// class ValidationResult {
//   final bool isValid;
//   final String? e164Format;
//   final String? nationalFormat;
//   final String? countryCode;
//   final String? errorMessage;
  
//   ValidationResult({
//     required this.isValid,
//     this.e164Format,
//     this.nationalFormat,
//     this.countryCode,
//     this.errorMessage,
//   });
// }