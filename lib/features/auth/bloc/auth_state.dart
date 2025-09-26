import 'package:equatable/equatable.dart';
import '../../../domain/auth/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

// Initial State
class AuthInitial extends AuthState {
  const AuthInitial();
}

// Send OTP States
class SendingOtp extends AuthState {
  const SendingOtp();
}

class OtpSent extends AuthState {
  final String? email;
  final String phone;
  final String? otpId;

  const OtpSent({
    this.email,
    required this.phone,
    this.otpId,
  });
  
  @override
  List<Object?> get props => [email, phone, otpId];
}

class OtpResent extends AuthState {
  final String? email;
  final String phone;
  final String? otpId;

  const OtpResent({
    this.email,
    required this.phone,
    this.otpId,
  });
  
  @override
  List<Object?> get props => [email, phone, otpId];
}

class ErrorWhileSendingOtp extends AuthState {
  final String message;
  final String? email;
  final String? phone;
  
  const ErrorWhileSendingOtp({
    required this.message,
    this.email,
    this.phone,
  });
  
  @override
  List<Object?> get props => [message, email, phone];
}

// Verify OTP States
class VerifyingOtp extends AuthState {
  const VerifyingOtp();
}

class OtpVerified extends AuthState {
  final AuthResponse authResponse;

  const OtpVerified({
    required this.authResponse,
  });
  
  @override
  List<Object> get props => [authResponse];
}

class ErrorWhileOtpVerification extends AuthState {
  final String message;
  final String? email;
  final String? phone;
  
  const ErrorWhileOtpVerification({
    required this.message,
    this.email,
    this.phone,
  });
  
  @override
  List<Object?> get props => [message, email, phone];
}