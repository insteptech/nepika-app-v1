import '../../../core/utils/either.dart';
import '../entities/settings.dart';

abstract class SettingsRepository {
  Future<Result<List<Settings>>> getUserSettings({required String token});
  Future<Result<void>> updateSetting({required String token, required String settingId, required bool isEnabled});
  Future<Result<UserProfile>> getUserProfile({required String token});
  Future<Result<void>> updateUserProfile({required String token, required UserProfile profile});
  Future<Result<void>> deleteAccount({required String token});
}
