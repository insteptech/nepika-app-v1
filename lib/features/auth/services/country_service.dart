import 'package:flutter/widgets.dart';

class Country {
  final String code;
  final String flag;
  final String name;
  final String hint;
  final String format;
  final int limit;

  const Country({
    required this.code,
    required this.flag,
    required this.name,
    required this.hint,
    required this.format,
    required this.limit,
  });
}

class CountryService {
  static const List<Country> _countries = [
    Country(
      code: '+1',
      flag: '🇺🇸',
      name: 'United States',
      hint: '(202) 555-0123',
      format: '(XXX) XXX-XXXX',
      limit: 10,
    ),
    Country(
      code: '+91',
      flag: '🇮🇳',
      name: 'India',
      hint: '98765 43210',
      format: 'XXXXX XXXXX',
      limit: 10,
    ),
    Country(
      code: '+44',
      flag: '🇬🇧',
      name: 'United Kingdom',
      hint: '7123 456789',
      format: 'XXXX XXXXXX',
      limit: 10,
    ),
    Country(
      code: '+34',
      flag: '🇪🇸',
      name: 'Spain',
      hint: '612 345 678',
      format: 'XXX XXX XXX',
      limit: 9,
    ),
    Country(
      code: '+86',
      flag: '🇨🇳',
      name: 'China',
      hint: '138 0013 8000',
      format: 'XXX XXXX XXXX',
      limit: 11,
    ),
    Country(
      code: '+33',
      flag: '🇫🇷',
      name: 'France',
      hint: '6 12 34 56 78',
      format: 'X XX XX XX XX',
      limit: 9,
    ),
    Country(
      code: '+49',
      flag: '🇩🇪',
      name: 'Germany',
      hint: '151 234 56789',
      format: 'XXX XXX XXXXX',
      limit: 11,
    ),
    Country(
      code: '+81',
      flag: '🇯🇵',
      name: 'Japan',
      hint: '03-1234-5678',
      format: 'XX-XXXX-XXXX',
      limit: 10,
    ),
    Country(
      code: '+61',
      flag: '🇦🇺',
      name: 'Australia',
      hint: '4 1234 5678',
      format: 'X XXXX XXXX',
      limit: 9,
    ),
    Country(
      code: '+82',
      flag: '🇰🇷',
      name: 'South Korea',
      hint: '010-2345-6789',
      format: 'XXX-XXXX-XXXX',
      limit: 10,
    ),
    Country(
      code: '+55',
      flag: '🇧🇷',
      name: 'Brazil',
      hint: '(11) 91234-5678',
      format: '(XX) XXXXX-XXXX',
      limit: 11,
    ),
  ];

  static List<Country> get countries => _countries;

  static Country getDefaultCountry() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final countryCode = locale.countryCode;

    switch (countryCode) {
      case 'US':
        return _countries.firstWhere((c) => c.code == '+1');
      case 'IN':
        return _countries.firstWhere((c) => c.code == '+91');
      case 'GB':
        return _countries.firstWhere((c) => c.code == '+44');
      case 'CN':
        return _countries.firstWhere((c) => c.code == '+86');
      case 'FR':
        return _countries.firstWhere((c) => c.code == '+33');
      case 'DE':
        return _countries.firstWhere((c) => c.code == '+49');
      case 'JP':
        return _countries.firstWhere((c) => c.code == '+81');
      case 'AU':
        return _countries.firstWhere((c) => c.code == '+61');
      case 'KR':
        return _countries.firstWhere((c) => c.code == '+82');
      case 'BR':
        return _countries.firstWhere((c) => c.code == '+55');
      default:
        return _countries.first; // Default to US
    }
  }

  static Country? findByCode(String code) {
    try {
      return _countries.firstWhere((c) => c.code == code);
    } catch (e) {
      return null;
    }
  }
}