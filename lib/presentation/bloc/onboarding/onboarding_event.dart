abstract class OnboardingEvent {}

/// USER INFO
class FetchUserInfoRequested extends OnboardingEvent {
  final String token;
  FetchUserInfoRequested(this.token);
}
class SubmitUserInfoRequested extends OnboardingEvent {
  final String token;
  final Map<String, dynamic> payload;
  SubmitUserInfoRequested(this.token, this.payload);
}

/// USER DETAIL
class FetchUserDetailRequested extends OnboardingEvent {
  final String token;
  final String type;
  FetchUserDetailRequested(this.token, this.type);
}
class SubmitUserDetailRequested extends OnboardingEvent {
  final String token;
  final String type;
  final Map<String, dynamic> payload;
  SubmitUserDetailRequested(this.token, this.type, this.payload);
}

/// LIFESTYLE
class FetchLifestyleRequested extends OnboardingEvent {
  final String token;
  FetchLifestyleRequested(this.token);
}
class SubmitLifestyleRequested extends OnboardingEvent {
  final String token;
  final Map<String, dynamic> payload;
  SubmitLifestyleRequested(this.token, this.payload);
}

/// SKIN TYPE
class FetchSkinTypeRequested extends OnboardingEvent {
  final String token;
  final String productId;
  FetchSkinTypeRequested(this.token, this.productId);
}
class SubmitSkinTypeRequested extends OnboardingEvent {
  final String token;
  final String productId;
  final Map<String, dynamic> payload;
  SubmitSkinTypeRequested(this.token, this.productId, this.payload);
}

/// CYCLE DETAIL
class FetchCycleDetailRequested extends OnboardingEvent {
  final String token;
  FetchCycleDetailRequested(this.token);
}
class SubmitCycleDetailRequested extends OnboardingEvent {
  final String token;
  final Map<String, dynamic> payload;
  SubmitCycleDetailRequested(this.token, this.payload);
}

/// CYCLE INFO
class FetchCycleInfoRequested extends OnboardingEvent {
  final String token;
  final String productId;
  FetchCycleInfoRequested(this.token, this.productId);
}
class SubmitCycleInfoRequested extends OnboardingEvent {
  final String token;
  final String productId;
  final Map<String, dynamic> payload;
  SubmitCycleInfoRequested(this.token, this.productId, this.payload);
}

/// MENOPAUSE STATUS
class FetchMenopauseStatusRequested extends OnboardingEvent {
  final String token;
  FetchMenopauseStatusRequested(this.token);
}
class SubmitMenopauseStatusRequested extends OnboardingEvent {
  final String token;
  final Map<String, dynamic> payload;
  SubmitMenopauseStatusRequested(this.token, this.payload);
}

/// SKIN GOAL
class FetchSkinGoalRequested extends OnboardingEvent {
  final String token;
  final String productId;
  FetchSkinGoalRequested(this.token, this.productId);
}
class SubmitSkinGoalRequested extends OnboardingEvent {
  final String token;
  final String productId;
  final Map<String, dynamic> payload;
  SubmitSkinGoalRequested(this.token, this.productId, this.payload);
}
