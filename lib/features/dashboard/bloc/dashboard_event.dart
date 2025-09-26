abstract class DashboardEvent {}

class DashboardRequested extends DashboardEvent {
  final String token;
  DashboardRequested(this.token);
}

class FetchTodaysRoutine extends DashboardEvent {
  final String token;
  final String type;
  FetchTodaysRoutine(this.token, this.type);
}

class FetchMyProducts extends DashboardEvent {
  final String token;
  FetchMyProducts(this.token);
}

class FetchProductInfo extends DashboardEvent {
  final String token;
  final String productId;
  FetchProductInfo(this.token, this.productId);
}