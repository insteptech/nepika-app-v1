import '../entities/fcm_token_entity.dart';
import '../repositories/fcm_token_repository.dart';
import '../../../core/utils/app_logger.dart';

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

      AppLogger.info('🔍 FCM_USE_CASE: Current token: ${currentToken.substring(0, 20)}...', tag: 'FCM_USE_CASE');

      // 2. Check if token has changed since last save
      final hasChanged = await repository.hasTokenChanged(currentToken);
      
      AppLogger.info('🔍 FCM_USE_CASE: Token changed: $hasChanged', tag: 'FCM_USE_CASE');
      
      if (!hasChanged) {
        // Token hasn't changed, but let's verify it's actually saved on backend
        AppLogger.warning('⚠️ FCM_USE_CASE: Token unchanged, but forcing save to ensure backend sync', tag: 'FCM_USE_CASE');
        
        // FORCE SAVE: Always save to ensure backend has the token
        final result = await repository.saveFcmToken(
          fcmToken: currentToken,
          fcmRefreshToken: null,
        );
        
        return result;
      }

      // 3. Save new/changed token to backend
      AppLogger.success('✅ FCM_USE_CASE: Saving changed token to backend', tag: 'FCM_USE_CASE');
      final result = await repository.saveFcmToken(
        fcmToken: currentToken,
        fcmRefreshToken: null, // Can be enhanced later if needed
      );

      return result;

    } catch (e) {
      AppLogger.error('❌ FCM_USE_CASE: Error - $e', tag: 'FCM_USE_CASE');
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