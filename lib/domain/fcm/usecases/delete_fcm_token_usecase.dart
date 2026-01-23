import 'package:nepika/core/utils/app_logger.dart';
import '../repositories/fcm_token_repository.dart';

/// Use case to delete FCM token from backend (for logout)
class DeleteFcmTokenUseCase {
  final FcmTokenRepository _repository;

  DeleteFcmTokenUseCase(this._repository);

  Future<void> call({required String fcmToken}) async {
    try {
      if (fcmToken.isEmpty) {
        AppLogger.warning('Cannot delete empty FCM token', tag: 'DELETE_FCM_UC');
        return;
      }
      
      await _repository.deleteFcmToken(fcmToken);
    } catch (e) {
      AppLogger.error('Failed to execute DeleteFcmTokenUseCase', tag: 'DELETE_FCM_UC', error: e);
      // We don't rethrow as this is a cleanup operation
    }
  }
}
