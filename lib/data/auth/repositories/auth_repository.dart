// Removed unused import

abstract class AuthRepository {
  Future<void> sendOtp({String? phone, String? email});
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp);
  // Add other methods as needed for your app
}
