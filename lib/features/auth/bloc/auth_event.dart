import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

// Send OTP Events
class SendOtpRequested extends AuthEvent {
  final String phone;
  final String? email;
  final String otpId;
  final String? appSignature;

  const SendOtpRequested({
    required this.phone,
    this.email,
    required this.otpId,
    this.appSignature,
  });

  @override
  List<Object?> get props => [phone, email, otpId, appSignature];
}

// Verify OTP Events
class VerifyOtpRequested extends AuthEvent {
  final String? phone;
  final String otp;
  final String otpId;
  
  const VerifyOtpRequested({
    this.phone,
    required this.otp,
    required this.otpId,
  });
  
  @override
  List<Object?> get props => [phone, otp, otpId];
}

// Resend OTP Event
class ResendOtpRequested extends AuthEvent {
  final String phone;
  final String otpId;
  final String? appSignature;

  const ResendOtpRequested({
    required this.phone, 
    required this.otpId,
    this.appSignature,
  });

  @override
  List<Object?> get props => [phone, otpId, appSignature];
}

// Clear Auth State
class ClearAuthState extends AuthEvent {
  const ClearAuthState();
}