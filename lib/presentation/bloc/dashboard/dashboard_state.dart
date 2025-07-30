abstract class DashboardState {}

class DashboardLoading extends DashboardState {}
class DashboardLoaded extends DashboardState {
  final Map<String, dynamic> dashboardData;
  DashboardLoaded(this.dashboardData);
}
class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}

class TodaysRoutineLoading extends DashboardState {}
class TodaysRoutineLoaded extends DashboardState {
  final List<dynamic> routineSteps;
  TodaysRoutineLoaded(this.routineSteps);
}
class TodaysRoutineError extends DashboardState {
  final String message;
  TodaysRoutineError(this.message);
}

class MyProductsLoading extends DashboardState {}
class MyProductsLoaded extends DashboardState {
  final List<Map<String, dynamic>> myProducts;
  MyProductsLoaded({required this.myProducts});
}
class MyProductsError extends DashboardState {
  final String message;
  MyProductsError(this.message);
}

class ProductInfoLoading extends DashboardState {}
class ProductInfoLoaded extends DashboardState {
  final Map<String, dynamic> productInfo;
  ProductInfoLoaded({required this.productInfo});
}
class ProductInfoError extends DashboardState {
  final String message;
  ProductInfoError(this.message);
} 