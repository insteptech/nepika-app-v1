import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

      // Check if the response indicates failure
      if (data['success'] == false) {
        // Extract the user-friendly error message from the backend
        final errorMessage = data['message'] as String? ?? 'Failed to submit answers';
        throw Exception(errorMessage);
      }

      return data;
    } on DioException catch (e) {
      // Handle Dio-specific errors (network, HTTP errors, etc.)
      debugPrint('========================================');
      debugPrint('OnboardingDataSource: DioException occurred');
      debugPrint('Status code: ${e.response?.statusCode}');
      debugPrint('Response data: ${e.response?.data}');
      debugPrint('========================================');

      final responseData = e.response?.data;

      // Extract error message from backend response
      String errorMessage = 'Failed to submit answers';

      if (responseData is Map<String, dynamic>) {
        if (responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        } else if (responseData['detail'] != null) {
          errorMessage = responseData['detail'].toString();
        } else if (e.response?.statusCode == 400) {
          errorMessage = 'Invalid data submitted. Please check your answers.';
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Session expired. Please login again.';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Onboarding step not found.';
        } else if (e.response?.statusCode == 500) {
          errorMessage = 'Server error. Please try again later.';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server is taking too long to respond. Please try again.';
      } else if (e.type == DioExceptionType.unknown) {
        errorMessage = 'Network error. Please check your internet connection.';
      }

      debugPrint('Final error message: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('OnboardingDataSource: Unexpected error: $e');
      // Re-throw if it's already an Exception with a message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Unexpected error: $e');
    }
  }
}
