import 'package:equatable/equatable.dart';
import 'package:nepika/domain/auth/entities/user.dart';
// import '../../../domain/auth/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

// Initial State
class AuthInitial extends AuthState {
  const AuthInitial();
}





// # ==========================. Send Otp States. ==========================. 
class SendingOtp extends AuthState {
  const SendingOtp();
}

class OtpSent extends AuthState {
  final String? email;
  final String phone;
  
  const OtpSent({
    this.email,
    required this.phone,
  });
  
  @override
  List<Object?> get props => [email, phone];
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





// # ==========================. Verify Otp States. ==========================.
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
