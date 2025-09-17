/// Enhanced country data model for production use
class CountryData {
  final String code;
  final String dialCode;
  final String flag;
  final String name;
  final String isoCode;
  final int minLength;
  final int maxLength;
  final String example;
  
  const CountryData({
    required this.code,
    required this.dialCode,
    required this.flag,
    required this.name,
    required this.isoCode,
    required this.minLength,
    required this.maxLength,
    required this.example,
  });
  
  /// Comprehensive list of countries with accurate phone data
  static const List<CountryData> allCountries = [
    CountryData(
      code: 'US',
      dialCode: '+1',
      flag: '🇺🇸',
      name: 'United States',
      isoCode: 'US',
      minLength: 10,
      maxLength: 10,
      example: '(202) 555-0123',
    ),
    CountryData(
      code: 'IN',
      dialCode: '+91',
      flag: '🇮🇳',
      name: 'India',
      isoCode: 'IN',
      minLength: 10,
      maxLength: 10,
      example: '98765 43210',
    ),
    CountryData(
      code: 'GB',
      dialCode: '+44',
      flag: '🇬🇧',
      name: 'United Kingdom',
      isoCode: 'GB',
      minLength: 10,
      maxLength: 11,
      example: '7123 456789',
    ),
    CountryData(
      code: 'CN',
      dialCode: '+86',
      flag: '🇨🇳',
      name: 'China',
      isoCode: 'CN',
      minLength: 11,
      maxLength: 11,
      example: '138 0013 8000',
    ),
    CountryData(
      code: 'FR',
      dialCode: '+33',
      flag: '🇫🇷',
      name: 'France',
      isoCode: 'FR',
      minLength: 9,
      maxLength: 9,
      example: '6 12 34 56 78',
    ),
    CountryData(
      code: 'DE',
      dialCode: '+49',
      flag: '🇩🇪',
      name: 'Germany',
      isoCode: 'DE',
      minLength: 10,
      maxLength: 12,
      example: '151 234 56789',
    ),
    CountryData(
      code: 'JP',
      dialCode: '+81',
      flag: '🇯🇵',
      name: 'Japan',
      isoCode: 'JP',
      minLength: 10,
      maxLength: 11,
      example: '03-1234-5678',
    ),
    CountryData(
      code: 'AU',
      dialCode: '+61',
      flag: '🇦🇺',
      name: 'Australia',
      isoCode: 'AU',
      minLength: 9,
      maxLength: 9,
      example: '4 1234 5678',
    ),
    CountryData(
      code: 'KR',
      dialCode: '+82',
      flag: '🇰🇷',
      name: 'South Korea',
      isoCode: 'KR',
      minLength: 10,
      maxLength: 11,
      example: '010-2345-6789',
    ),
    CountryData(
      code: 'BR',
      dialCode: '+55',
      flag: '🇧🇷',
      name: 'Brazil',
      isoCode: 'BR',
      minLength: 10,
      maxLength: 11,
      example: '(11) 91234-5678',
    ),
    CountryData(
      code: 'CA',
      dialCode: '+1',
      flag: '🇨🇦',
      name: 'Canada',
      isoCode: 'CA',
      minLength: 10,
      maxLength: 10,
      example: '(416) 555-0123',
    ),
    CountryData(
      code: 'MX',
      dialCode: '+52',
      flag: '🇲🇽',
      name: 'Mexico',
      isoCode: 'MX',
      minLength: 10,
      maxLength: 10,
      example: '55 1234 5678',
    ),
    CountryData(
      code: 'IT',
      dialCode: '+39',
      flag: '🇮🇹',
      name: 'Italy',
      isoCode: 'IT',
      minLength: 9,
      maxLength: 11,
      example: '320 123 4567',
    ),
    CountryData(
      code: 'ES',
      dialCode: '+34',
      flag: '🇪🇸',
      name: 'Spain',
      isoCode: 'ES',
      minLength: 9,
      maxLength: 9,
      example: '612 34 56 78',
    ),
    CountryData(
      code: 'RU',
      dialCode: '+7',
      flag: '🇷🇺',
      name: 'Russia',
      isoCode: 'RU',
      minLength: 10,
      maxLength: 10,
      example: '912 345 67 89',
    ),
  ];
  
  /// Find country by ISO code
  static CountryData? findByCode(String code) {
    try {
      return allCountries.firstWhere(
        (country) => country.code.toUpperCase() == code.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Find country by dial code
  static CountryData? findByDialCode(String dialCode) {
    try {
      return allCountries.firstWhere(
        (country) => country.dialCode == dialCode,
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Get default country (US)
  static CountryData get defaultCountry {
    return allCountries.first; // US is first in the list
  }
}