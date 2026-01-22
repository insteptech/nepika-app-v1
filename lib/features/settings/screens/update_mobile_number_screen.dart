import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/widgets/custom_button.dart';
import 'package:nepika/core/widgets/otp_input_field.dart';
import 'package:nepika/domain/auth/repositories/auth_repository.dart';
import 'package:nepika/features/auth/widgets/phone_input_widget.dart';
import 'package:nepika/core/di/injection_container.dart' as di;

class UpdateMobileNumberScreen extends StatefulWidget {
  const UpdateMobileNumberScreen({super.key});

  @override
  State<UpdateMobileNumberScreen> createState() => _UpdateMobileNumberScreenState();
}

class _UpdateMobileNumberScreenState extends State<UpdateMobileNumberScreen> {
  final _authRepository = di.ServiceLocator.get<AuthRepository>();

  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _otpId;
  String _otp = '';
  String? _newMobileNumber;
  
  // Phone input state
  String _fullPhoneNumber = '';
  bool _isPhoneValid = false;

  Future<void> _sendOtp() async {
    if (!_isPhoneValid || _fullPhoneNumber.isEmpty) {
      _showError('Please enter a valid mobile number');
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authRepository.sendUpdateMobileOtp(newMobileNumber: _fullPhoneNumber);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => _showError(failure.message),
      (data) {
        setState(() {
          _isOtpSent = true;
          _otpId = data['otp_id'];
          _newMobileNumber = _fullPhoneNumber;
        });
        _showMessage('OTP sent successfully');
      },
    );
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != 6) {
      _showError('Please enter a valid 6-digit OTP');
      return;
    }
    if (_otpId == null || _newMobileNumber == null) {
      _showError('Session expired. Please request OTP again.');
      setState(() => _isOtpSent = false);
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authRepository.verifyUpdateMobileOtp(
      newMobileNumber: _newMobileNumber!,
      otpCode: _otp,
      otpId: _otpId!,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => _showError(failure.message),
      (data) {
        _showMessage('Mobile number updated successfully');
        Navigator.of(context).pop();
      },
    );
  }

  void _showError(String message) {
    debugPrint('🚨 UpdateMobileNumberScreen Error: $message');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Mobile Number'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isOtpSent) ...[
                const Text(
                  'Enter your new mobile number',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                PhoneInputWidget(
                  onPhoneChanged: (phone) {
                    setState(() {
                      _fullPhoneNumber = phone;
                    });
                  },
                  onValidationChanged: (isValid) {
                    setState(() {
                      _isPhoneValid = isValid;
                    });
                  },
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Send OTP',
                  isLoading: _isLoading,
                  onPressed: (_isPhoneValid && !_isLoading) ? _sendOtp : null,
                  isDisabled: !_isPhoneValid,
                ),
              ] else ...[
                Text(
                  'Enter OTP sent to $_newMobileNumber',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                OtpInputField(
                  length: 6,
                  onCompleted: (val) {
                    setState(() => _otp = val);
                  },
                  onChanged: (val) {
                    setState(() => _otp = val);
                  },
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Verify & Update',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _verifyOtp,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isOtpSent = false;
                      _otp = '';
                    });
                  },
                  child: const Text('Change Number'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
