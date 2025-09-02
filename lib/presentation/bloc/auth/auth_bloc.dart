import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/auth/usecases/send_otp.dart';
import '../../../domain/auth/usecases/verify_otp.dart';
import '../../../domain/auth/usecases/resend_otp.dart' as resend;
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendOtp sendOtpUseCase;
  final VerifyOtp verifyOtpUseCase;
  final resend.ResendOtp resendOtpUseCase;

  AuthBloc({
    required this.sendOtpUseCase,
    required this.verifyOtpUseCase,
    required this.resendOtpUseCase,
  }) : super(const AuthInitial()) {
    on<SendOtpRequested>(_onSendOtpRequested);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
    on<ResendOtpRequested>(_onResendOtpRequested);
  }
  Future<void> _onResendOtpRequested(
    ResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const SendingOtp());
    final result = await resendOtpUseCase.call(
      resend.ResendOtpParams(phone: event.phone, otpId: event.otpId),
    );
    result.fold(
      (failure) => emit(ErrorWhileSendingOtp(message: failure.message)),
      (data) {
        final otpId = data['otp_id'] as String?;
        emit(OtpResent(
          email: null,
          phone: event.phone,
          otpId: otpId,
        ));
      },
    );
  }

  Future<void> _onSendOtpRequested(
    SendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const SendingOtp());
    final result = await sendOtpUseCase.call(SendOtpParams(
      phone: event.phone,
      email: event.email,
      otpId: event.otpId,
    ));
    result.fold(
      (failure) => emit(ErrorWhileSendingOtp(message: failure.message)),
      (data) {
        final otpId = data['otp_id'] as String?;
        emit(OtpSent(
          email: event.email,
          phone: event.phone,
          otpId: otpId,
        ));
      },
    );
  }

  Future<void> _onVerifyOtpRequested(
    VerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const VerifyingOtp());
    final phone = event.phone ?? '';
    final otp = event.otp;
    final otpId = event.otpId;
    final result = await verifyOtpUseCase.call(VerifyOtpParams(
      phone: phone,
      otp: otp,
      otpId: otpId,
    ));
    result.fold(
      (failure) => emit(ErrorWhileOtpVerification(message: failure.message)),
      (authResponse) {
         emit(OtpVerified(authResponse: authResponse));
         }
    );

  }
}
