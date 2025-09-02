import 'package:nepika/domain/onboarding/entities/onboarding_entites.dart';

class OnboardingState {
  final int currentStepIndex;
  final List<OnboardingStepEntity> steps;
  final List<OnboardingQuestionEntity> questions;
  final Map<String, dynamic> answers;
  final bool isFormValid;
  final bool loading;
  final String? error;

  OnboardingState({
    this.currentStepIndex = 0,
    this.steps = const [],
    this.questions = const [],
    this.answers = const {},
    this.isFormValid = false,
    this.loading = false,
    this.error,
  });

  OnboardingState copyWith({
    int? currentStepIndex,
    List<OnboardingStepEntity>? steps,
    List<OnboardingQuestionEntity>? questions,
    Map<String, dynamic>? answers,
    bool? isFormValid,
    bool? loading,
    String? error,
  }) {
    return OnboardingState(
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      steps: steps ?? this.steps,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      isFormValid: isFormValid ?? this.isFormValid,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}
