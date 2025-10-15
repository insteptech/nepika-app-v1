import '../entities/fcm_token_entity.dart';
import '../repositories/fcm_token_repository.dart';

class SaveFcmTokenUseCase {
  final FcmTokenRepository repository;

  SaveFcmTokenUseCase(this.repository);

  /// Main method to handle FCM token saving logic
  Future<FcmTokenEntity> call() async {
    try {
      // 1. Get current FCM token from device
      final currentToken = await repository.getCurrentFcmToken();
      
      if (currentToken == null || currentToken.isEmpty) {
        throw Exception('Unable to get FCM token from device');
      }

      // 2. Check if token has changed since last save
      final hasChanged = await repository.hasTokenChanged(currentToken);
      
      if (!hasChanged) {
        // Token hasn't changed, return existing entity
        final storedToken = await repository.getStoredFcmToken();
        return FcmTokenEntity(
          fcmToken: storedToken ?? currentToken,
          lastUpdated: DateTime.now(),
          isActive: true,
        );
      }

      // 3. Save new/changed token to backend
      final result = await repository.saveFcmToken(
        fcmToken: currentToken,
        fcmRefreshToken: null, // Can be enhanced later if needed
      );

      return result;

    } catch (e) {
      throw Exception('Failed to save FCM token: $e');
    }
  }

  /// Force save FCM token (useful for manual triggers)
  Future<FcmTokenEntity> forceSave() async {
    try {
      final currentToken = await repository.getCurrentFcmToken();
      
      if (currentToken == null || currentToken.isEmpty) {
        throw Exception('Unable to get FCM token from device');
      }

      final result = await repository.saveFcmToken(
        fcmToken: currentToken,
        fcmRefreshToken: null,
      );

      return result;

    } catch (e) {
      throw Exception('Failed to force save FCM token: $e');
    }
  }

  /// Clear stored FCM token (useful for logout)
  Future<void> clearToken() async {
    try {
      await repository.clearStoredToken();
    } catch (e) {
      throw Exception('Failed to clear FCM token: $e');
    }
  }

  /// Check if FCM token needs to be updated
  Future<bool> needsUpdate() async {
    try {
      final currentToken = await repository.getCurrentFcmToken();
      if (currentToken == null || currentToken.isEmpty) {
        return false;
      }
      
      return await repository.hasTokenChanged(currentToken);
    } catch (e) {
      return false; // Assume no update needed if we can't determine
    }
  }
}