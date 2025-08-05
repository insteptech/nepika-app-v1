import '../entities/dashboard_entities.dart';

abstract class DashboardRepository {
  Future<DashboardDataEntity> fetchDashboardData({required String token});
  Future<RoutineEntity> fetchTodaysRoutine({required String token, required String type});
  Future<ProductEntity> fetchMyProducts({required String token});
  Future<ProductInfoEntity> fetchProductInfo({required String token, required String productId});
}