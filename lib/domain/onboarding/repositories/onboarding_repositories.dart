import 'package:nepika/domain/onboarding/entities/onboarding_entites.dart';

abstract class OnboardingRepository {
  Future<OnboardingScreenDataEntity> fetchQuestions({
    required String userId,
    required String screenSlug,
    required String token,
  });

  Future<void> submitAnswers({
    required String userId,
    required String screenSlug,
    required String token,
    required Map<String, dynamic> answers,
  });
}