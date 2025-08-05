import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/constants/theme.dart';
import 'package:nepika/presentation/bloc/auth/auth_bloc.dart';
import 'package:nepika/presentation/bloc/auth/auth_event.dart';
import 'package:nepika/presentation/bloc/auth/auth_state.dart';
import '../../../core/constants/routes.dart';
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
  String _selectedCountryCode = '+91';
  String _selectedCountryFlag = '🇮🇳';
  String _phoneNumber = '';
  String _phoneHint = '9876543210';
  num phoneLimit = 10;

  final List<Map<String, String>> _countries = [
    {
      'code': '+1',
      'limit': '10',
      'flag': '🇺🇸',
      'name': 'United States',
      'hint': '2025550123',
    },
    {
      'code': '+91',
      'limit': '10',
      'flag': '🇮🇳',
      'name': 'India',
      'hint': '9876543210',
    },
    {
      'code': '+44',
      'limit': '10',
      'flag': '🇬🇧',
      'name': 'United Kingdom',
      'hint': '7123456789',
    },
    {
      'code': '+86',
      'limit': '11',
      'flag': '🇨🇳',
      'name': 'China',
      'hint': '13800138000',
    },
    {
      'code': '+33',
      'limit': '9',
      'flag': '🇫🇷',
      'name': 'France',
      'hint': '612345678',
    },
    {
      'code': '+49',
      'limit': '11',
      'flag': '🇩🇪',
      'name': 'Germany',
      'hint': '15123456789',
    },
    {
      'code': '+81',
      'limit': '10',
      'flag': '🇯🇵',
      'name': 'Japan',
      'hint': '0312345678',
    },
    {
      'code': '+61',
      'limit': '9',
      'flag': '🇦🇺',
      'name': 'Australia',
      'hint': '412345678',
    },
    {
      'code': '+82',
      'limit': '10',
      'flag': '🇰🇷',
      'name': 'South Korea',
      'hint': '1023456789',
    },
    {
      'code': '+55',
      'limit': '11',
      'flag': '🇧🇷',
      'name': 'Brazil',
      'hint': '11912345678',
    },
  ];

  @override
  void initState() {
    super.initState();
    _countryCodeController.text = '$_selectedCountryFlag $_selectedCountryCode';
    // _phoneController.addListener(() {
    //   setState(() {
    //     _phoneNumber = _phoneController.text;
    //   });
    //   _phoneHint = _countries.firstWhere(
    //     (country) => country['code'] == _selectedCountryCode,
    //     orElse: () => {'hint': '000 000 0000'},
    //   )['hint']!;
    // });
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
                        phoneLimit = int.parse(country['limit']!);
                        _phoneController.clear();
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

  void _handleContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isResponseLoading = true;
      });
      final fullNumber = _selectedCountryCode + _phoneNumber;
      debugPrint('Phone Number payload to send: $fullNumber');
      BlocProvider.of<AuthBloc>(
        context,
      ).add(SendOtpRequested(phone: fullNumber, email: null));
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
          Navigator.pushNamed(
            context,
            AppRoutes.otpVerification,
            arguments: {'phoneNumber': _selectedCountryCode + _phoneNumber},
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  const SizedBox(height: 60),
                  // Title
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Let’s get started.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'What’s your number?',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Phone number input
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
                            textAlign: TextAlign.center,
                            textStyle: Theme.of(context).textTheme.displaySmall,
                            hintStyle: Theme.of(
                              context,
                            ).textTheme.displaySmall!.secondary(context),
                            suffixIcon: Icon(
                              Icons.keyboard_arrow_down,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall!.secondary(context).color,
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
                            textAlign: TextAlign.center,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(
                                phoneLimit.toInt(),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _phoneNumber = value;
                              });
                            },
                            textStyle: Theme.of(context).textTheme.displaySmall,
                            hintStyle: Theme.of(
                              context,
                            ).textTheme.displaySmall!.secondary(context),

                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your\nphone number';
                              }
                              if (value.length != phoneLimit) {
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
                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Continue',
                      onPressed: _phoneNumber.length == phoneLimit
                          ? _handleContinue
                          : null,
                      isDisabled: _phoneNumber.length != phoneLimit,

                      isLoading: _isResponseLoading,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Terms and privacy
                  
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
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall!.hint(context),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'privacy policy',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall!.hint(context),
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
    );
  }
}
