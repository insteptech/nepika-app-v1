import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/auth/usecases/send_otp.dart';
import '../../../domain/auth/usecases/verify_otp.dart';
import '../../../domain/auth/usecases/resend_otp.dart' as resend;
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SendOtp _sendOtpUseCase;
  final VerifyOtp _verifyOtpUseCase;
  final resend.ResendOtp _resendOtpUseCase;

  AuthBloc({
    required SendOtp sendOtpUseCase,
    required VerifyOtp verifyOtpUseCase,
    required resend.ResendOtp resendOtpUseCase,
  })  : _sendOtpUseCase = sendOtpUseCase,
        _verifyOtpUseCase = verifyOtpUseCase,
        _resendOtpUseCase = resendOtpUseCase,
        super(const AuthInitial()) {
    on<SendOtpRequested>(_onSendOtpRequested);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
    on<ResendOtpRequested>(_onResendOtpRequested);
    on<ClearAuthState>(_onClearAuthState);
  }

  Future<void> _onSendOtpRequested(
    SendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const SendingOtp());
    
    final result = await _sendOtpUseCase.call(SendOtpParams(
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
    debugPrint('AuthBloc: Starting OTP verification');
    emit(const VerifyingOtp());
    
    final phone = event.phone ?? '';
    final otp = event.otp;
    final otpId = event.otpId;
    
    debugPrint('AuthBloc: Calling verifyOtpUseCase with phone: $phone, otp: $otp, otpId: $otpId');
    
    final result = await _verifyOtpUseCase.call(VerifyOtpParams(
      phone: phone,
      otp: otp,
      otpId: otpId,
    ));
    
    result.fold(
      (failure) {
        debugPrint('AuthBloc: OTP verification failed: ${failure.message}');
        emit(ErrorWhileOtpVerification(message: failure.message));
      },
      (authResponse) {
        debugPrint('AuthBloc: OTP verification successful, emitting OtpVerified');
        debugPrint('AuthBloc: AuthResponse user activeStep: ${authResponse.user.activeStep}');
        emit(OtpVerified(authResponse: authResponse));
      },
    );
  }

  Future<void> _onResendOtpRequested(
    ResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const SendingOtp());
    
    final result = await _resendOtpUseCase.call(
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

  void _onClearAuthState(
    ClearAuthState event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthInitial());
  }
}