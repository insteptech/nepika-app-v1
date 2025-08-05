import 'package:equatable/equatable.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../entities/settings.dart';
import '../repositories/settings_repository.dart';

class GetUserProfile extends UseCase<UserProfile, GetUserProfileParams> {
  final SettingsRepository repository;

  GetUserProfile(this.repository);

  @override
  Future<Result<UserProfile>> call(GetUserProfileParams params) async {
    return await repository.getUserProfile(token: params.token);
  }
}

class GetUserProfileParams extends Equatable {
  final String token;

  const GetUserProfileParams({required this.token});

  @override
  List<Object> get props => [token];
}
