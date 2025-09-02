import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'dart:async';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/back_button.dart';
import '../../../core/widgets/otp_input_field.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/auth/auth_event.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  String _otp = '';
  String _phoneNumber = '';
  String? _otpId;
  Timer? _timer;
  int _resendTimer = 60;
  bool _canResend = false;
  bool _isResponseLoading = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      _phoneNumber = args['phone'] ?? '';
      _otpId = args['otpId'];
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendTimer = 60;
    });
    
    _timer?.cancel(); // Cancel existing timer if any
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
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

  void _handleOtpCompleted(String otp) {
    setState(() {
      _otp = otp;
    });
    // Auto-verify when OTP is complete
    if (otp.length == 6) {
      _verifyOtp();
    }
  }

  void _verifyOtp() {
    if (_otp.length == 6 && _phoneNumber.isNotEmpty && _otpId != null) {
      setState(() {
        _isResponseLoading = true;
      });
      BlocProvider.of<AuthBloc>(context).add(
        VerifyOtpRequested(phone: _phoneNumber, otp: _otp, otpId: _otpId!)
      );
    } else {
      // Show error if required fields are missing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_otp.length != 6 
              ? 'Please enter complete 6-digit OTP' 
              : 'Missing phone number or OTP ID'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _resendOtp() {
    if (_canResend && _phoneNumber.isNotEmpty && _otpId != null) {
      BlocProvider.of<AuthBloc>(context).add(
        ResendOtpRequested(phone: _phoneNumber, otpId: _otpId!)
      );
      _startResendTimer();
      // Show success message with proper color
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP sent again'),
          backgroundColor: Colors.green, // Changed to green for success
        ),
      );
    } else if (!_canResend) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait ${_resendTimer}s before resending'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Missing phone number or OTP ID'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is OtpSent) {
                setState(() {
                  _phoneNumber = state.phone;
                  if (state.otpId != null) {
                    _otpId = state.otpId;
                  }
                });
              } 
              else if (state is OtpVerified) {
                setState(() {
                  _isResponseLoading = false;
                });
                // Show success message in green
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('OTP verified successfully!'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
                if (mounted) {
                  Navigator.of(context).pushNamed(
                    AppRoutes.userInfo
                  );
                  // NavigationHelper.navigateAfterOtpVerification(
                  //   context,
                  //   state.authResponse,
                  // );
                }
              } 
              else if (state is ErrorWhileOtpVerification) {
                setState(() {
                  _isResponseLoading = false;
                });
                // Show error message in red
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              // Handle resend OTP response
              else if (state is OtpResent) {
                setState(() {
                  if (state.otpId != null) {
                    _otpId = state.otpId;
                  }
                });
              }
            },
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) { 
                // Only update phone number and otpId if they're empty
                if (state is OtpSent && _phoneNumber.isEmpty) {
                  _phoneNumber = state.phone;
                  if (state.otpId != null) {
                    _otpId = state.otpId;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    const CustomBackButton(),

                    const SizedBox(height: 40),

                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Enter 6 digit verification code sent',
                            style: Theme.of(context).textTheme.displaySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'to $_phoneNumber',
                            style: Theme.of(context).textTheme.displaySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // OTP Input
                    OtpInputField(
                      length: 6,
                      onCompleted: _handleOtpCompleted,
                      onChanged: (value) {
                        setState(() {
                          _otp = value;
                        });
                      },
                    ),

                    const SizedBox(height: 60),

                    // Resend OTP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Resend code in ', 
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        GestureDetector(
                          onTap: _canResend ? _resendOtp : null, // Only allow tap when can resend
                          child: Text(
                            _canResend ? 'Send Again' : '00:${_resendTimer.toString().padLeft(2, '0')}s',
                            style: _canResend 
                              ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                )
                              : Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                )
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Confirm',
                        onPressed: _verifyOtp,
                        // isDisabled: _otp.length != 6,
                        isDisabled: true,
                        isLoading: _isResponseLoading,
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    // Terms and privacy
                    Center(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          children: [
                            const TextSpan(
                              text: 'By continuing, you agree to our ',
                            ),
                            TextSpan(
                              text: 'Terms of Service',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}