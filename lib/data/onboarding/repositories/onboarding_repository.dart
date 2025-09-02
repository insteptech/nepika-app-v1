import 'package:nepika/data/onboarding/datasources/onboarding_remote_datasource.dart';
import 'package:nepika/data/onboarding/models/onboarding_models.dart';
import 'package:nepika/domain/onboarding/entities/onboarding_entites.dart';
import 'package:nepika/domain/onboarding/repositories/onboarding_repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nepika/core/config/constants/app_constants.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final IOnboardingRemoteDataSource dataSource;

  OnboardingRepositoryImpl(this.dataSource);

  @override
  Future<OnboardingScreenDataEntity> fetchQuestions({
    required String userId,
    required String screenSlug,
    required String token,
  }) async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      final accessToken =
          sharedPrefs.getString(AppConstants.accessTokenKey) ?? token;

      final model = await dataSource.fetchOnboardingQuestionnaire(
          userId, screenSlug, accessToken);

      return _mapToEntity(model);
    } catch (e) {
      throw Exception("Failed to fetch onboarding questions: $e");
    }
  }

  @override
  Future<void> submitAnswers({
    required String userId,
    required String screenSlug,
    required String token,
    required Map<String, dynamic> answers,
  }) async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      final accessToken =
          sharedPrefs.getString(AppConstants.accessTokenKey) ?? token;

      await dataSource.submitAnswers(userId, screenSlug, accessToken, answers);
    } catch (e) {
      throw Exception("Failed to submit onboarding answers: $e");
    }
  }

  OnboardingScreenDataEntity _mapToEntity(OnboardingScreenDataModel model) {
    return OnboardingScreenDataEntity(
      screenId: model.screenId,
      title: model.title,
      description: model.description,
      slug: model.slug,
      questions: model.questions
          .map(
            (q) => OnboardingQuestionEntity(
              id: q.id,
              slug: q.slug,
              questionText: q.questionText,
              targetField: q.targetField,
              targetTable: q.targetTable,
              inputType: q.inputType,
              keyboardType: q.keyboardType,
              prefillValue: q.prefillValue,
              inputPlaceholder: q.inputPlaceholder ?? '',
              isRequired: q.isRequired,
              displayOrder: q.displayOrder,
              options: q.options
                  .map(
                    (o) => OnboardingOptionEntity(
                      id: o.id,
                      text: o.text,
                      description: o.description,
                      value: o.value,
                      sortOrder: o.sortOrder,
                      isSelected: o.isSelected,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }
}
