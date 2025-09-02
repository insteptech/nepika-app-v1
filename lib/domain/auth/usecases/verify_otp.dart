import 'package:equatable/equatable.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class VerifyOtp extends UseCase<AuthResponse, VerifyOtpParams> {
  final AuthRepository repository;

  VerifyOtp(this.repository);

  @override
  Future<Result<AuthResponse>> call(VerifyOtpParams params) async {
    return await repository.verifyOtp(
      phone: params.phone,
      otp: params.otp,
      otpId: params.otpId,
    );
  }
}

class VerifyOtpParams extends Equatable {
  final String? phone;
  final String otp;
  final String otpId;

  const VerifyOtpParams({this.phone, required this.otp, required this.otpId});

  @override
  List<Object?> get props => [phone, otp, otpId];
}
