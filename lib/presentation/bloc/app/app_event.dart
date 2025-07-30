abstract class AppEvent {}

class AppSubscriptions extends AppEvent {
  final String token;
  AppSubscriptions(this.token);
}