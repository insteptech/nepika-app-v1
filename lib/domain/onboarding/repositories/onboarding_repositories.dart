import 'package:nepika/domain/onboarding/entities/onboarding_entites.dart';

abstract class UserBasicsRepository {
  Future<UserBasicsEntity> fetchUserBasics(String token);
  Future<void> submitUserBasics(String token, UserBasicsEntity entity);
}

abstract class UserDetailsRepository {
  Future<UserDetailsEntity> fetchUserDetails(String token);
  Future<void> submitUserDetails(String token, UserDetailsEntity entity);
}

abstract class LifestyleRepository {
  Future<LifestyleEntity> fetchLifestyle(String token);
  Future<void> submitLifestyle(String token, LifestyleEntity entity);
}

abstract class SkinTypeRepository {
  Future<SkinTypeEntity> fetchSkinType(String token, String productId);
  Future<void> submitSkinType(String token, SkinTypeEntity entity);
}

abstract class NaturalRhythmRepository {
  Future<NaturalRhythmEntity> fetchNaturalRhythm(String token);
  Future<void> submitNaturalRhythm(String token, NaturalRhythmEntity entity);
}

abstract class MenstrualCycleOverviewRepository {
  Future<MenstrualCycleOverviewEntity> fetchCycleOverview(
    String token,
    String productId,
  );
  Future<void> submitCycleOverview(
    String token,
    MenstrualCycleOverviewEntity entity,
  );
}

abstract class CycleDetailsRepository {
  Future<CycleDetailsEntity> fetchCycleDetails(String token);
  Future<void> submitCycleDetails(String token, CycleDetailsEntity entity);
}

abstract class MenopauseRepository {
  Future<MenopauseEntity> fetchMenopauseStatus(String token);
  Future<void> submitMenopauseStatus(String token, MenopauseEntity entity);
}

abstract class SkinGoalsRepository {
  Future<SkinGoalsEntity> fetchSkinGoals(String token, String productId);
  Future<void> submitSkinGoals(String token, SkinGoalsEntity entity);
}
