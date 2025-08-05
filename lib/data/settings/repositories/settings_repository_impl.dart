import '../../../core/utils/either.dart';
import '../../../core/error/failures.dart';
import '../../../domain/settings/entities/settings.dart';
import '../../../domain/settings/repositories/settings_repository.dart';
import '../datasources/settings_remote_data_source.dart';
import '../models/settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource remoteDataSource;

  SettingsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<Settings>>> getUserSettings({required String token}) async {
    try {
      final settingsModels = await remoteDataSource.getUserSettings(token: token);
      final settings = settingsModels.map((model) => _mapToSettingsEntity(model)).toList();
      return success(settings);
    } catch (e) {
      return failure(ServerFailure(message: 'Failed to get user settings: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> updateSetting({required String token, required String settingId, required bool isEnabled}) async {
    try {
      await remoteDataSource.updateSetting(token: token, settingId: settingId, isEnabled: isEnabled);
      return success(null);
    } catch (e) {
      return failure(ServerFailure(message: 'Failed to update setting: ${e.toString()}'));
    }
  }

  @override
  Future<Result<UserProfile>> getUserProfile({required String token}) async {
    try {
      final profileModel = await remoteDataSource.getUserProfile(token: token);
      final profile = _mapToUserProfileEntity(profileModel);
      return success(profile);
    } catch (e) {
      return failure(ServerFailure(message: 'Failed to get user profile: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> updateUserProfile({required String token, required UserProfile profile}) async {
    try {
      final profileModel = _mapToUserProfileModel(profile);
      await remoteDataSource.updateUserProfile(token: token, profile: profileModel);
      return success(null);
    } catch (e) {
      return failure(ServerFailure(message: 'Failed to update user profile: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> deleteAccount({required String token}) async {
    try {
      await remoteDataSource.deleteAccount(token: token);
      return success(null);
    } catch (e) {
      return failure(ServerFailure(message: 'Failed to delete account: ${e.toString()}'));
    }
  }

  Settings _mapToSettingsEntity(SettingsModel model) {
    return Settings(
      id: model.id,
      name: model.name,
      isEnabled: model.isEnabled,
      description: model.description,
      type: _mapToSettingsType(model.type),
    );
  }

  SettingsType _mapToSettingsType(String type) {
    switch (type.toLowerCase()) {
      case 'notification':
        return SettingsType.notification;
      case 'privacy':
        return SettingsType.privacy;
      case 'account':
        return SettingsType.account;
      default:
        return SettingsType.general;
    }
  }

  UserProfile _mapToUserProfileEntity(UserProfileModel model) {
    return UserProfile(
      id: model.id,
      name: model.name,
      email: model.email,
      profileImageUrl: model.profileImageUrl,
      createdAt: DateTime.tryParse(model.createdAt) ?? DateTime.now(),
    );
  }

  UserProfileModel _mapToUserProfileModel(UserProfile entity) {
    return UserProfileModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      profileImageUrl: entity.profileImageUrl,
      createdAt: entity.createdAt.toIso8601String(),
    );
  }
}
