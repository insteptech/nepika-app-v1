import '../../../domain/skin_condition/entities/skin_condition_entities.dart';
import '../../../domain/skin_condition/repositories/skin_condition_repository.dart';
import '../datasources/skin_condition_remote_datasource.dart';

class SkinConditionRepositoryImpl implements SkinConditionRepository {
  final SkinConditionRemoteDataSource remoteDataSource;

  SkinConditionRepositoryImpl(this.remoteDataSource);

  @override
  Future<SkinConditionEntity> getSkinConditionDetails({
    required String token,
    required String conditionSlug,
  }) async {
    try {
      final response = await remoteDataSource.getSkinConditionDetails(
        token: token,
        conditionSlug: conditionSlug,
      );

      return SkinConditionEntity(
        conditionSlug: response.data.conditionSlug,
        formattedConditionName: response.data.formattedConditionName,
        currentPercentage: response.data.currentPercentage,
        skinScore: response.data.skinScore,
        lastUpdated: response.data.lastUpdated,
        progressSummary: response.data.progressSummary.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to get skin condition details: $e');
    }
  }
}