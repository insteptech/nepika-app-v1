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

  /// Verify Email OTP (Inline)
  Future<Map<String, dynamic>> verifyEmailOtp({
    required String email,
    required String otpCode,
    required String otpId,
  });

  /// Send OTP for updating mobile number
  Future<Map<String, dynamic>> sendUpdateMobileOtp({
    required String newMobileNumber,
    String? recoveryToken,
  });

  /// Verify OTP and update mobile number
  Future<Map<String, dynamic>> verifyUpdateMobileOtp({
    required String newMobileNumber,
    required String otpCode,
    required String otpId,
    String? recoveryToken,
  });
  
  /// Send OTP for recovery email verification
  Future<Map<String, dynamic>> recoverSendEmailOtp({
    required String email,
  });

  /// Verify OTP for recovery email verification and get recovery token
  Future<Map<String, dynamic>> recoverVerifyEmailOtp({
    required String email,
    required String otpCode,
    required String otpId,
  });
}
