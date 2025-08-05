import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/presentation/bloc/onboarding/onboarding_state.dart';
import 'onboarding_event.dart';
import 'package:nepika/domain/onboarding/repositories/onboarding_repositories.dart';
import 'package:nepika/domain/onboarding/entities/onboarding_entites.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final UserBasicsRepository userBasicsRepository;
  final UserDetailsRepository userDetailsRepository;
  final LifestyleRepository lifestyleRepository;
  final SkinTypeRepository skinTypeRepository;
  final NaturalRhythmRepository naturalRhythmRepository;
  final MenstrualCycleOverviewRepository menstrualCycleOverviewRepository;
  final CycleDetailsRepository cycleDetailsRepository;
  final MenopauseRepository menopauseRepository;
  final SkinGoalsRepository skinGoalsRepository;

  OnboardingBloc({
    required this.userBasicsRepository,
    required this.userDetailsRepository,
    required this.lifestyleRepository,
    required this.skinTypeRepository,
    required this.naturalRhythmRepository,
    required this.menstrualCycleOverviewRepository,
    required this.cycleDetailsRepository,
    required this.menopauseRepository,
    required this.skinGoalsRepository,
  }) : super(OnboardingInitial()) {
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
      if (event is FetchUserInfoRequested) {
        final entity = await userBasicsRepository.fetchUserBasics(event.token);
        emit(UserInfoFetchSuccess(entity));
      } else if (event is FetchUserDetailRequested) {
        final entity = await userDetailsRepository.fetchUserDetails(event.token);
        emit(UserDetailFetchSuccess(entity));
      } else if (event is FetchLifestyleRequested) {
        final entity = await lifestyleRepository.fetchLifestyle(event.token);
        emit(LifestyleFetchSuccess(entity));
      } else if (event is FetchSkinTypeRequested) {
        final entity = await skinTypeRepository.fetchSkinType(event.token, event.productId);
        emit(SkinTypeFetchSuccess(entity));
      } else if (event is FetchCycleDetailRequested) {
        final entity = await cycleDetailsRepository.fetchCycleDetails(event.token);
        emit(CycleDetailFetchSuccess(entity));
      } else if (event is FetchCycleInfoRequested) {
        final entity = await menstrualCycleOverviewRepository.fetchCycleOverview(event.token, event.productId);
        emit(CycleInfoFetchSuccess(entity));
      } else if (event is FetchMenopauseStatusRequested) {
        final entity = await menopauseRepository.fetchMenopauseStatus(event.token);
        emit(MenopauseStatusFetchSuccess(entity));
      } else if (event is FetchSkinGoalRequested) {
        final entity = await skinGoalsRepository.fetchSkinGoals(event.token, event.productId);
        emit(SkinGoalFetchSuccess(entity));
      } else {
        throw Exception("Unhandled fetch event");
      }
    } catch (e) {
      emit(OnboardingFailure(e.toString()));
    }
  }

  Future<void> _submit(OnboardingEvent event, Emitter<OnboardingState> emit) async {
    emit(OnboardingLoading());
    try {
      if (event is SubmitUserInfoRequested) {
        final entity = UserBasicsEntity(
          fullName: event.payload['fullName'],
          email: event.payload['email'],
        );
        await userBasicsRepository.submitUserBasics(event.token, entity);
        emit(UserInfoSubmitSuccess(entity));
      } else if (event is SubmitUserDetailRequested) {
        final entity = UserDetailsEntity(
          gender: event.payload['gender'],
          dateOfBirth: event.payload['dateOfBirth'],
          heightUnit: event.payload['heightUnit'],
          heightCm: event.payload['heightCm'],
          heightFeet: event.payload['heightFeet'],
          heightInches: event.payload['heightInches'],
          weightUnit: event.payload['weightUnit'],
          weightValue: event.payload['weightValue'],
          waistUnit: event.payload['waistUnit'],
          waistValue: event.payload['waistValue'],
        );
        await userDetailsRepository.submitUserDetails(event.token, entity);
        emit(UserDetailSubmitSuccess(entity));
      } else if (event is SubmitLifestyleRequested) {
        final entity = LifestyleEntity(
          jobType: event.payload['jobType'],
          workEnvironment: event.payload['workEnvironment'],
          stressLevel: event.payload['stressLevel'],
          physicalActivityLevel: event.payload['physicalActivityLevel'],
          hydrationEntry: event.payload['hydrationEntry'],
        );
        await lifestyleRepository.submitLifestyle(event.token, entity);
        emit(LifestyleSubmitSuccess(entity));
      } else if (event is SubmitSkinTypeRequested) {
        final entity = SkinTypeEntity(
          skinType: event.payload['skinType'],
        );
        await skinTypeRepository.submitSkinType(event.token, entity);
        emit(SkinTypeSubmitSuccess(entity));
      } else if (event is SubmitCycleDetailRequested) {
        final entity = CycleDetailsEntity(
          cycleStartDate: event.payload['cycleStartDate'],
          cycleLengthDays: event.payload['cycleLengthDays'],
          currentDayInCycle: event.payload['currentDayInCycle'],
        );
        await cycleDetailsRepository.submitCycleDetails(event.token, entity);
        emit(CycleDetailSubmitSuccess(entity));
      } else if (event is SubmitCycleInfoRequested) {
        final entity = MenstrualCycleOverviewEntity(
          currentPhase: event.payload['currentPhase'],
          cycleRegularity: event.payload['cycleRegularity'],
          pmsSymptoms: event.payload['pmsSymptoms'],
        );
        await menstrualCycleOverviewRepository.submitCycleOverview(event.token, entity);
        emit(CycleInfoSubmitSuccess(entity));
      } else if (event is SubmitMenopauseStatusRequested) {
        final entity = MenopauseEntity(
          menopauseStatus: event.payload['menopauseStatus'],
          lastPeriodDate: event.payload['lastPeriodDate'],
          commonSymptoms: event.payload['commonSymptoms'],
          usingHrtSupplements: event.payload['usingHrtSupplements'],
        );
        await menopauseRepository.submitMenopauseStatus(event.token, entity);
        emit(MenopauseStatusSubmitSuccess(entity));
      } else if (event is SubmitSkinGoalRequested) {
        final entity = SkinGoalsEntity(
          acneBlemishGoals: event.payload['acneBlemishGoals'],
          glowRadianceGoals: event.payload['glowRadianceGoals'],
          hydrationTextureGoals: event.payload['hydrationTextureGoals'],
          notSureYet: event.payload['notSureYet'],
        );
        await skinGoalsRepository.submitSkinGoals(event.token, entity);
        emit(SkinGoalSubmitSuccess(entity));
      } else {
        throw Exception("Unhandled submit event");
      }
    } catch (e) {
      emit(OnboardingFailure(e.toString()));
    }
  }
}
