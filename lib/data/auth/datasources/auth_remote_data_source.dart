abstract class AuthRemoteDataSource {
  /// Send OTP to email or phone
  Future<Map<String, dynamic>> sendOtp({
    String? email,
    String? phone,
    String? otpId,
    String? appSignature,
  });
  
  /// Resend OTP
  Future<Map<String, dynamic>> resendOtp({
    required String phone,
    required String otpId,
    String? appSignature,
  });

  /// Verify OTP and get auth token
  Future<Map<String, dynamic>> verifyOtp({
    String? email,
    String? phone,
    required String otp,
    required String otpId,
  });
}
