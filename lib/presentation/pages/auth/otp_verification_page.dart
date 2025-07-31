import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/constants/theme.dart';
import 'dart:async';
import '../../../core/constants/routes.dart';
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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimer = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _handleOtpCompleted(String otp) {
    setState(() {
      _otp = otp;
    });
  }

  void _verifyOtp() {
    if (_otp.length == 6 && _phoneNumber.isNotEmpty) {
      setState(() {
        _isResponseLoading = true;
      });
      BlocProvider.of<AuthBloc>(context).add(
        VerifyOtpRequested(phone: _phoneNumber, otp: _otp)
      );
    }
  }

  void _resendOtp() {
    if (_canResend && _phoneNumber.isNotEmpty) {
      setState(() {
        _canResend = false;
      });

      // Send OTP again using the same phone number
      BlocProvider.of<AuthBloc>(context).add(
        SendOtpRequested(phone: _phoneNumber, email: null)
      );

      _startResendTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP sent again'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              // Handle OtpSent to get phone number
              if (state is OtpSent) {
                setState(() {
                  _phoneNumber = state.phone;
                });
              } 
              // Handle successful authentication
              else if (state is OtpVerified) {
                setState(() {
                  _isResponseLoading = false;
                });
                
                print('Authentication successful, navigating to: ${AppRoutes.userInfo}');
                print('User data: ${state.user}');
                
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.userInfo,
                  (route) => false,
                ).then((_) {
                  print('Navigation completed successfully');
                }).catchError((error) {
                  print('Navigation error: $error');
                });
              } 
              // Handle OTP verification errors
              else if (state is OtpError) {
                setState(() {
                  _isResponseLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
              // Handle any other auth errors
              // else if (state is AuthError) {
              //   setState(() {
              //     _isResponseLoading = false;
              //   });
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     SnackBar(
              //       content: Text(state.message),
              //       backgroundColor: Theme.of(context).colorScheme.error,
              //     ),
              //   );
              // }
              // // Handle loading states
              // else if (state is VerifyingOtp) {
              //   setState(() {
              //     _isResponseLoading = true;
              //   });
              // }
              // else if (state is SendingOtp) {
              //   // Show loading state for resend OTP
              //   setState(() {
              //     _isResponseLoading = true;
              //   });
              // }
            },
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                // Get phone number from current state if available
                if (state is OtpSent && _phoneNumber.isEmpty) {
                  _phoneNumber = state.phone;
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
                          onTap: _canResend ? _resendOtp : null,
                          child: Text(
                            _canResend ? 'Send Again' : '00:${_resendTimer.toString().padLeft(2, '0')}s',
                            style: _canResend 
                              ? Theme.of(context).textTheme.bodyLarge!.hint(context) 
                              : Theme.of(context).textTheme.bodyLarge
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
                        onPressed: _otp.length == 6 && _phoneNumber.isNotEmpty ? _verifyOtp : null,
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