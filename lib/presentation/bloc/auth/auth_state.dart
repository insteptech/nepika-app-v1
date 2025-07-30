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

// Loading States
class AuthLoading extends AuthState {
  const AuthLoading();
}

class SendingOtp extends AuthState {
  const SendingOtp();
}

class VerifyingOtp extends AuthState {
  const VerifyingOtp();
}

class LoggingIn extends AuthState {
  const LoggingIn();
}

class Registering extends AuthState {
  const Registering();
}

class UpdatingProfile extends AuthState {
  const UpdatingProfile();
}

class ChangingPassword extends AuthState {
  const ChangingPassword();
}

// Success States
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

class OtpVerified extends AuthState {
  final User user;
  
  const OtpVerified({
    required this.user,
  });
  
  @override
  List<Object> get props => [user];
}

class AuthenticationSuccess extends AuthState {
  final User user;
  
  const AuthenticationSuccess({
    required this.user,
  });
  
  @override
  List<Object> get props => [user];
}

class Authenticated extends AuthState {
  final User user;
  
  const Authenticated({
    required this.user,
  });
  
  @override
  List<Object> get props => [user];
}

class ProfileUpdated extends AuthState {
  final User user;
  
  const ProfileUpdated({
    required this.user,
  });
  
  @override
  List<Object> get props => [user];
}

class PasswordChanged extends AuthState {
  const PasswordChanged();
}

class PasswordResetEmailSent extends AuthState {
  final String email;
  
  const PasswordResetEmailSent({
    required this.email,
  });
  
  @override
  List<Object> get props => [email];
}

class PasswordReset extends AuthState {
  const PasswordReset();
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AccountDeleted extends AuthState {
  const AccountDeleted();
}

// Error States
class AuthError extends AuthState {
  final String message;
  final String? errorCode;
  
  const AuthError({
    required this.message,
    this.errorCode,
  });
  
  @override
  List<Object?> get props => [message, errorCode];
}

class OtpError extends AuthState {
  final String message;
  final String? email;
  final String? phone;
  
  const OtpError({
    required this.message,
    this.email,
    this.phone,
  });
  
  @override
  List<Object?> get props => [message, email, phone];
}

class LoginError extends AuthState {
  final String message;
  
  const LoginError({
    required this.message,
  });
  
  @override
  List<Object> get props => [message];
}

class RegistrationError extends AuthState {
  final String message;
  
  const RegistrationError({
    required this.message,
  });
  
  @override
  List<Object> get props => [message];
}

class ProfileUpdateError extends AuthState {
  final String message;
  final User? currentUser;
  
  const ProfileUpdateError({
    required this.message,
    this.currentUser,
  });
  
  @override
  List<Object?> get props => [message, currentUser];
}

class PasswordChangeError extends AuthState {
  final String message;
  
  const PasswordChangeError({
    required this.message,
  });
  
  @override
  List<Object> get props => [message];
}

class NetworkError extends AuthState {
  final String message;
  
  const NetworkError({
    required this.message,
  });
  
  @override
  List<Object> get props => [message];
}

class ValidationError extends AuthState {
  final String message;
  final Map<String, List<String>>? fieldErrors;
  
  const ValidationError({
    required this.message,
    this.fieldErrors,
  });
  
  @override
  List<Object?> get props => [message, fieldErrors];
}

class UnauthorizedError extends AuthState {
  final String message;
  
  const UnauthorizedError({
    required this.message,
  });
  
  @override
  List<Object> get props => [message];
}
