import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/auth/usecases/send_otp.dart';
import '../../../domain/auth/usecases/verify_otp.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendOtp sendOtpUseCase;
  final VerifyOtp verifyOtpUseCase;

  AuthBloc({
    required this.sendOtpUseCase,
    required this.verifyOtpUseCase,
  }) : super(const AuthInitial()) {
    on<SendOtpRequested>(_onSendOtpRequested);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
  }

  Future<void> _onSendOtpRequested(
    SendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const SendingOtp());
    final result = await sendOtpUseCase.call(SendOtpParams(
      phone: event.phone,
      email: event.email,
    ));
    result.fold(
      (failure) => emit(ErrorWhileSendingOtp(message: failure.message)),
      (_) => emit(OtpSent(phone: event.phone)),
    );
  }

  Future<void> _onVerifyOtpRequested(
    VerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const VerifyingOtp());
    final phone = event.phone ?? '';
    final otp = event.otp;
    final result = await verifyOtpUseCase.call(VerifyOtpParams(
      phone: phone,
      otp: otp,
    ));
    result.fold(
      (failure) => emit(ErrorWhileOtpVerification(message: failure.message)),
      (authResponse) => emit(OtpVerified(authResponse: authResponse)),
    );
  }
}
