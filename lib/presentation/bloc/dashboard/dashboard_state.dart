
import '../../../domain/dashboard/entities/dashboard_entities.dart';

abstract class DashboardState {}


class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardDataEntity dashboardData;
  DashboardLoaded(this.dashboardData);
}
class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}

class TodaysRoutineLoading extends DashboardState {}
class TodaysRoutineLoaded extends DashboardState {
  final RoutineEntity routineSteps;
  TodaysRoutineLoaded(this.routineSteps);
}
class TodaysRoutineError extends DashboardState {
  final String message;
  TodaysRoutineError(this.message);
}

class MyProductsLoading extends DashboardState {}
class MyProductsLoaded extends DashboardState {
  final ProductEntity myProducts;
  MyProductsLoaded({required this.myProducts});
}
class MyProductsError extends DashboardState {
  final String message;
  MyProductsError(this.message);
}

class ProductInfoLoading extends DashboardState {}
class ProductInfoLoaded extends DashboardState {
  final ProductInfoEntity productInfo;
  ProductInfoLoaded({required this.productInfo});
}
class ProductInfoError extends DashboardState {
  final String message;
  ProductInfoError(this.message);
} 