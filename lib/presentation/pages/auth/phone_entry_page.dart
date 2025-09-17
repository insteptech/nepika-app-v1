import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/presentation/bloc/auth/auth_bloc.dart';
import 'package:nepika/presentation/bloc/auth/auth_event.dart';
import 'package:nepika/presentation/bloc/auth/auth_state.dart';
import '../../../core/config/constants/routes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class PhoneEntryPage extends StatefulWidget {
  const PhoneEntryPage({super.key});

  @override
  State<PhoneEntryPage> createState() => _PhoneEntryPageState();
}

class _PhoneEntryPageState extends State<PhoneEntryPage> {
  final _phoneController = TextEditingController();
  final _countryCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isResponseLoading = false;
  String _selectedCountryCode = '+1';
  String _selectedCountryFlag = '🇺🇸';
  String _phoneNumber = '';
  String _phoneHint = '(202) 555-0123';
  String _phoneFormat = '(XXX) XXX-XXXX';
  num phoneLimit = 10;

  final List<Map<String, String>> _countries = [
    {
      'code': '+1',
      'limit': '10',
      'flag': '🇺🇸',
      'name': 'United States',
      'hint': '(202) 555-0123',
      'format': '(XXX) XXX-XXXX',
    },
    {
      'code': '+91',
      'limit': '10',
      'flag': '🇮🇳',
      'name': 'India',
      'hint': '98765 43210',
      'format': 'XXXXX XXXXX',
    },
    {
      'code': '+44',
      'limit': '10',
      'flag': '🇬🇧',
      'name': 'United Kingdom',
      'hint': '7123 456789',
      'format': 'XXXX XXXXXX',
    },
    {
      'code': '+34',
      'limit': '9',
      'flag': '🇪🇸',
      'name': 'Spain',
      'hint': '612 345 678',
      'format': 'XXX XXX XXX',
    },
    {
      'code': '+86',
      'limit': '11',
      'flag': '🇨🇳',
      'name': 'China',
      'hint': '138 0013 8000',
      'format': 'XXX XXXX XXXX',
    },
    {
      'code': '+33',
      'limit': '9',
      'flag': '🇫🇷',
      'name': 'France',
      'hint': '6 12 34 56 78',
      'format': 'X XX XX XX XX',
    },
    {
      'code': '+49',
      'limit': '11',
      'flag': '🇩🇪',
      'name': 'Germany',
      'hint': '151 234 56789',
      'format': 'XXX XXX XXXXX',
    },
    {
      'code': '+81',
      'limit': '10',
      'flag': '🇯🇵',
      'name': 'Japan',
      'hint': '03-1234-5678',
      'format': 'XX-XXXX-XXXX',
    },
    {
      'code': '+61',
      'limit': '9',
      'flag': '🇦🇺',
      'name': 'Australia',
      'hint': '4 1234 5678',
      'format': 'X XXXX XXXX',
    },
    {
      'code': '+82',
      'limit': '10',
      'flag': '🇰🇷',
      'name': 'South Korea',
      'hint': '010-2345-6789',
      'format': 'XXX-XXXX-XXXX',
    },
    {
      'code': '+55',
      'limit': '11',
      'flag': '🇧🇷',
      'name': 'Brazil',
      'hint': '(11) 91234-5678',
      'format': '(XX) XXXXX-XXXX',
    },
  ];

  @override
  void initState() {
    super.initState();
    _setDefaultCountry();
    _countryCodeController.text = '$_selectedCountryFlag $_selectedCountryCode';
  }

