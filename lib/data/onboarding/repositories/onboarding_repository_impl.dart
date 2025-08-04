// import 'package:nepika/data/onboarding/datasources/onboarding_remote_datasource.dart';
// import 'package:nepika/domain/onboarding/entities/onboarding_entites.dart';
// import 'package:nepika/domain/onboarding/repositories/onboarding_repositories.dart';
// import 'package:nepika/data/onboarding/datasources/onboarding_remote_datasource.dart';

// class UserBasicsRepositoryImpl implements UserBasicsRepository {
//   final OnboardingRemoteDataSource dataSource;

//   UserBasicsRepositoryImpl(this.dataSource);

//   @override
//   Future<UserBasicsEntity> fetchUserBasics(String token) {
//     return dataSource.fetchUserBasics(token);
//   }

//   @override
//   Future<void> submitUserBasics(String token, UserBasicsEntity entity) {
//     return dataSource.submitUserBasics(token, entity);
//   }
// }

// class UserDetailsRepositoryImpl implements UserDetailsRepository {
//   final OnboardingRemoteDataSource dataSource;

//   UserDetailsRepositoryImpl(this.dataSource);

//   @override
//   Future<UserDetailsEntity> fetchUserDetails(String token) {
//     return dataSource.fetchUserDetails(token);
//   }

//   @override
//   Future<void> submitUserDetails(String token, UserDetailsEntity entity) {
//     return dataSource.submitUserDetails(token, entity);
//   }
// }

// class LifestyleRepositoryImpl implements LifestyleRepository {
//   final OnboardingRemoteDataSource dataSource;

//   LifestyleRepositoryImpl(this.dataSource);

//   @override
//   Future<LifestyleEntity> fetchLifestyle(String token) {
//     return dataSource.fetchLifestyle(token);
//   }

//   @override
//   Future<void> submitLifestyle(String token, LifestyleEntity entity) {
//     return dataSource.submitLifestyle(token, entity);
//   }
// }

// class SkinTypeRepositoryImpl implements SkinTypeRepository {
//   final OnboardingRemoteDataSource dataSource;

//   SkinTypeRepositoryImpl(this.dataSource);

//   @override
//   Future<SkinTypeEntity> fetchSkinType(String token, String productId) {
//     return dataSource.fetchSkinType(token, productId);
//   }

//   @override
//   Future<void> submitSkinType(String token, SkinTypeEntity entity) {
//     return dataSource.submitSkinType(token, entity);
//   }
// }

// class NaturalRhythmRepositoryImpl implements NaturalRhythmRepository {
//   final OnboardingRemoteDataSource dataSource;

//   NaturalRhythmRepositoryImpl(this.dataSource);

//   @override
//   Future<NaturalRhythmEntity> fetchNaturalRhythm(String token) {
//     return dataSource.fetchNaturalRhythm(token);
//   }

//   @override
//   Future<void> submitNaturalRhythm(String token, NaturalRhythmEntity entity) {
//     return dataSource.submitNaturalRhythm(token, entity);
//   }
// }

// class MenstrualCycleOverviewRepositoryImpl implements MenstrualCycleOverviewRepository {
//   final OnboardingRemoteDataSource dataSource;

//   MenstrualCycleOverviewRepositoryImpl(this.dataSource);

//   @override
//   Future<MenstrualCycleOverviewEntity> fetchCycleOverview(String token, String productId) {
//     return dataSource.fetchCycleOverview(token, productId);
//   }

//   @override
//   Future<void> submitCycleOverview(String token, MenstrualCycleOverviewEntity entity) {
//     return dataSource.submitCycleOverview(token, entity);
//   }
// }

// class CycleDetailsRepositoryImpl implements CycleDetailsRepository {
//   final OnboardingRemoteDataSource dataSource;

//   CycleDetailsRepositoryImpl(this.dataSource);

//   @override
//   Future<CycleDetailsEntity> fetchCycleDetails(String token) {
//     return dataSource.fetchCycleDetails(token);
//   }

//   @override
//   Future<void> submitCycleDetails(String token, CycleDetailsEntity entity) {
//     return dataSource.submitCycleDetails(token, entity);
//   }
// }

// class MenopauseRepositoryImpl implements MenopauseRepository {
//   final OnboardingRemoteDataSource dataSource;

//   MenopauseRepositoryImpl(this.dataSource);

//   @override
//   Future<MenopauseEntity> fetchMenopauseStatus(String token) {
//     return dataSource.fetchMenopauseStatus(token);
//   }

//   @override
//   Future<void> submitMenopauseStatus(String token, MenopauseEntity entity) {
//     return dataSource.submitMenopauseStatus(token, entity);
//   }
// }

// class SkinGoalsRepositoryImpl implements SkinGoalsRepository {
//   final OnboardingRemoteDataSource dataSource;

//   SkinGoalsRepositoryImpl(this.dataSource);

//   @override
//   Future<SkinGoalsEntity> fetchSkinGoals(String token, String productId) {
//     return dataSource.fetchSkinGoals(token, productId);
//   }

//   @override
//   Future<void> submitSkinGoals(String token, SkinGoalsEntity entity) {
//     return dataSource.submitSkinGoals(token, entity);
//   }
// }
