import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../core/config/constants/routes.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/back_button.dart';
import '../../../core/widgets/otp_input_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../services/otp_service.dart';
import '../components/otp_permission_handler.dart';
import '../components/auto_capture_indicator.dart';

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
                AutoCaptureIndicator(isActive: _isAutoCapturing),
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
    return OtpInputField(
      length: 6,
      controller: _otpController,
      onCompleted: _handleOtpCompleted,
      onChanged: (value) {
        debugPrint('OTP Changed: "$value", Length: ${value.length}');
        setState(() {
          _otp = value;
        });
        
        // Auto-confirm when 6 digits are entered via manual typing
        if (value.length == 6 && _phoneNumber.isNotEmpty && _otpId != null && !_isLoading) {
          debugPrint('Auto-confirm triggered for manually entered OTP');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_isLoading && _otp == value) {
              debugPrint('Executing auto-confirmation for OTP: $value');
              _performOtpVerification();
            }
          });
        }
      },
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
        text: _isAutoCapturing
            ? 'Waiting for OTP...'
            : _otp.length == 6
                ? 'Confirm'
                : 'Verify OTP',
        onPressed: _handleVerifyOtp,
        isDisabled: false,
        isLoading: _isLoading || _isAutoCapturing,
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

  void _handleOtpCompleted(String otp) {
    debugPrint('OTP Completed: "$otp", Length: ${otp.length}');
    setState(() {
      _otp = otp;
    });
    
    if (otp.length == 6 && _phoneNumber.isNotEmpty && _otpId != null && !_isLoading) {
      debugPrint('Auto-confirm triggered for completed OTP');
      // Add a small delay to ensure UI updates are complete
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_isLoading) {
          debugPrint('Executing auto-confirmation for completed OTP: $otp');
          _performOtpVerification();
        }
      });
    } else {
      debugPrint('OTP completion validation failed - Length: ${otp.length}, Phone: "$_phoneNumber", OtpId: "$_otpId", Loading: $_isLoading');
    }
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

    final shouldAutoCapture = await OtpPermissionHandler.showPermissionDialog(context);
    
    if (shouldAutoCapture && mounted) {
      final hasPermission = await OtpPermissionHandler.handlePermissionRequest(context);
      
      if (hasPermission && mounted) {
        _startAutoCapture();
      }
    }
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
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP captured successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
          
          Future.delayed(const Duration(milliseconds: 800), () {
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
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Auto-capture timed out. Please enter OTP manually.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      },
      onError: () {
        if (mounted) {
          setState(() {
            _isAutoCapturing = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Auto-capture error. Please enter OTP manually.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listening for incoming OTP SMS...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    debugPrint('OTP Screen - BLoC State: ${state.runtimeType}');
    
    switch (state) {
      case OtpSent():
        // Don't override navigation arguments with BLoC state
        // Navigation arguments take precedence
        debugPrint('OtpSent state received but navigation arguments take precedence');
        break;
        
      case VerifyingOtp():
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
          final route = state.authResponse.user.activeStep == 0
              ? AppRoutes.userInfo
              : AppRoutes.dashboardHome;
              
          Navigator.of(context).pushReplacementNamed(route);
        }
        break;
        
      case ErrorWhileOtpVerification():
        debugPrint('OTP Verification Error: ${state.message}');
        setState(() {
          _isLoading = false;
        });
        
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
        
      case OtpResent():
        setState(() {
          if (state.otpId != null) {
            _otpId = state.otpId;
          }
        });
        break;
    }
  }
}