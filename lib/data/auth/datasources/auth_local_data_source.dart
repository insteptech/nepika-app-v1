import '../models/auth_token_model.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  /// Save auth token to local storage
  Future<void> saveAuthToken(AuthTokenModel token);
  
  /// Get auth token from local storage
  Future<AuthTokenModel?> getAuthToken();
  
  /// Save user data to local storage
  Future<void> saveUser(UserModel user);
  
  /// Get user data from local storage
  Future<UserModel?> getUser();
  
  /// Check if user is authenticated (has valid token)
  Future<bool> isAuthenticated();
  
  /// Clear all auth data from local storage
  Future<void> clearAuthData();
  
  /// Clear user data from local storage
  Future<void> clearUserData();
  
  /// Save onboarding completion status
  Future<void> saveOnboardingStatus(bool completed);
  
  /// Get onboarding completion status
  Future<bool> getOnboardingStatus();

  /// Store tokens securely
  Future<void> storeToken(String token);
  Future<void> storeRefreshToken(String refreshToken);
  Future<String?> getToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
}
