import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/domain/onboarding/entities/onboarding_entites.dart';
import 'package:nepika/domain/onboarding/repositories/onboarding_repositories.dart';

abstract class OnboardingEvent {}
class FetchOnboardingQuestions extends OnboardingEvent {
  final String userId;
  final String screenSlug;
  final String token;
  FetchOnboardingQuestions({required this.userId, required this.screenSlug, required this.token});
}
class SubmitOnboardingAnswers extends OnboardingEvent {
  final String userId;
  final String screenSlug;
  final String token;
  final Map<String, dynamic> answers;
  SubmitOnboardingAnswers({
    required this.userId,
    required this.screenSlug,
    required this.token,
    required this.answers,
  });
}

abstract class OnboardingState {}
class OnboardingInitial extends OnboardingState {}
class OnboardingLoading extends OnboardingState {}
class OnboardingSuccess extends OnboardingState {
  final OnboardingScreenDataEntity data;
  OnboardingSuccess(this.data);
}
class OnboardingAnswersSubmitted extends OnboardingState {}
class OnboardingError extends OnboardingState {
  final String message;
  OnboardingError(this.message);
}

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final OnboardingRepository repository;

  OnboardingBloc(this.repository) : super(OnboardingInitial()) {
    on<FetchOnboardingQuestions>((event, emit) async {
      emit(OnboardingLoading());
      try {
        final data = await repository.fetchQuestions(
          userId: event.userId,
          screenSlug: event.screenSlug,
          token: event.token,
        );
        emit(OnboardingSuccess(data));
      } catch (e) {
        emit(OnboardingError(e.toString()));
      }
    });

    on<SubmitOnboardingAnswers>((event, emit) async {
      emit(OnboardingLoading());
      try {
        await repository.submitAnswers(
          userId: event.userId,
          screenSlug: event.screenSlug,
          token: event.token,
          answers: event.answers,
        );
        emit(OnboardingAnswersSubmitted());
      } catch (e) {
        emit(OnboardingError(e.toString()));
      }
    });
  }
}