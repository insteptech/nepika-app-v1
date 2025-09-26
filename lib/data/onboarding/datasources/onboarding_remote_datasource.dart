import 'dart:convert';

import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/config/constants/api_endpoints.dart';
import 'package:nepika/data/onboarding/models/onboarding_models.dart';

abstract class IOnboardingRemoteDataSource {
  Future<OnboardingScreenDataModel> fetchOnboardingQuestionnaire(
    String userId,
    String screenSlug,
    String token, {
    String lang = 'en',
  });

  Future<Map<String, dynamic>> submitAnswers(
    String userId,
    String screenSlug,
    String token,
    Map<String, dynamic> answers,
  );
}

class OnboardingRemoteDataSource implements IOnboardingRemoteDataSource {
  final ApiBase apiBase;

  OnboardingRemoteDataSource(this.apiBase);

  @override
  Future<OnboardingScreenDataModel> fetchOnboardingQuestionnaire(
    String userId,
    String screenSlug,
    String token, {
    String lang = 'en',
  }) async {
    try {
      final response = await apiBase.request(
        path:
            '${ApiEndpoints.onboardingQuestionnaire}/$screenSlug?lang=$lang',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
     
      return OnboardingScreenDataModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception("Failed to fetch onboarding questionnaire: $e");
    }
  }

  @override
  Future<Map<String, dynamic>> submitAnswers(
    String userId,
    String screenSlug,
    String token,
    Map<String, dynamic> answers,
  ) async {
    try {
      final response = await apiBase.request(
        path: '${ApiEndpoints.onboardingQuestionnaire}/$screenSlug',
        method: 'POST',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: answers
      );
  
      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to submit answers');
      }
      
      return data;
    } catch (e) {
      throw Exception("Failed to submit answers: $e");
    }
  }
}
