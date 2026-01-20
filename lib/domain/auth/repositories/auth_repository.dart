import '../../../core/utils/either.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Result<Map<String, dynamic>>> sendOtp({String? phone, String? email, String? otpId, String? appSignature});
  Future<Result<Map<String, dynamic>>> resendOtp({required String phone, required String otpId, String? appSignature});
  Future<Result<AuthResponse>> verifyOtp({String? phone, required String otp, required String otpId});
  Future<Result<Map<String, dynamic>>> verifyEmailOtp({required String email, required String otpCode, required String otpId});
  Future<Result<Map<String, dynamic>>> sendUpdateMobileOtp({required String newMobileNumber});
  Future<Result<Map<String, dynamic>>> verifyUpdateMobileOtp({required String newMobileNumber, required String otpCode, required String otpId});
}
