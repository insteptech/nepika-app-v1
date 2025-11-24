import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/constants/routes.dart';
import '../../../core/config/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/shared_prefs_helper.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/phone_input_widget.dart';
import '../services/app_signature_service.dart';
import 'otp_verification_screen.dart';

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

// Backwards compatibility alias
typedef PhoneEntryPage = PhoneEntryScreen;

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPhoneValid = false;
  bool _isTermsAccepted = true;
  String _fullPhoneNumber = '';

  @override
  void initState() {
    super.initState();
    // Load saved terms acceptance state
    _loadTermsAcceptanceState();
    // Start SMS listener immediately when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSmsListener();
    });
  }

  Future<void> _loadTermsAcceptanceState() async {
    final prefs = SharedPrefsHelper();
    final savedValue = await prefs.getBool(AppConstants.termsAcceptedKey);
    setState(() {
      _isTermsAccepted = savedValue;
    });
  }

  Future<void> _saveTermsAcceptanceState(bool value) async {
    final prefs = SharedPrefsHelper();
    await prefs.setBool(AppConstants.termsAcceptedKey, value);
  }

  @override
  void dispose() {
    // Unfocus keyboard when screen is disposed
    FocusScope.of(context).unfocus();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _handleAuthStateChanges,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // const Spacer(),
                    const SizedBox(height: 60),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildPhoneInput(),
                    const Spacer(),
                    _buildContinueButton(),
                    const SizedBox(height: 24),
                    _buildTermsAndPrivacy(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Text(
            'Let\'s get started.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'What\'s your number?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: PhoneInputWidget(
        onPhoneChanged: (phone) => _fullPhoneNumber = phone,
        onValidationChanged: (isValid) {
          setState(() {
            _isPhoneValid = isValid;
          });
        },
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Continue',
        onPressed: (_isPhoneValid && _isTermsAccepted) ? _handleContinue : null,
        isDisabled: !(_isPhoneValid && _isTermsAccepted),
        isLoading: _isLoading,
      ),
    );
  }

  Widget _buildTermsAndPrivacy() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _isTermsAccepted,
              onChanged: (bool? value) {
                final newValue = value ?? false;
                setState(() {
                  _isTermsAccepted = newValue;
                });
                _saveTermsAcceptanceState(newValue);
              },
              activeColor: Theme.of(context).colorScheme.primary,
              checkColor: Colors.white,
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 1.5,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),

          const SizedBox(width: 12),

          // Terms text
          Expanded(
            child: GestureDetector(
              onTap: () {
                final newValue = !_isTermsAccepted;
                setState(() {
                  _isTermsAccepted = newValue;
                });
                _saveTermsAcceptanceState(newValue);
              },
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodySmall,
                  children: [
                    const TextSpan(text: 'By continuing, you agree to our '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed(AppRoutes.termsOfUse);
                        },
                        child: Text(
                          'Terms of Service',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed(AppRoutes.privacyPolicy);
                        },
                        child: Text(
                          'Privacy Policy',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startSmsListener() {
    debugPrint('PhoneEntryScreen: _startSmsListener() called');

    try {
      // Start listening for SMS directly
      debugPrint('PhoneEntryScreen: Starting SmsAutoFill listener...');
      SmsAutoFill().listenForCode();
      debugPrint(
        'PhoneEntryScreen: SmsAutoFill.listenForCode() called successfully',
      );

      // Also listen to the stream to verify it's working
      debugPrint('PhoneEntryScreen: Setting up SMS code stream listener...');
      SmsAutoFill().code
          .listen((code) {
            debugPrint('PhoneEntryScreen: SMS stream received code: $code');
          })
          .onError((error) {
            debugPrint('PhoneEntryScreen: SMS stream error: $error');
          });

      debugPrint('PhoneEntryScreen: SMS listener setup completed successfully');
    } catch (e, stackTrace) {
      debugPrint('PhoneEntryScreen: Exception in SMS listener setup: $e');
      debugPrint('PhoneEntryScreen: Stack trace: $stackTrace');
    }
  }

  void _handleContinue() async {
    debugPrint('PhoneEntryScreen: _handleContinue() called');
    debugPrint(
      'PhoneEntryScreen: Form validation result: ${_formKey.currentState?.validate() ?? false}',
    );

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      debugPrint('PhoneEntryScreen: Starting OTP send process...');
      debugPrint('PhoneEntryScreen: Phone number: $_fullPhoneNumber');

      debugPrint(
        'PhoneEntryScreen: Getting app signature for SMS auto-fill...',
      );

      final appSignature = await AppSignatureService.instance.getAppSignature();

      debugPrint('PhoneEntryScreen: App signature result: "$appSignature"');
      debugPrint(
        'PhoneEntryScreen: App signature is null: ${appSignature == null}',
      );
      debugPrint(
        'PhoneEntryScreen: App signature is empty: ${appSignature?.isEmpty ?? true}',
      );

      if (!mounted) return;

      debugPrint('PhoneEntryScreen: Creating SendOtpRequested event...');
      final uuid = const Uuid();
      final otpId = uuid.v4();
      debugPrint('PhoneEntryScreen: Generated OTP ID: "$otpId"');

      final event = SendOtpRequested(
        phone: _fullPhoneNumber,
        email: null,
        otpId: otpId,
        appSignature: appSignature,
      );

      debugPrint(
        'PhoneEntryScreen: Event created with appSignature: "${event.appSignature}"',
      );
      debugPrint('PhoneEntryScreen: Dispatching event to AuthBloc...');

      context.read<AuthBloc>().add(event);
    }
  }

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    debugPrint('Phone Entry - BLoC State: ${state.runtimeType}');

    if (state is OtpSent) {
      setState(() {
        _isLoading = false;
      });

      debugPrint(
        'OTP sent successfully - Phone: "${state.phone}", OtpId: "${state.otpId}"',
      );

      final arguments = {'phone': state.phone, 'otpId': state.otpId};

      debugPrint('Navigation arguments being passed: $arguments');

      // Use direct navigation with constructor parameters to ensure data is passed
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            phoneNumber: state.phone,
            otpId: state.otpId ?? '',
          ),
          settings: const RouteSettings(name: AppRoutes.otpVerification),
        ),
      );
    } else if (state is ErrorWhileSendingOtp) {
      setState(() {
        _isLoading = false;
      });

      debugPrint('Error sending OTP: ${state.message}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send OTP: ${state.message}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
