abstract class OnboardingState {}

class OnboardingInitial extends OnboardingState {}

class OnboardingLoading extends OnboardingState {}

class OnboardingFailure extends OnboardingState {
  final String error;
  OnboardingFailure(this.error);
}

// USER INFO
class UserInfoFetchSuccess extends OnboardingState {
  final dynamic data;
  UserInfoFetchSuccess(this.data);
}
class UserInfoSubmitSuccess extends OnboardingState {
  final dynamic response;
  UserInfoSubmitSuccess(this.response);
}

// USER DETAIL
class UserDetailFetchSuccess extends OnboardingState {
  final dynamic data;
  UserDetailFetchSuccess(this.data);
}
class UserDetailSubmitSuccess extends OnboardingState {
  final dynamic response;
  UserDetailSubmitSuccess(this.response);
}

// LIFESTYLE
class LifestyleFetchSuccess extends OnboardingState {
  final dynamic data;
  LifestyleFetchSuccess(this.data);
}
class LifestyleSubmitSuccess extends OnboardingState {
  final dynamic response;
  LifestyleSubmitSuccess(this.response);
}

// SKIN TYPE
class SkinTypeFetchSuccess extends OnboardingState {
  final dynamic data;
  SkinTypeFetchSuccess(this.data);
}
class SkinTypeSubmitSuccess extends OnboardingState {
  final dynamic response;
  SkinTypeSubmitSuccess(this.response);
}

// CYCLE DETAIL
class CycleDetailFetchSuccess extends OnboardingState {
  final dynamic data;
  CycleDetailFetchSuccess(this.data);
}
class CycleDetailSubmitSuccess extends OnboardingState {
  final dynamic response;
  CycleDetailSubmitSuccess(this.response);
}

// CYCLE INFO
class CycleInfoFetchSuccess extends OnboardingState {
  final dynamic data;
  CycleInfoFetchSuccess(this.data);
}
class CycleInfoSubmitSuccess extends OnboardingState {
  final dynamic response;
  CycleInfoSubmitSuccess(this.response);
}

// MENOPAUSE STATUS
class MenopauseStatusFetchSuccess extends OnboardingState {
  final dynamic data;
  MenopauseStatusFetchSuccess(this.data);
}
class MenopauseStatusSubmitSuccess extends OnboardingState {
  final dynamic response;
  MenopauseStatusSubmitSuccess(this.response);
}

// SKIN GOAL
class SkinGoalFetchSuccess extends OnboardingState {
  final dynamic data;
  SkinGoalFetchSuccess(this.data);
}
class SkinGoalSubmitSuccess extends OnboardingState {
  final dynamic response;
  SkinGoalSubmitSuccess(this.response);
}
