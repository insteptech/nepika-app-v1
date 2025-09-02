import 'package:equatable/equatable.dart';
import 'package:nepika/core/error/failures.dart';
import 'package:nepika/core/utils/either.dart';
import 'package:nepika/domain/auth/repositories/auth_repository.dart';

class ResendOtp {
  final AuthRepository repository;
  ResendOtp(this.repository);

  Future<Either<Failure, dynamic>> call(ResendOtpParams params) async {
    return await repository.resendOtp(
      phone: params.phone,
      otpId: params.otpId,
    );
  }
}

class ResendOtpParams extends Equatable {
  final String phone;
  final String otpId;

  const ResendOtpParams({required this.phone, required this.otpId});

  @override
  List<Object?> get props => [phone, otpId];
}
