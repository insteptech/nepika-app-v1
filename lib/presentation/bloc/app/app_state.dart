abstract class AppState {}


class AppInitial extends AppState {}

class AppSubscriptionLoading extends AppState {}
class AppSubscriptionLoaded extends AppState {
  final Map<String, dynamic> subscriptionPlan;
  AppSubscriptionLoaded(this.subscriptionPlan);
}
class AppSubscriptionError extends AppState {
  final String message;
  AppSubscriptionError(this.message);
}