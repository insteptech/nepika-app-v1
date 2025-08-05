import 'package:equatable/equatable.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../entities/settings.dart';
import '../repositories/settings_repository.dart';

class GetUserSettings extends UseCase<List<Settings>, GetUserSettingsParams> {
  final SettingsRepository repository;

  GetUserSettings(this.repository);

  @override
  Future<Result<List<Settings>>> call(GetUserSettingsParams params) async {
    return await repository.getUserSettings(token: params.token);
  }
}

class GetUserSettingsParams extends Equatable {
  final String token;

  const GetUserSettingsParams({required this.token});

  @override
  List<Object> get props => [token];
}
