import 'package:equatable/equatable.dart';
import 'package:nepika/features/onboarding/bloc/onboarding_state.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class LoadOnboardingStep extends OnboardingEvent {
  final String userId;
  final String screenSlug;
  final String token;

  const LoadOnboardingStep({
    required this.userId,
    required this.screenSlug,
    required this.token,
  });

  @override
  List<Object?> get props => [userId, screenSlug, token];
}

class UpdateAnswer extends OnboardingEvent {
  final String questionSlug;
  final dynamic value;

  const UpdateAnswer({
    required this.questionSlug,
    required this.value,
  });

  @override
  List<Object?> get props => [questionSlug, value];
}

class ValidateStep extends OnboardingEvent {
  const ValidateStep();
}

class SubmitCurrentStep extends OnboardingEvent {
  final String userId;
  final String screenSlug;
  final String token;

  const SubmitCurrentStep({
    required this.userId,
    required this.screenSlug,
    required this.token,
  });

  @override
  List<Object?> get props => [userId, screenSlug, token];
}

class NavigateToNextStep extends OnboardingEvent {
  const NavigateToNextStep();
}

class NavigateToPreviousStep extends OnboardingEvent {
  const NavigateToPreviousStep();
}

class SkipCurrentStep extends OnboardingEvent {
  const SkipCurrentStep();
}

class SkipAndFetchNextStep extends OnboardingEvent {
  final String userId;
  final String token;
  final int currentStep;

  const SkipAndFetchNextStep({
    required this.userId,
    required this.token,
    required this.currentStep,
  });

  @override
  List<Object?> get props => [userId, token, currentStep];
}

class ResetOnboarding extends OnboardingEvent {
  const ResetOnboarding();
}

class RestoreFormState extends OnboardingEvent {
  final OnboardingStepLoaded state;

  const RestoreFormState({required this.state});

  @override
  List<Object?> get props => [state];
}