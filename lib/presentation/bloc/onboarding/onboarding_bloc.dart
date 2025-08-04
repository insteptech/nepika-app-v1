import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/presentation/bloc/onboarding/dashboard_state.dart';
import 'onboarding_event.dart';
// import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(OnboardingInitial()) {
    // AUTO MAPPED
    on<FetchUserInfoRequested>(_fetch);
    on<SubmitUserInfoRequested>(_submit);

    on<FetchUserDetailRequested>(_fetch);
    on<SubmitUserDetailRequested>(_submit);

    on<FetchLifestyleRequested>(_fetch);
    on<SubmitLifestyleRequested>(_submit);

    on<FetchSkinTypeRequested>(_fetch);
    on<SubmitSkinTypeRequested>(_submit);

    on<FetchCycleDetailRequested>(_fetch);
    on<SubmitCycleDetailRequested>(_submit);

    on<FetchCycleInfoRequested>(_fetch);
    on<SubmitCycleInfoRequested>(_submit);

    on<FetchMenopauseStatusRequested>(_fetch);
    on<SubmitMenopauseStatusRequested>(_submit);

    on<FetchSkinGoalRequested>(_fetch);
    on<SubmitSkinGoalRequested>(_submit);
  }

  Future<void> _fetch(OnboardingEvent event, Emitter<OnboardingState> emit) async {
    emit(OnboardingLoading());
    try {
      await Future.delayed(Duration(milliseconds: 500)); // simulate API
      switch (event.runtimeType) {
        case FetchUserInfoRequested:
          emit(UserInfoFetchSuccess({"prefilled": true}));
          break;
        case FetchUserDetailRequested:
          emit(UserDetailFetchSuccess({"type": (event as FetchUserDetailRequested).type}));
          break;
        case FetchLifestyleRequested:
          emit(LifestyleFetchSuccess({"lifestyle": "active"}));
          break;
        case FetchSkinTypeRequested:
          emit(SkinTypeFetchSuccess({"productId": (event as FetchSkinTypeRequested).productId}));
          break;
        case FetchCycleDetailRequested:
          emit(CycleDetailFetchSuccess({"cycle": "28 days"}));
          break;
        case FetchCycleInfoRequested:
          emit(CycleInfoFetchSuccess({"productId": (event as FetchCycleInfoRequested).productId}));
          break;
        case FetchMenopauseStatusRequested:
          emit(MenopauseStatusFetchSuccess({"status": "pre"}));
          break;
        case FetchSkinGoalRequested:
          emit(SkinGoalFetchSuccess({"productId": (event as FetchSkinGoalRequested).productId}));
          break;
        default:
          throw Exception("Unhandled fetch event");
      }
    } catch (e) {
      emit(OnboardingFailure(e.toString()));
    }
  }

  Future<void> _submit(OnboardingEvent event, Emitter<OnboardingState> emit) async {
    emit(OnboardingLoading());
    try {
      await Future.delayed(Duration(milliseconds: 500)); // simulate API
      switch (event.runtimeType) {
        case SubmitUserInfoRequested:
          emit(UserInfoSubmitSuccess({"saved": true}));
          break;
        case SubmitUserDetailRequested:
          emit(UserDetailSubmitSuccess({"saved": true}));
          break;
        case SubmitLifestyleRequested:
          emit(LifestyleSubmitSuccess({"saved": true}));
          break;
        case SubmitSkinTypeRequested:
          emit(SkinTypeSubmitSuccess({"saved": true}));
          break;
        case SubmitCycleDetailRequested:
          emit(CycleDetailSubmitSuccess({"saved": true}));
          break;
        case SubmitCycleInfoRequested:
          emit(CycleInfoSubmitSuccess({"saved": true}));
          break;
        case SubmitMenopauseStatusRequested:
          emit(MenopauseStatusSubmitSuccess({"saved": true}));
          break;
        case SubmitSkinGoalRequested:
          emit(SkinGoalSubmitSuccess({"saved": true}));
          break;
        default:
          throw Exception("Unhandled submit event");
      }
    } catch (e) {
      emit(OnboardingFailure(e.toString()));
    }
  }
}
