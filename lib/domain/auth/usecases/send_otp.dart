import 'package:equatable/equatable.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../repositories/auth_repository.dart';

class SendOtp extends UseCase<Map<String, dynamic>, SendOtpParams> {
  final AuthRepository repository;

  SendOtp(this.repository);

  @override
  Future<Result<Map<String, dynamic>>> call(SendOtpParams params) async {
    return await repository.sendOtp(
      phone: params.phone,
      email: params.email,
      otpId: params.otpId,
      appSignature: params.appSignature,
    );
  }
}

class SendOtpParams extends Equatable {
  final String? phone;
  final String? email;
  final String? otpId;
  final String? appSignature;

  const SendOtpParams({this.phone, this.email, this.otpId, this.appSignature});

  @override
  List<Object?> get props => [phone, email, otpId, appSignature];
}

class ResendOtp extends UseCase<Map<String, dynamic>, ResendOtpParams> {
  final AuthRepository repository;
  ResendOtp(this.repository);
  @override
  Future<Result<Map<String, dynamic>>> call(ResendOtpParams params) async {
    return await repository.resendOtp(phone: params.phone, otpId: params.otpId);
  }
}

class ResendOtpParams extends Equatable {
  final String phone;
  final String otpId;
  const ResendOtpParams({required this.phone, required this.otpId});
  @override
  List<Object?> get props => [phone, otpId];
}
