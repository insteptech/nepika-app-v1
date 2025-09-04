abstract class SkinConditionEvent {}

class SkinConditionDetailsRequested extends SkinConditionEvent {
  final String token;
  final String conditionSlug;

  SkinConditionDetailsRequested({
    required this.token,
    required this.conditionSlug,
  });
}