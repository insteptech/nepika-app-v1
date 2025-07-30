abstract class AuthRepository {
  Future<void> sendOtp(String phone);
  Future<bool> verifyOtp(String phoneNumber, String otp);
}
