
import 'package:nepika/core/api_base.dart';
import 'package:nepika/domain/dashboard/repositories/dashboard_repository.dart';
import 'package:nepika/domain/dashboard/entities/dashboard_entities.dart';
import '../../../core/config/constants/api_endpoints.dart';



class DashboardRepositoryImpl implements DashboardRepository {
  final ApiBase apiBase;
  DashboardRepositoryImpl(this.apiBase);

  @override
  Future<DashboardDataEntity> fetchDashboardData({required String token}) async {
    final response = await apiBase.request(
      path: ApiEndpoints.dashboard,
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && response.data['success'] == true) {
      return DashboardDataEntity(data: Map<String, dynamic>.from(response.data['data']));
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch dashboard data');
    }
  }

  @override
  Future<RoutineEntity> fetchTodaysRoutine({required String token, required String type}) async {
    final response = await apiBase.request(
      path: ApiEndpoints.userDailyRoutine,
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
      query: {'type': type},
    );
    if (response.statusCode == 200 && response.data['success'] == true) {
      return RoutineEntity(routines: List<dynamic>.from(response.data['data']));
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch today\'s routine');
    }
  }

  @override
  Future<ProductEntity> fetchMyProducts({required String token}) async {
    final response = await apiBase.request(
      path: ApiEndpoints.userMyProducts,
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && response.data['success'] == true) {
      return ProductEntity(products: List<Map<String, dynamic>>.from(response.data['data']));
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch products');
    }
  }

  @override
  Future<ProductInfoEntity> fetchProductInfo({required String token, required String productId}) async {
    if (productId.isEmpty) {
      throw Exception('Product ID cannot be empty');
    }
    final response = await apiBase.request(
      path: '${ApiEndpoints.userMyProducts}/$productId',
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200 && response.data['success'] == true) {
      return ProductInfoEntity(info: Map<String, dynamic>.from(response.data['data']));
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch products');
    }
  }
}