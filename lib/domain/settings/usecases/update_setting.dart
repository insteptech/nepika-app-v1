import 'package:equatable/equatable.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../repositories/settings_repository.dart';

class UpdateSetting extends UseCase<void, UpdateSettingParams> {
  final SettingsRepository repository;

  UpdateSetting(this.repository);

  @override
  Future<Result<void>> call(UpdateSettingParams params) async {
    return await repository.updateSetting(
      token: params.token,
      settingId: params.settingId,
      isEnabled: params.isEnabled,
    );
  }
}

class UpdateSettingParams extends Equatable {
  final String token;
  final String settingId;
  final bool isEnabled;

  const UpdateSettingParams({
    required this.token,
    required this.settingId,
    required this.isEnabled,
  });

  @override
  List<Object> get props => [token, settingId, isEnabled];
}
