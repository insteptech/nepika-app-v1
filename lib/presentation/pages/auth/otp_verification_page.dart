import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
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
  bool _isAutoCapturing = false;
  bool _hasRequestedPermission = false;
  Timer? _autoCaptuteTimeout;
  final OtpController _otpController = OtpController();

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
      
      // Show auto-capture dialog immediately after getting the data
      if (!_hasRequestedPermission && _phoneNumber.isNotEmpty && _otpId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showAutoCapturePemissionDialog();
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoCaptuteTimeout?.cancel();
    SmsAutoFill().unregisterListener();
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
    // If OTP is complete, verify directly
    if (_otp.length == 6 && _phoneNumber.isNotEmpty && _otpId != null) {
      _performOtpVerification();
      return;
    }

    // If OTP is incomplete, show error message asking user to fill manually
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter the complete 6-digit OTP'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _performOtpVerification() {
    // Don't set loading state here - let BLoC handle it via VerifyingOtp state
    BlocProvider.of<AuthBloc>(context).add(
      VerifyOtpRequested(phone: _phoneNumber, otp: _otp, otpId: _otpId!)
    );
  }

  Future<void> _showAutoCapturePemissionDialog() async {
    if (_hasRequestedPermission) return;
    
    setState(() {
      _hasRequestedPermission = true;
    });

    final shouldAutoCapture = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Auto-capture OTP?'),
          content: const Text(
            'Would you like to automatically capture the OTP from the SMS we\'re sending? This will require SMS permission.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Enter Manually'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Auto-capture'),
            ),
          ],
        );
      },
    );

    if (shouldAutoCapture == true) {
      _requestAutoCapture();
    }
  }

  Future<void> _requestAutoCapture() async {
    // Request SMS permission
    final permissionStatus = await Permission.sms.request();
    
    if (permissionStatus.isGranted) {
      _startAutoCapture();
    } else if (permissionStatus.isDenied) {
      _showPermissionDialog();
    } else if (permissionStatus.isPermanentlyDenied) {
      _showPermissionSettingsDialog();
    }
  }

  void _startAutoCapture() {
    setState(() {
      _isAutoCapturing = true;
    });

    try {
      debugPrint('OTP AutoCapture: Starting SMS listener');
      
      // Initialize SmsAutoFill
      SmsAutoFill().listenForCode;
      
      // Get the app signature for SMS auto-fill
      SmsAutoFill().getAppSignature.then((signature) {
        debugPrint('OTP AutoCapture: App signature: $signature');
      }).catchError((error) {
        debugPrint('OTP AutoCapture: Error getting app signature: $error');
      });
      
      // Set up auto-capture timeout (45 seconds)
      _autoCaptuteTimeout = Timer(const Duration(seconds: 45), () {
        if (mounted) {
          debugPrint('OTP AutoCapture: Timeout reached');
          setState(() {
            _isAutoCapturing = false;
          });
          SmsAutoFill().unregisterListener();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Auto-capture timed out. Please enter OTP manually.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });

      // Register listener for incoming SMS
      SmsAutoFill().code.listen((code) {
        debugPrint('OTP AutoCapture: Received code: $code');
        
        if (code.isNotEmpty && code.length >= 4 && mounted) {
          // Extract 6 digit OTP from the received code
          final RegExp otpRegExp = RegExp(r'\d{6}');
          final Match? match = otpRegExp.firstMatch(code);
          
          if (match != null) {
            final extractedOtp = match.group(0)!;
            debugPrint('OTP AutoCapture: Extracted OTP: $extractedOtp');
            
            _autoCaptuteTimeout?.cancel();
            setState(() {
              _isAutoCapturing = false;
              _otp = extractedOtp;
            });
            
            // Auto-fill the OTP fields
            _otpController.setText(extractedOtp);
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP captured successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 1),
              ),
            );
            
            // Auto-verify after a short delay
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted && _otp.length == 6) {
                debugPrint('OTP AutoCapture: Auto-verifying OTP');
                _performOtpVerification();
              }
            });
          } else {
            debugPrint('OTP AutoCapture: No valid 6-digit OTP found in: $code');
          }
        }
      }).onError((error) {
        debugPrint('OTP AutoCapture: Error listening for code: $error');
        if (mounted) {
          setState(() {
            _isAutoCapturing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Auto-capture error. Please enter OTP manually.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listening for incoming OTP SMS...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      debugPrint('OTP AutoCapture: Exception in _startAutoCapture: $e');
      setState(() {
        _isAutoCapturing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start auto-capture. Please enter OTP manually.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('SMS Permission Required'),
          content: const Text(
            'To automatically capture OTP from SMS, we need permission to access your messages. You can still enter the OTP manually if you prefer.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Enter Manually'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestAutoCapture();
              },
              child: const Text('Grant Permission'),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Permanently Denied'),
          content: const Text(
            'SMS permission has been permanently denied. To enable auto-capture, please go to Settings and grant SMS permission manually.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _resendOtp() {
    if (_canResend && _phoneNumber.isNotEmpty && _otpId != null) {
      // Clear the OTP input field
      _otpController.clear();
      setState(() {
        _otp = '';
      });
      
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
              debugPrint('OTP Page - BLoC State: ${state.runtimeType}');
              if (state is OtpSent) {
                setState(() {
                  _phoneNumber = state.phone;
                  if (state.otpId != null) {
                    _otpId = state.otpId;
                  }
                });
              } 
              else if (state is VerifyingOtp) {
                setState(() {
                  _isResponseLoading = true;
                });
              }
              else if (state is OtpVerified) {
                debugPrint('OTP Page: Received OtpVerified state');
                setState(() {
                  _isResponseLoading = false;
                });
                
                // Navigate immediately - success feedback will be shown on destination screen
                if (mounted) {
                   if(state.authResponse.user.activeStep == 0){
                    Navigator.of(context).pushReplacementNamed(
                      AppRoutes.userInfo
                    );
                  }else{
                    Navigator.of(context).pushReplacementNamed(
                      AppRoutes.dashboardHome
                    );
                  }
                }
              } 
              else if (state is ErrorWhileOtpVerification) {
                debugPrint('OTP Verification Error: ${state.message}');
                setState(() {
                  _isResponseLoading = false;
                });
                // Show error message in red
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
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
                      controller: _otpController,
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

                    // Auto-capture status indicator
                    if (_isAutoCapturing)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Listening for OTP SMS...',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: _isAutoCapturing 
                            ? 'Waiting for OTP...' 
                            : _otp.length == 6 
                                ? 'Confirm'
                                : 'Verify OTP',
                        onPressed: _verifyOtp,
                        isDisabled: false,
                        isLoading: _isResponseLoading || _isAutoCapturing,
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