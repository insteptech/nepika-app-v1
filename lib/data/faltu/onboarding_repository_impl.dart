// import 'package:nepika/data/onboarding/datasources/onboarding_remote_datasource.dart';
// import 'package:nepika/domain/onboarding/entities/onboarding_entites.dart';
// import 'package:nepika/domain/onboarding/repositories/onboarding_repositories.dart';
// import 'package:nepika/data/onboarding/models/onboarding_models.dart';

// class UserBasicsRepositoryImpl implements UserBasicsRepository {
//   final IOnboardingRemoteDataSource dataSource;
//   UserBasicsRepositoryImpl(this.dataSource);
//   @override
//   Future<UserBasicsEntity> fetchUserBasics(String token) async {
//     final model = await dataSource.fetchUserBasics(token);
//     return UserBasicsEntity(fullName: model.fullName, email: model.email);
//   }
//   @override
//   Future<void> submitUserBasics(String token, UserBasicsEntity entity) {
//     return dataSource.submitUserBasics(token, UserBasicsModel(fullName: entity.fullName, email: entity.email));
//   }
// }

// class UserDetailsRepositoryImpl implements UserDetailsRepository {
//   final IOnboardingRemoteDataSource dataSource;
//   UserDetailsRepositoryImpl(this.dataSource);
//   @override
//   Future<UserDetailsEntity> fetchUserDetails(String token) async {
//     final model = await dataSource.fetchUserDetails(token);
//     return UserDetailsEntity(
//       gender: model.gender,
//       dateOfBirth: model.dateOfBirth,
//       heightUnit: model.heightUnit,
//       heightCm: model.heightCm,
//       heightFeet: model.heightFeet,
//       heightInches: model.heightInches,
//       weightUnit: model.weightUnit,
//       weightValue: model.weightValue,
//       waistUnit: model.waistUnit,
//       waistValue: model.waistValue,
//     );
//   }
//   @override
//   Future<void> submitUserDetails(String token, UserDetailsEntity entity) {
//     return dataSource.submitUserDetails(token, UserDetailsModel(
//       gender: entity.gender,
//       dateOfBirth: entity.dateOfBirth,
//       heightUnit: entity.heightUnit,
//       heightCm: entity.heightCm,
//       heightFeet: entity.heightFeet,
//       heightInches: entity.heightInches,
//       weightUnit: entity.weightUnit,
//       weightValue: entity.weightValue,
//       waistUnit: entity.waistUnit,
//       waistValue: entity.waistValue,
//     ));
//   }
// }

// class LifestyleRepositoryImpl implements LifestyleRepository {
//   final IOnboardingRemoteDataSource dataSource;
//   LifestyleRepositoryImpl(this.dataSource);
//   @override
//   Future<LifestyleEntity> fetchLifestyle(String token) async {
//     final model = await dataSource.fetchLifestyle(token);
//     return LifestyleEntity(
//       jobType: model.jobType,
//       workEnvironment: model.workEnvironment,
//       stressLevel: model.stressLevel,
//       physicalActivityLevel: model.physicalActivityLevel,
//       hydrationEntry: model.hydrationEntry,
//     );
//   }
//   @override
//   Future<void> submitLifestyle(String token, LifestyleEntity entity) {
//     return dataSource.submitLifestyle(token, LifestyleModel(
//       jobType: entity.jobType,
//       workEnvironment: entity.workEnvironment,
//       stressLevel: entity.stressLevel,
//       physicalActivityLevel: entity.physicalActivityLevel,
//       hydrationEntry: entity.hydrationEntry,
//     ));
//   }
// }

// class SkinTypeRepositoryImpl implements SkinTypeRepository {
//   final IOnboardingRemoteDataSource dataSource;
//   SkinTypeRepositoryImpl(this.dataSource);
//   @override
//   Future<SkinTypeEntity> fetchSkinType(String token, String productId) async {
//     final model = await dataSource.fetchSkinType(token, productId);
//     return SkinTypeEntity(skinType: model.skinType);
//   }
//   @override
//   Future<void> submitSkinType(String token, SkinTypeEntity entity) {
//     return dataSource.submitSkinType(token, SkinTypeModel(skinType: entity.skinType));
//   }
// }

