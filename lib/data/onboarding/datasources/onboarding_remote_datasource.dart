import 'package:nepika/data/onboarding/models/onboarding_models.dart';

abstract class IOnboardingRemoteDataSource {
  Future<UserBasicsModel> fetchUserBasics(String token);
  Future<void> submitUserBasics(String token, UserBasicsModel model);

  Future<UserDetailsModel> fetchUserDetails(String token);
  Future<void> submitUserDetails(String token, UserDetailsModel model);

  Future<LifestyleModel> fetchLifestyle(String token);
  Future<void> submitLifestyle(String token, LifestyleModel model);

  Future<SkinTypeModel> fetchSkinType(String token, String productId);
  Future<void> submitSkinType(String token, SkinTypeModel model);

  Future<NaturalRhythmModel> fetchNaturalRhythm(String token);
  Future<void> submitNaturalRhythm(String token, NaturalRhythmModel model);

  Future<MenstrualCycleOverviewModel> fetchCycleOverview(String token, String productId);
  Future<void> submitCycleOverview(String token, MenstrualCycleOverviewModel model);

  Future<CycleDetailsModel> fetchCycleDetails(String token);
  Future<void> submitCycleDetails(String token, CycleDetailsModel model);

  Future<MenopauseModel> fetchMenopauseStatus(String token);
  Future<void> submitMenopauseStatus(String token, MenopauseModel model);

  Future<SkinGoalsModel> fetchSkinGoals(String token, String productId);
  Future<void> submitSkinGoals(String token, SkinGoalsModel model);
}

class OnboardingRemoteDataSource implements IOnboardingRemoteDataSource {
  // Example: final http.Client client;
  // You can inject client via constructor if needed

  @override
  Future<UserBasicsModel> fetchUserBasics(String token) async {
    // TODO: Replace with actual API call
    return UserBasicsModel(fullName: 'Demo', email: 'demo@email.com');
  }

  @override
  Future<void> submitUserBasics(String token, UserBasicsModel model) async {
    // TODO: Replace with POST call
  }

  @override
  Future<UserDetailsModel> fetchUserDetails(String token) async {
    return UserDetailsModel(
      gender: 'Female',
      dateOfBirth: '2000-01-01',
      heightUnit: 'cm',
      heightCm: 160,
      weightUnit: 'kg',
      weightValue: 50,
      waistUnit: 'cm',
      waistValue: 70,
    );
  }

  @override
  Future<void> submitUserDetails(String token, UserDetailsModel model) async {}

  @override
  Future<LifestyleModel> fetchLifestyle(String token) async {
    return LifestyleModel(
      jobType: 'Desk Job',
      workEnvironment: 'Indoor',
      stressLevel: 'Moderate',
      physicalActivityLevel: 'Low',
      hydrationEntry: '2L',
    );
  }

  @override
  Future<void> submitLifestyle(String token, LifestyleModel model) async {}

  @override
  Future<SkinTypeModel> fetchSkinType(String token, String productId) async {
    return SkinTypeModel(skinType: 'Oily');
  }

  @override
  Future<void> submitSkinType(String token, SkinTypeModel model) async {}

  @override
  Future<NaturalRhythmModel> fetchNaturalRhythm(String token) async {
    return NaturalRhythmModel(doYouMenstruate: true);
  }

  @override
  Future<void> submitNaturalRhythm(String token, NaturalRhythmModel model) async {}

  @override
  Future<MenstrualCycleOverviewModel> fetchCycleOverview(String token, String productId) async {
    return MenstrualCycleOverviewModel(
      currentPhase: 'Luteal',
      cycleRegularity: 'Regular',
      pmsSymptoms: ['Bloating'],
    );
  }

  @override
  Future<void> submitCycleOverview(String token, MenstrualCycleOverviewModel model) async {}

  @override
  Future<CycleDetailsModel> fetchCycleDetails(String token) async {
    return CycleDetailsModel(
      cycleStartDate: '2025-08-01',
      cycleLengthDays: 28,
      currentDayInCycle: 3,
    );
  }

  @override
  Future<void> submitCycleDetails(String token, CycleDetailsModel model) async {}

  @override
  Future<MenopauseModel> fetchMenopauseStatus(String token) async {
    return MenopauseModel(
      menopauseStatus: 'Perimenopause',
      lastPeriodDate: '2024-12-01',
      commonSymptoms: ['Hot flashes'],
      usingHrtSupplements: false,
    );
  }

  @override
  Future<void> submitMenopauseStatus(String token, MenopauseModel model) async {}

  @override
  Future<SkinGoalsModel> fetchSkinGoals(String token, String productId) async {
    return SkinGoalsModel(
      acneBlemishGoals: ['Reduce acne'],
      glowRadianceGoals: ['Increase glow'],
      hydrationTextureGoals: ['Improve texture'],
      notSureYet: false,
    );
  }

  @override
  Future<void> submitSkinGoals(String token, SkinGoalsModel model) async {}
}
