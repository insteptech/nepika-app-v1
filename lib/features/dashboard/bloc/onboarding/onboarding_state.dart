import 'package:equatable/equatable.dart';
import '../../../../domain/onboarding/entities/onboarding_entites.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
}

class OnboardingStepLoaded extends OnboardingState {
  final OnboardingScreenDataEntity screenData;
  final Map<String, dynamic> answers;
  final Map<String, String> selectedOptions;
  final List<Map<String, dynamic>> responses;
  final bool isFormValid;
  final int currentStep;

  const OnboardingStepLoaded({
    required this.screenData,
    required this.answers,
    required this.selectedOptions,
    required this.responses,
    required this.isFormValid,
    required this.currentStep,
  });

  @override
  List<Object?> get props => [
        screenData,
        answers,
        selectedOptions,
        responses,
        isFormValid,
        currentStep,
      ];

  OnboardingStepLoaded copyWith({
    OnboardingScreenDataEntity? screenData,
    Map<String, dynamic>? answers,
    Map<String, String>? selectedOptions,
    List<Map<String, dynamic>>? responses,
    bool? isFormValid,
    int? currentStep,
  }) {
    return OnboardingStepLoaded(
      screenData: screenData ?? this.screenData,
      answers: answers ?? this.answers,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      responses: responses ?? this.responses,
      isFormValid: isFormValid ?? this.isFormValid,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

class OnboardingStepSubmitting extends OnboardingState {
  const OnboardingStepSubmitting();
}

class OnboardingStepSubmitted extends OnboardingState {
  final String message;
  final int? nextStep;

  const OnboardingStepSubmitted({
    required this.message,
    this.nextStep,
  });

  @override
  List<Object?> get props => [message, nextStep];
}

class OnboardingCompleted extends OnboardingState {
  const OnboardingCompleted();
}

class OnboardingError extends OnboardingState {
  final String message;
  final String? errorCode;

  const OnboardingError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}