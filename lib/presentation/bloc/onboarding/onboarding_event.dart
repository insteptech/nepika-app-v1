abstract class OnboardingEvent {}

class LoadOnboardingSteps extends OnboardingEvent {
  final String userId;
  final String token;
  LoadOnboardingSteps({required this.userId, required this.token});
}

class FetchQuestions extends OnboardingEvent {
  final String stepSlug;
  FetchQuestions(this.stepSlug);
}

class UpdateAnswer extends OnboardingEvent {
  final String slug;
  final dynamic value;
  UpdateAnswer(this.slug, this.value);
}

class SubmitStepAnswers extends OnboardingEvent {}
class NextStep extends OnboardingEvent {}
class PreviousStep extends OnboardingEvent {}
