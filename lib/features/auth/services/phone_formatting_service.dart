import 'package:flutter/services.dart';

class PhoneFormattingService {
  static String formatPhoneNumber(String input, String format) {
    final String digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = '';
    int digitIndex = 0;
    
    for (int i = 0; i < format.length && digitIndex < digitsOnly.length; i++) {
      if (format[i] == 'X') {
        formatted += digitsOnly[digitIndex];
        digitIndex++;
      } else {
        formatted += format[i];
      }
    }
    
    return formatted;
  }
  
  static String getDigitsOnly(String formatted) {
    return formatted.replaceAll(RegExp(r'[^0-9]'), '');
  }
  
  static bool isValidPhoneLength(String phone, int expectedLength) {
    final digitsOnly = getDigitsOnly(phone);
    return digitsOnly.length == expectedLength;
  }
}

class PhoneNumberFormatter extends TextInputFormatter {
  final String format;
  
  const PhoneNumberFormatter(this.format);
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digitsOnly.isEmpty) {
      return const TextEditingValue();
    }
    
    final formatted = PhoneFormattingService.formatPhoneNumber(digitsOnly, format);
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}