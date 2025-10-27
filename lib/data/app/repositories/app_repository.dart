
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/config/env.dart';
import 'package:nepika/core/config/constants/api_endpoints.dart';
import 'package:nepika/core/utils/debug_logger.dart';

abstract class AppRepository {
  final ApiBase apiBase;
  AppRepository(this.apiBase);

  Future<Map<String, dynamic>> fetchSubscriptionPlan({required String token});
  // Add other methods as needed for your app
}

class AppRepositoryImpl extends AppRepository {
  AppRepositoryImpl(ApiBase apiBase) : super(apiBase);

  @override
  Future<Map<String, dynamic>> fetchSubscriptionPlan({required String token}) async {
    final response = await apiBase.request(
      path: '${Env.baseUrl}${ApiEndpoints.paymentPlans}',
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && response.data['success'] == true) {
      logJson(response.data['data']);
      return Map<String, dynamic>.from(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch dashboard data');
    }
  }
}