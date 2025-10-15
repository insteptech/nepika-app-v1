import '../entities/fcm_token_entity.dart';

abstract class FcmTokenRepository {
  /// Save FCM token to backend
  Future<FcmTokenEntity> saveFcmToken({
    required String fcmToken,
    String? fcmRefreshToken,
  });

  /// Get current FCM token from device
  Future<String?> getCurrentFcmToken();

  /// Check if FCM token has changed
  Future<bool> hasTokenChanged(String newToken);

  /// Get stored FCM token from local storage
  Future<String?> getStoredFcmToken();

  /// Store FCM token in local storage
  Future<void> storeTokenLocally(String token);

  /// Clear stored FCM token
  Future<void> clearStoredToken();
}