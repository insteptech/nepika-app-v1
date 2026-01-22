import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nepika/core/di/injection_container.dart' as di;
import 'package:nepika/core/widgets/custom_button.dart';
import 'package:nepika/core/widgets/custom_text_field.dart';
import 'package:nepika/core/widgets/otp_input_field.dart';
import 'package:nepika/domain/auth/repositories/auth_repository.dart';
import 'package:nepika/features/auth/widgets/phone_input_widget.dart';
import 'package:nepika/features/auth/screens/phone_entry_screen.dart'; // For navigation back to login if needed

class MobileRecoveryScreen extends StatefulWidget {
  const MobileRecoveryScreen({super.key});

  @override
  State<MobileRecoveryScreen> createState() => _MobileRecoveryScreenState();
}

enum RecoveryStep {
  emailInput,
  emailVerification,
  mobileInput,
  mobileVerification,
}

class _MobileRecoveryScreenState extends State<MobileRecoveryScreen> {
  final _authRepository = di.ServiceLocator.get<AuthRepository>();
  
  // Navigation State
  RecoveryStep _currentStep = RecoveryStep.emailInput;
  bool _isLoading = false;

  // Data State
  String _email = '';
  String _otpCode = '';
  String? _otpId;
  String? _recoveryToken;
  String _newMobileNumber = '';
  String _fullMobileNumber = '';
  bool _isPhoneValid = false;

  final TextEditingController _emailController = TextEditingController();

  // Timer State
  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _start = 60;
      _canResend = false;
    });
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
            _canResend = true;
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  // --- Step 1: Send Email OTP ---
  Future<void> _sendEmailOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authRepository.recoverSendEmailOtp(email: email);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => _showError(failure.message),
      (data) {
        setState(() {
          _email = email;
          _otpId = data['otp_id'];
          _currentStep = RecoveryStep.emailVerification;
          _otpCode = ''; // Reset OTP
        });
        _startTimer();
        _showMessage('Recovery code sent to your email');
      },
    );
  }

  // --- Step 2: Verify Email OTP ---
  Future<void> _verifyEmailOtp() async {
    if (_otpCode.length != 6) {
      _showError('Please enter a valid 6-digit code');
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authRepository.recoverVerifyEmailOtp(
      email: _email,
      otpCode: _otpCode,
      otpId: _otpId!,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => _showError(failure.message),
      (data) {
        _stopTimer();
        setState(() {
          _recoveryToken = data['recovery_token'];
          _currentStep = RecoveryStep.mobileInput;
          _otpCode = ''; // Reset OTP for next step
          _otpId = null; // Reset OTP ID for next step
        });
        _showMessage('Email verified. Please enter new mobile number.');
      },
    );
  }

  // --- Step 3: Send Mobile OTP ---
  Future<void> _sendMobileOtp() async {
    if (!_isPhoneValid) {
      _showError('Please enter a valid mobile number');
      return;
    }

    if (_recoveryToken == null) {
      _showError('Session expired. Please start over.');
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authRepository.sendUpdateMobileOtp(
      newMobileNumber: _fullMobileNumber,
      recoveryToken: _recoveryToken,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => _showError(failure.message),
      (data) {
        setState(() {
          _newMobileNumber = _fullMobileNumber;
          _otpId = data['otp_id'];
          _currentStep = RecoveryStep.mobileVerification;
          _otpCode = ''; // Reset OTP
        });
        _startTimer();
        _showMessage('Verification code sent to $_fullMobileNumber');
      },
    );
  }

  // --- Step 4: Verify Mobile OTP ---
  Future<void> _verifyMobileOtp() async {
    if (_otpCode.length != 6) {
      _showError('Please enter a valid 6-digit code');
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authRepository.verifyUpdateMobileOtp(
      newMobileNumber: _newMobileNumber,
      otpCode: _otpCode,
      otpId: _otpId!,
      recoveryToken: _recoveryToken,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => _showError(failure.message),
      (data) {
        _stopTimer();
        _showMessage('Mobile number updated successfully!');
        // Navigate back to login or phone entry
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // --- Widgets ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Recovery'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
             Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStepContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResendButton({required VoidCallback onPressed}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _canResend ? "Didn't receive code? " : "Resend code in $_start s",
          style: TextStyle(color: Colors.grey[600]),
        ),
        if (_canResend)
          TextButton(
            onPressed: onPressed,
            child: const Text('Send Again'),
          ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case RecoveryStep.emailInput:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter your registered email address to receive a recovery code.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            UnderlinedTextField(
              controller: _emailController,
              hint: 'Email Address',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Send Recovery Code',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _sendEmailOtp,
            ),
          ],
        );

      case RecoveryStep.emailVerification:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the 6-digit code sent to\n$_email',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OtpInputField(
              onChanged: (code) => setState(() => _otpCode = code),
              onCompleted: (code) {
                  setState(() => _otpCode = code);
              },
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Verify Email',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _verifyEmailOtp,
            ),
            const SizedBox(height: 16),
            _buildResendButton(onPressed: _sendEmailOtp),
          ],
        );

      case RecoveryStep.mobileInput:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Email verified! Now enter your new mobile number.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            PhoneInputWidget(
              onPhoneChanged: (phone) => setState(() => _fullMobileNumber = phone),
              onValidationChanged: (isValid) => setState(() => _isPhoneValid = isValid),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Send OTP to Mobile',
              isLoading: _isLoading,
              onPressed: (_isPhoneValid && !_isLoading) ? _sendMobileOtp : null,
              isDisabled: !_isPhoneValid,
            ),
          ],
        );

      case RecoveryStep.mobileVerification:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the 6-digit code sent to\n$_fullMobileNumber',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OtpInputField(
              onChanged: (code) => setState(() => _otpCode = code),
              onCompleted: (code) {
                  setState(() => _otpCode = code);
              },
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Verify & Update Number',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _verifyMobileOtp,
            ),
            const SizedBox(height: 16),
            _buildResendButton(onPressed: _sendMobileOtp),
          ],
        );
    }
  }
}
