import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/utils/secure_storage.dart';
import '../../../data/auth/repositories/auth_repository.dart';
import '../../../domain/auth/entities/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;


  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<SendOtpRequested>(_onSendOtpRequested);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
  }

  Future<void> _onSendOtpRequested(
    SendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const SendingOtp());
    try {
      await authRepository.sendOtp(phone: event.phone, email: event.email);
      emit(OtpSent(phone: event.phone));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onVerifyOtpRequested(
    VerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const VerifyingOtp());
    try {
      final phone = event.phone ?? '';
      final otp = event.otp;
      final result = await authRepository.verifyOtp(phone, otp);
      if (result['success'] == true || result['sucsess'] == true) {
        emit(
          OtpVerified(
            user: User(
              id: result['userId'] ?? '',
              email: result['email'] ?? '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        );
      }
      await SecureStorage().saveAccessToken(result['accessToken'] ?? '');

      // final data = await SecureStorage().getAccessToken();
      // print('OTP verification successful: ${result['message']}');
      // print('Access Token: $data');
    } catch (e) {
      print('Error verifying OTP: $e');
      print(e.toString());
      emit(OtpError(message: e.toString()));
    }
  }
}