// class NaturalRhythmRepositoryImpl implements NaturalRhythmRepository {
//   final IOnboardingRemoteDataSource dataSource;
//   NaturalRhythmRepositoryImpl(this.dataSource);
//   @override
//   Future<NaturalRhythmEntity> fetchNaturalRhythm(String token) async {
//     final model = await dataSource.fetchNaturalRhythm(token);
//     return NaturalRhythmEntity(doYouMenstruate: model.doYouMenstruate);
//   }
//   @override
//   Future<void> submitNaturalRhythm(String token, NaturalRhythmEntity entity) {
//     return dataSource.submitNaturalRhythm(token, NaturalRhythmModel(doYouMenstruate: entity.doYouMenstruate));
//   }
// }

// class MenstrualCycleOverviewRepositoryImpl implements MenstrualCycleOverviewRepository {
//   final IOnboardingRemoteDataSource dataSource;
//   MenstrualCycleOverviewRepositoryImpl(this.dataSource);
//   @override
//   Future<MenstrualCycleOverviewEntity> fetchCycleOverview(String token, String productId) async {
//     final model = await dataSource.fetchCycleOverview(token, productId);
//     return MenstrualCycleOverviewEntity(
//       currentPhase: model.currentPhase,
//       cycleRegularity: model.cycleRegularity,
//       pmsSymptoms: model.pmsSymptoms,
//     );
//   }
//   @override
//   Future<void> submitCycleOverview(String token, MenstrualCycleOverviewEntity entity) {
//     return dataSource.submitCycleOverview(token, MenstrualCycleOverviewModel(
//       currentPhase: entity.currentPhase,
//       cycleRegularity: entity.cycleRegularity,
//       pmsSymptoms: entity.pmsSymptoms,
//     ));
//   }
// }

// class CycleDetailsRepositoryImpl implements CycleDetailsRepository {
//   final IOnboardingRemoteDataSource dataSource;
//   CycleDetailsRepositoryImpl(this.dataSource);
//   @override
//   Future<CycleDetailsEntity> fetchCycleDetails(String token) async {
//     final model = await dataSource.fetchCycleDetails(token);
//     return CycleDetailsEntity(
//       cycleStartDate: model.cycleStartDate,
//       cycleLengthDays: model.cycleLengthDays,
//       currentDayInCycle: model.currentDayInCycle,
//     );
//   }
//   @override
//   Future<void> submitCycleDetails(String token, CycleDetailsEntity entity) {
//     return dataSource.submitCycleDetails(token, CycleDetailsModel(
//       cycleStartDate: entity.cycleStartDate,
//       cycleLengthDays: entity.cycleLengthDays,
//       currentDayInCycle: entity.currentDayInCycle,
//     ));
//   }
// }

// class MenopauseRepositoryImpl implements MenopauseRepository {
//   final IOnboardingRemoteDataSource dataSource;
//   MenopauseRepositoryImpl(this.dataSource);
//   @override
//   Future<MenopauseEntity> fetchMenopauseStatus(String token) async {
//     final model = await dataSource.fetchMenopauseStatus(token);
//     return MenopauseEntity(
//       menopauseStatus: model.menopauseStatus,
//       lastPeriodDate: model.lastPeriodDate,
//       commonSymptoms: model.commonSymptoms,
//       usingHrtSupplements: model.usingHrtSupplements,
//     );
//   }
//   @override
//   Future<void> submitMenopauseStatus(String token, MenopauseEntity entity) {
//     return dataSource.submitMenopauseStatus(token, MenopauseModel(
//       menopauseStatus: entity.menopauseStatus,
//       lastPeriodDate: entity.lastPeriodDate,
//       commonSymptoms: entity.commonSymptoms,
//       usingHrtSupplements: entity.usingHrtSupplements,
//     ));
//   }
// }

// class SkinGoalsRepositoryImpl implements SkinGoalsRepository {
//   final IOnboardingRemoteDataSource dataSource;
//   SkinGoalsRepositoryImpl(this.dataSource);
//   @override
//   Future<SkinGoalsEntity> fetchSkinGoals(String token, String productId) async {
//     final model = await dataSource.fetchSkinGoals(token, productId);
//     return SkinGoalsEntity(
//       acneBlemishGoals: model.acneBlemishGoals,
//       glowRadianceGoals: model.glowRadianceGoals,
//       hydrationTextureGoals: model.hydrationTextureGoals,
//       notSureYet: model.notSureYet,
//     );
//   }
//   @override
//   Future<void> submitSkinGoals(String token, SkinGoalsEntity entity) {
//     return dataSource.submitSkinGoals(token, SkinGoalsModel(
//       acneBlemishGoals: entity.acneBlemishGoals,
//       glowRadianceGoals: entity.glowRadianceGoals,
//       hydrationTextureGoals: entity.hydrationTextureGoals,
//       notSureYet: entity.notSureYet,
//     ));
//   }
// }
// data