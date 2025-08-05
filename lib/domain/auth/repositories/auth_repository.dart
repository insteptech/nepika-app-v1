import '../../../core/utils/either.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Result<void>> sendOtp({String? phone, String? email});
  Future<Result<AuthResponse>> verifyOtp({String? phone, required String otp});
}
