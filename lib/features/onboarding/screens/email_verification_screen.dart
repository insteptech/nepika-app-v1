import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/widgets/custom_button.dart';
import 'package:nepika/core/widgets/otp_input_field.dart';
import 'package:nepika/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:nepika/features/onboarding/bloc/onboarding_event.dart';
import 'package:nepika/features/onboarding/bloc/onboarding_state.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String otpId;
  final OnboardingBloc onboardingBloc;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.otpId,
    required this.onboardingBloc,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  String _otp = '';
  bool _isValid = false;
  String _currentOtpId = '';
  
  // Timer state
  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _currentOtpId = widget.otpId;
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });
    
    _resendTimer?.cancel();
    
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _handleResendOtp() {
    if (_canResend && !_isResending) {
      debugPrint('📧 Requesting email OTP resend for: ${widget.email}');
      setState(() {
        _isResending = true;
      });
      widget.onboardingBloc.add(ResendEmailOtp(email: widget.email));
      // Timer will be restarted in listener upon success
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.onboardingBloc,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              _restoreState();
              Navigator.of(context).pop();
            },
          ),
        ),
        body: BlocConsumer<OnboardingBloc, OnboardingState>(
          listener: (context, state) {
            if (state is OnboardingStepSubmitted || state is OnboardingCompleted) {
              Navigator.of(context).pop(); 
            } else if (state is OnboardingEmailVerificationRequired) {
              // Update OTP ID if resend was successful
              if (state.otpId.isNotEmpty && state.otpId != _currentOtpId) {
                setState(() {
                  _currentOtpId = state.otpId;
                  _isResending = false; // Stop loading
                });
                _startResendTimer(); // Restart timer on success
                
                debugPrint('📧 OTP ID updated to: $_currentOtpId');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('OTP sent again'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } else if (state is OnboardingError) {
              setState(() {
                _isResending = false; // Stop loading on error
              });
            }
          },
          builder: (context, state) {
            String? errorText;
            if (state is OnboardingError) {
              errorText = state.message;
            }
            final bool isLoading = state is OnboardingLoading;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Verify Email',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 24,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter the code sent to\n${widget.email}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    OtpInputField(
                      length: 6,
                      onCompleted: (otp) {
                        setState(() {
                          _otp = otp;
                          _isValid = otp.length == 6;
                        });
                      },
                      onChanged: (otp) {
                        setState(() {
                          _otp = otp;
                          _isValid = otp.length == 6;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    // Resend timer section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_canResend)
                          Text(
                            'Resend code in ',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        GestureDetector(
                          onTap: (_canResend && !_isResending) ? _handleResendOtp : null,
                          child: _isResending
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                )
                              : Text(
                                  _canResend 
                                      ? 'Send Again' 
                                      : '00:${_resendCountdown.toString().padLeft(2, '0')}s',
                                  style: (_canResend && !_isResending)
                                      ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        )
                                      : Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    CustomButton(
                      text: 'Verify',
                      isLoading: isLoading,
                      onPressed: (_isValid && !isLoading)
                          ? () {
                              widget.onboardingBloc.add(VerifyEmailOtp(
                                email: widget.email,
                                otpCode: _otp,
                                otpId: _currentOtpId,
                              ));
                            }
                          : null,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 24),
                    if (errorText != null) ...[
                      Text(
                        errorText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _restoreState() {
    // Restoration is handled by the parent OnboardingScreen
  }
}
