import 'package:nepika/core/api_base.dart';
import '../../../core/constants/api_endpoints.dart';



class DashboardRepository {
  final ApiBase apiBase;
  DashboardRepository(this.apiBase);

  Future<Map<String, dynamic>> fetchDashboardData({required String token}) async {
    final response = await apiBase.request(
      path: ApiEndpoints.dashboard,
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && response.data['success'] == true) {
      return Map<String, dynamic>.from(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch dashboard data');
    }
  }

  Future<List<dynamic>> fetchTodaysRoutine({required String token, required String type}) async {
    final response = await apiBase.request(
      path: ApiEndpoints.userDailyRoutine,
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
      query: {'type': type},
    );
    if (response.statusCode == 200 && response.data['success'] == true) {
      return List<dynamic>.from(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch today\'s routine');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyProducts({required String token}) async {
    final response = await apiBase.request(
      path: ApiEndpoints.userMyProducts,
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && response.data['success'] == true) {
      return List<Map<String, dynamic>>.from(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch products');
    }
  }

  Future<Map<String, dynamic>> fetchProductInfo({required String token, required String productId}) async {
    if (productId.isEmpty) {
      throw Exception('Product ID cannot be empty');
    }
    final response = await apiBase.request(
      path: '${ApiEndpoints.userMyProducts}/$productId',
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && response.data['success'] == true) {
      return Map<String, dynamic>.from(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch products');
    }
  }
}