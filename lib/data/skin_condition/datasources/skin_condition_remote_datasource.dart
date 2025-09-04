import '../../../core/api_base.dart';
import '../../../core/config/constants/api_endpoints.dart';
import '../../../core/utils/logger.dart';
import '../models/skin_condition_models.dart';

abstract class SkinConditionRemoteDataSource {
  Future<SkinConditionResponse> getSkinConditionDetails({
    required String token,
    required String conditionSlug,
  });
}

class SkinConditionRemoteDataSourceImpl implements SkinConditionRemoteDataSource {
  final ApiBase apiBase;

  SkinConditionRemoteDataSourceImpl(this.apiBase);

  @override
  Future<SkinConditionResponse> getSkinConditionDetails({
    required String token,
    required String conditionSlug,
  }) async {
    try {
      Logger.network('Fetching skin condition details for: $conditionSlug');
      
      final response = await apiBase.request(
        path: '${ApiEndpoints.fetchSkinConditionDetails}/$conditionSlug',
        method: 'GET',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      Logger.network('Skin condition details response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return SkinConditionResponse.fromJson(response.data);
      } else {
        Logger.network('Failed to fetch skin condition details: ${response.statusCode}');
        throw Exception('Failed to fetch skin condition details: ${response.statusCode}');
      }
    } catch (e) {
      Logger.network('Error fetching skin condition details', error: e);
      rethrow;
    }
  }
}