import '../entities/skin_condition_entities.dart';
import '../repositories/skin_condition_repository.dart';

class GetSkinConditionDetails {
  final SkinConditionRepository repository;

  GetSkinConditionDetails(this.repository);

  Future<SkinConditionEntity> call({
    required String token,
    required String conditionSlug,
  }) async {
    return await repository.getSkinConditionDetails(
      token: token,
      conditionSlug: conditionSlug,
    );
  }
}