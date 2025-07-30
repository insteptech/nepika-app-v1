abstract class AuthRemoteDataSource {
  /// Send OTP to email or phone
  Future<void> sendOtp({
    String? email,
    String? phone,
  });
  
  /// Verify OTP and get auth token
  Future<Map<String, dynamic>> verifyOtp({
    String? email,
    String? phone,
    required String otp,
  });
}
