import 'package:equatable/equatable.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../repositories/auth_repository.dart';

class SendOtp extends UseCase<void, SendOtpParams> {
  final AuthRepository repository;

  SendOtp(this.repository);

  @override
  Future<Result<void>> call(SendOtpParams params) async {
    return await repository.sendOtp(
      phone: params.phone,
      email: params.email,
    );
  }
}

class SendOtpParams extends Equatable {
  final String? phone;
  final String? email;

  const SendOtpParams({this.phone, this.email});

  @override
  List<Object?> get props => [phone, email];
}
