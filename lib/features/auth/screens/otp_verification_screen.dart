import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:sms_autofill/sms_autofill.dart';
import '../../../core/config/constants/routes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/back_button.dart';
import '../../../core/widgets/otp_input_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../services/otp_service.dart';
import '../components/otp_permission_handler.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? phoneNumber;
  final String? otpId;
  
  const OtpVerificationScreen({
    super.key,
    this.phoneNumber,
    this.otpId,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

// Backwards compatibility alias
typedef OtpVerificationPage = OtpVerificationScreen;

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  // Controllers
  final OtpController _otpController = OtpController();
  final OtpService _otpService = OtpService();
  
  // State variables
  String _otp = '';
  String _phoneNumber = '';
  String? _otpId;
  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;
  bool _isLoading = false;
  bool _isAutoCapturing = false;
  bool _hasRequestedPermission = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    
    // Initialize with constructor parameters if provided
    if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
      _phoneNumber = widget.phoneNumber!;
      debugPrint('Phone number from constructor: "$_phoneNumber"');
    }
    
    if (widget.otpId != null && widget.otpId!.isNotEmpty) {
      _otpId = widget.otpId!;
      debugPrint('OTP ID from constructor: "$_otpId"');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use post frame callback to ensure route is fully established
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _extractNavigationArguments();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpService.dispose();
    super.dispose();
  }

  void _extractNavigationArguments() {
    // Only use navigation arguments as fallback if constructor parameters weren't provided
    if (_phoneNumber.isEmpty || _otpId == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      debugPrint('Navigation arguments (fallback): $args');
      
      if (args != null) {
        final newPhoneNumber = args['phone'] ?? '';
        final newOtpId = args['otpId'];
        
        setState(() {
          if (_phoneNumber.isEmpty && newPhoneNumber.isNotEmpty) {
            _phoneNumber = newPhoneNumber;
          }
          if (_otpId == null && newOtpId != null) {
            _otpId = newOtpId;
          }
        });
        
        debugPrint('Extracted from navigation - Phone: "$_phoneNumber", OtpId: "$_otpId"');
      } else {
        debugPrint('No navigation arguments found');
      }
    } else {
      debugPrint('Using constructor parameters - Phone: "$_phoneNumber", OtpId: "$_otpId"');
    }
    
    // Start auto-capture if we have the required data
    if (!_hasRequestedPermission && _phoneNumber.isNotEmpty && _otpId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestAutoCapture();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Additional safety check for navigation arguments in build method
    if (_phoneNumber.isEmpty || _otpId == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null) {
        debugPrint('Getting navigation arguments in build method: $args');
        final newPhoneNumber = args['phone'] ?? '';
        final newOtpId = args['otpId'];
        
        if (newPhoneNumber.isNotEmpty && newOtpId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _phoneNumber = newPhoneNumber;
                _otpId = newOtpId;
              });
              debugPrint('Set from build method - Phone: "$_phoneNumber", OtpId: "$_otpId"');
            }
          });
        }
      }
    }
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: BlocListener<AuthBloc, AuthState>(
            listener: _handleAuthStateChanges,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomBackButton(),
                const SizedBox(height: 40),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildOtpInput(),
                const SizedBox(height: 60),
                _buildResendSection(),
                const Spacer(),
                // Hide the existing auto-capture indicator
                // AutoCaptureIndicator(isActive: _isAutoCapturing),
                _buildVerifyButton(),
                const SizedBox(height: 24),
                _buildTermsAndPrivacy(),
              ],
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
    );
  }

  Widget _buildOtpInput() {
    return Column(
      children: [
        Stack(
          children: [
            // Hidden TextFieldPinAutoFill for SMS auto-capture (iOS/Android)
            Positioned(
              left: -1000,
              top: -1000,
              child: SizedBox(
                width: 1,
                height: 1,
                child: TextFieldPinAutoFill(
                  codeLength: 6,
                  autoFocus: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                  currentCode: _otp,
                  onCodeSubmitted: (code) {
                    debugPrint('AutoFill: Code submitted: "$code"');
                    if (code.length == 6) {
                      _handleAutoFilledCode(code);
                    }
                  },
                  onCodeChanged: (code) {
                    debugPrint('AutoFill: Code changed: "$code"');
                    if (code.length == 6) {
                      _handleAutoFilledCode(code);
                    }
                  },
                ),
              ),
            ),
            // Visible custom OTP input fields
            OtpInputField(
              length: 6,
              controller: _otpController,
              autofillHints: const [
                AutofillHints.oneTimeCode,
              ],
              onCompleted: (otp) {
                debugPrint('OTP Completed manually: "$otp"');
                // Schedule state update after build completes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _otp = otp;
                    });

                    // Auto-verify when 6 digits are entered manually
                    if (otp.length == 6 && _phoneNumber.isNotEmpty && _otpId != null && !_isLoading) {
                      debugPrint('Auto-verifying manually entered OTP');
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted && !_isLoading && _otp == otp) {
                          _performOtpVerification();
                        }
                      });
                    }
                  }
                });
              },
              onChanged: (value) {
                debugPrint('OTP Changed: "$value", Length: ${value.length}');
                // Schedule state update after build completes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _otp = value;
                    });
                  }
                });
              },
            ),
          ],
        ),
        if (_isAutoCapturing)
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Auto-detecting',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildResendSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Resend code in ',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        GestureDetector(
          onTap: _canResend ? _handleResendOtp : null,
          child: Text(
            _canResend 
                ? 'Send Again' 
                : '00:${_resendCountdown.toString().padLeft(2, '0')}s',
            style: _canResend
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
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: _otp.length == 6 ? 'Confirm' : 'Verify OTP',
        onPressed: _handleVerifyOtp,
        isDisabled: false,
        isLoading: _isLoading,
      ),
    );
  }

  Widget _buildTermsAndPrivacy() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: Theme.of(context).colorScheme.outline,
          ),
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
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
    );
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


  void _handleVerifyOtp() {
    debugPrint('Verify OTP clicked - OTP: "$_otp", Length: ${_otp.length}, Phone: "$_phoneNumber", OtpId: "$_otpId"');
    
    if (_otp.length == 6 && _phoneNumber.isNotEmpty && _otpId != null) {
      _performOtpVerification();
    } else {
      String errorMessage = 'Please enter the complete 6-digit OTP';
      
      if (_otp.length != 6) {
        errorMessage = 'Please enter all 6 digits (current: ${_otp.length})';
      } else if (_phoneNumber.isEmpty) {
        errorMessage = 'Phone number is missing';
      } else if (_otpId == null) {
        errorMessage = 'OTP session expired. Please go back and resend OTP';
      }
      
      debugPrint('OTP Validation failed: $errorMessage');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _performOtpVerification() {
    if (_isLoading) return; // Prevent duplicate calls
    
    setState(() {
      _isLoading = true;
    });
    
    context.read<AuthBloc>().add(
      VerifyOtpRequested(
        phone: _phoneNumber,
        otp: _otp,
        otpId: _otpId!,
      ),
    );
  }

  void _handleResendOtp() {
    if (_canResend && _phoneNumber.isNotEmpty && _otpId != null) {
      _otpController.clear();
      setState(() {
        _otp = '';
      });
      
      context.read<AuthBloc>().add(
        ResendOtpRequested(phone: _phoneNumber, otpId: _otpId!),
      );
      
      _startResendTimer();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent again'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _requestAutoCapture() async {
    if (_hasRequestedPermission) return;

    setState(() {
      _hasRequestedPermission = true;
    });

    // Directly request permission without showing dialog
    final hasPermission = await OtpPermissionHandler.handlePermissionRequest(context);

    if (hasPermission && mounted) {
      _startAutoCapture();
    } else if (mounted) {
      // If permission denied, silently continue with manual entry
      debugPrint('Auto-capture permission denied, continuing with manual entry');
    }
  }

  void _handleAutoFilledCode(String code) {
    debugPrint('Handling auto-filled code: "$code"');
    
    // Schedule state update after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && code.length == 6) {
        setState(() {
          _otp = code;
          _isAutoCapturing = false;
        });
        
        // Update the visible OTP input fields
        _otpController.setText(code);

        // Auto-confirm when 6 digits are entered
        if (_phoneNumber.isNotEmpty && _otpId != null && !_isLoading) {
          debugPrint('Auto-confirm triggered for auto-filled OTP');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_isLoading && _otp == code) {
              debugPrint('Executing auto-confirmation for OTP: $code');
              _performOtpVerification();
            }
          });
        }
      }
    });
  }

  void _startAutoCapture() {
    setState(() {
      _isAutoCapturing = true;
    });

    _otpService.startListening(
      onOtpReceived: (otp) {
        if (mounted) {
          setState(() {
            _isAutoCapturing = false;
            _otp = otp;
          });

          _otpController.setText(otp);

          // Silently verify without showing snackbar
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _otp.length == 6) {
              _performOtpVerification();
            }
          });
        }
      },
      onTimeout: () {
        if (mounted) {
          setState(() {
            _isAutoCapturing = false;
          });
        }
      },
      onError: () {
        if (mounted) {
          setState(() {
            _isAutoCapturing = false;
          });
        }
      },
    );
  }

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    debugPrint('OTP Screen - BLoC State: ${state.runtimeType}');
    debugPrint('OTP Screen - Full state details: $state');

    switch (state) {
      case OtpSent():
        // Don't override navigation arguments with BLoC state
        // Navigation arguments take precedence
        debugPrint('OtpSent state received but navigation arguments take precedence');
        break;

      case VerifyingOtp():
        debugPrint('VerifyingOtp state - Setting loading to true');
        setState(() {
          _isLoading = true;
        });
        break;

      case OtpVerified():
        debugPrint('OTP verification successful');
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          final route = state.authResponse.user.activeStep == 1
              ? AppRoutes.userInfo
              : AppRoutes.dashboardHome;

          Navigator.of(context).pushReplacementNamed(route);
        }
        break;

      case ErrorWhileOtpVerification():
        debugPrint('========================================');
        debugPrint('ERROR STATE DETECTED!');
        debugPrint('OTP Verification Error: ${state.message}');
        debugPrint('Error email: ${state.email}');
        debugPrint('Error phone: ${state.phone}');
        debugPrint('Mounted: $mounted');
        debugPrint('========================================');

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          debugPrint('Attempting to show error snackbar...');
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message.isNotEmpty ? state.message : 'Invalid or expired OTP. Please try again.',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );
            debugPrint('Snackbar shown successfully');
          } catch (e) {
            debugPrint('Error showing snackbar: $e');
          }
        }

        // Also clear the OTP input so user can try again
        _otpController.clear();
        setState(() {
          _otp = '';
        });
        break;

      case OtpResent():
        setState(() {
          if (state.otpId != null) {
            _otpId = state.otpId;
          }
        });
        break;

      case ErrorWhileSendingOtp():
        debugPrint('Error while sending OTP: ${state.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        break;

      default:
        debugPrint('Unhandled auth state: ${state.runtimeType}');
    }
  }
}