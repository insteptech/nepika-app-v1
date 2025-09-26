import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/constants/routes.dart';
import '../../../core/widgets/custom_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/phone_input_widget.dart';
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
  String _fullPhoneNumber = '';

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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
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
        onPressed: _isPhoneValid ? _handleContinue : null,
        isDisabled: !_isPhoneValid,
        isLoading: _isLoading,
      ),
    );
  }

  Widget _buildTermsAndPrivacy() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(
              text: 'terms of service',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'privacy policy',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
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
        _isLoading = true;
      });
      
      debugPrint('Sending OTP to: $_fullPhoneNumber');
      context.read<AuthBloc>().add(
        SendOtpRequested(
          phone: _fullPhoneNumber,
          email: null,
          otpId: 'not-initialized-yet',
        ),
      );
    }
  }

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    debugPrint('Phone Entry - BLoC State: ${state.runtimeType}');
    
    if (state is OtpSent) {
      setState(() {
        _isLoading = false;
      });
      
      debugPrint('OTP sent successfully - Phone: "${state.phone}", OtpId: "${state.otpId}"');
      
      final arguments = {
        'phone': state.phone,
        'otpId': state.otpId,
      };
      
      debugPrint('Navigation arguments being passed: $arguments');
      
      // Use direct navigation with constructor parameters to ensure data is passed
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            phoneNumber: state.phone,
            otpId: state.otpId ?? '',
          ),
          settings: const RouteSettings(
            name: AppRoutes.otpVerification,
          ),
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