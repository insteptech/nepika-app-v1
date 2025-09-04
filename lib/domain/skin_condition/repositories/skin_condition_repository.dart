import '../entities/skin_condition_entities.dart';

abstract class SkinConditionRepository {
  Future<SkinConditionEntity> getSkinConditionDetails({
    required String token,
    required String conditionSlug,
  });
}