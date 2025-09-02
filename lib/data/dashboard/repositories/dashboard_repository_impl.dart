import 'package:nepika/core/api_base.dart';
import '../../../core/config/constants/api_endpoints.dart';
import '../../../domain/dashboard/entities/dashboard_entities.dart';
import '../../../domain/dashboard/repositories/dashboard_repository.dart';

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
      if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch dashboard data');
      }
    }
  }

  @override
  Future<RoutineEntity> fetchTodaysRoutine({required String token, required String type}) async {
    final path = '${ApiEndpoints.userDailyRoutine}/all';
    print('\n\n\n\n\n');
    print(path);
    print('\n\n\n\n\n');
    final response = await apiBase.request(
      path: path,
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
      // query: {'type': type},
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
      throw Exception(response.data['message'] ?? 'Failed to fetch product info');
    }
  }
}