  void _setDefaultCountry() {
    // Auto-detect country based on system locale (simplified approach)
    // You can enhance this with a proper country detection package
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final countryCode = locale.countryCode;
    
    Map<String, String>? defaultCountry;
    
    switch (countryCode) {
      case 'US':
        defaultCountry = _countries.firstWhere((c) => c['code'] == '+1');
        break;
      case 'IN':
        defaultCountry = _countries.firstWhere((c) => c['code'] == '+91');
        break;
      case 'GB':
        defaultCountry = _countries.firstWhere((c) => c['code'] == '+44');
        break;
      case 'CN':
        defaultCountry = _countries.firstWhere((c) => c['code'] == '+86');
        break;
      case 'FR':
        defaultCountry = _countries.firstWhere((c) => c['code'] == '+33');
        break;
      case 'DE':
        defaultCountry = _countries.firstWhere((c) => c['code'] == '+49');
        break;
      case 'JP':
        defaultCountry = _countries.firstWhere((c) => c['code'] == '+81');
        break;
      case 'AU':
        defaultCountry = _countries.firstWhere((c) => c['code'] == '+61');
        break;
      case 'KR':
        defaultCountry = _countries.firstWhere((c) => c['code'] == '+82');
        break;
      case 'BR':
        defaultCountry = _countries.firstWhere((c) => c['code'] == '+55');
        break;
      default:
        defaultCountry = _countries.first; // Default to US
    }
    
    if (defaultCountry != null) {
      _selectedCountryCode = defaultCountry['code']!;
      _selectedCountryFlag = defaultCountry['flag']!;
      _phoneHint = defaultCountry['hint']!;
      _phoneFormat = defaultCountry['format']!;
      phoneLimit = int.parse(defaultCountry['limit']!);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _countryCodeController.dispose();
    _phoneController.removeListener(() {});
    super.dispose();
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Country',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _countries.length,
                itemBuilder: (context, index) {
                  final country = _countries[index];
                  return ListTile(
                    leading: Text(
                      country['flag']!,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    title: Text(
                      country['name']!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    trailing: Text(
                      country['code']!,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium!.hint(context),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCountryCode = country['code']!;
                        _selectedCountryFlag = country['flag']!;
                        _countryCodeController.text =
                            '$_selectedCountryFlag $_selectedCountryCode';
                        _phoneHint = country['hint']!;
                        _phoneFormat = country['format']!;
                        phoneLimit = int.parse(country['limit']!);
                        _phoneController.clear();
                        _phoneNumber = '';
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPhoneNumber(String input) {
    String digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = '';
    int digitIndex = 0;
    
    for (int i = 0; i < _phoneFormat.length && digitIndex < digitsOnly.length; i++) {
      if (_phoneFormat[i] == 'X') {
        formatted += digitsOnly[digitIndex];
        digitIndex++;
      } else {
        formatted += _phoneFormat[i];
      }
    }
    
    return formatted;
  }
  
  String _getDigitsOnly(String formatted) {
    return formatted.replaceAll(RegExp(r'[^0-9]'), '');
  }

  void _handleContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isResponseLoading = true;
      });
      final digitsOnly = _getDigitsOnly(_phoneNumber);
      final fullNumber = _selectedCountryCode + digitsOnly;
      debugPrint('Phone Number payload to send: $fullNumber');
      BlocProvider.of<AuthBloc>(
        context,
      ).add(SendOtpRequested(phone: fullNumber, email: null, otpId: 'not-initialized-yet'));
      // Do not check state here; BlocListener will handle navigation and errors.
    }
  }

@override
Widget build(BuildContext context) {
  return BlocListener<AuthBloc, AuthState>(
    listener: (context, state) {
      if (state is OtpSent) {
        setState(() {
          _isResponseLoading = false;
        });
        debugPrint('OTP sent successfully: $state');
        Navigator.pushNamed(
          context,
          AppRoutes.otpVerification,
          arguments: {
            'phoneNumber': _selectedCountryCode + _phoneNumber,
            'otpId': state.otpId,
          },
        );
      } else if (state is ErrorWhileSendingOtp) {
        setState(() {
          _isResponseLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    },
    child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus(); // 🔑 dismiss keyboard + unfocus input
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Let’s get started.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'What’s your number?',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: UnderlinedTextField(
                            hint: '+91',
                            readOnly: true,
                            onTap: _showCountryPicker,
                            controller: _countryCodeController,
                            textAlign: TextAlign.end,
                            textStyle: Theme.of(context).textTheme.displaySmall,
                            hintStyle: Theme.of(context)
                                .textTheme
                                .displaySmall!
                                .secondary(context),
                            suffixIcon: Icon(
                              Icons.keyboard_arrow_down,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .secondary(context)
                                  .color,
                              size: 20,
                            ),
                          ),
                        ),
                        Expanded(
                          child: UnderlinedTextField(
                            key: ValueKey(_phoneHint),
                            hint: _phoneHint,
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textAlign: TextAlign.start,
                            inputFormatters: [
                              _PhoneNumberFormatter(_phoneFormat),
                              LengthLimitingTextInputFormatter(
                                _phoneFormat.length,
                              ),
                            ],
                            onChanged: (value) {
                              final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
                              setState(() {
                                _phoneNumber = digitsOnly;
                              });
                            },
                            textStyle: Theme.of(context).textTheme.displaySmall,
                            hintStyle: Theme.of(context)
                                .textTheme
                                .displaySmall!
                                .secondary(context),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your\nphone number';
                              }
                              final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
                              if (digitsOnly.length != phoneLimit) {
                                return 'Phone number should be $phoneLimit digits';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Continue',
                      onPressed:
                          _getDigitsOnly(_phoneController.text).length == phoneLimit ? _handleContinue : null,
                      isDisabled: _getDigitsOnly(_phoneController.text).length != phoneLimit,
                      isLoading: _isResponseLoading,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall,
                        children: [
                          const TextSpan(
                            text: 'By continuing, you agree to our ',
                          ),
                          TextSpan(
                            text: 'terms of service',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .hint(context),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'privacy policy',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .hint(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}

class _PhoneNumberFormatter extends TextInputFormatter {
  final String format;
  
  _PhoneNumberFormatter(this.format);
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digitsOnly.isEmpty) {
      return const TextEditingValue();
    }
    
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
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
