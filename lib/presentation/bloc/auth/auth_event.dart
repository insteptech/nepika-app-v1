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

  const SendOtpRequested({
    required this.phone,
    this.email,
  });

  @override
  List<Object?> get props => [phone, email];
}

// Verify OTP Events
class VerifyOtpRequested extends AuthEvent {
  final String? phone;
  final String otp;
  
  const VerifyOtpRequested({
    this.phone,
    required this.otp,
  });
  
  @override
  List<Object?> get props => [phone, otp];
}
// Clear Auth State
class ClearAuthState extends AuthEvent {
  const ClearAuthState();
}
