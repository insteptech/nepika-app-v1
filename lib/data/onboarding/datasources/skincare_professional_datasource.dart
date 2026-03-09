import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/config/constants/api_endpoints.dart';

class SkincareProfessionalDataSource {
  final ApiBase apiBase;

  SkincareProfessionalDataSource(this.apiBase);

  /// Fetch skin concerns list from the backend
  Future<List<Map<String, String>>> fetchSkinConcerns() async {
    try {
      final response = await apiBase.request(
        path: '${ApiEndpoints.onboardingQuestionnaire}/skin-concerns',
        method: 'GET',
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final concerns = data['data']['concerns'] as List<dynamic>;
        return concerns
            .map(
              (c) => {
                'id': c['id']?.toString() ?? '',
                'name': c['name']?.toString() ?? '',
              },
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching skin concerns: $e');
      return [];
    }
  }

  /// Flag the user as a skincare professional early (before full form submission)
  Future<void> flagAsProfessional() async {
    try {
      await apiBase.request(
        path: '${ApiEndpoints.onboardingQuestionnaire}/flag-professional',
        method: 'POST',
      );
    } catch (e) {
      debugPrint('Error flagging as professional: $e');
    }
  }

  /// Fetch user's existing skincare professional data for editing
  Future<Map<String, dynamic>?> fetchProfessionalProfile() async {
    try {
      final response = await apiBase.request(
        path: '${ApiEndpoints.onboardingQuestionnaire}/skincare-professional',
        method: 'GET',
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        return data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching professional profile: $e');
      return null;
    }
  }

  /// Submit skincare professional onboarding data
  Future<Map<String, dynamic>> submitProfessionalOnboarding({
    required String salonBusinessName,
    required String country,
    String? cityTown,
    required String professionalRole,
    required String qualification,
    required List<String> skinConcernsTreated,
    required String businessType,
    required String yearsOfExperience,
    required bool consentProfessional,
    required bool consentTerms,
  }) async {
    try {
      final response = await apiBase.request(
        path: '${ApiEndpoints.onboardingQuestionnaire}/skincare-professional',
        method: 'POST',
        body: {
          'salon_business_name': salonBusinessName,
          'country': country,
          'city_town': cityTown,
          'professional_role': professionalRole,
          'qualification': qualification,
          'skin_concerns_treated': skinConcernsTreated,
          'business_type': businessType,
          'years_of_experience': yearsOfExperience,
          'consent_professional': consentProfessional,
          'consent_terms': consentTerms,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == false) {
        throw Exception(
          data['message'] ?? 'Failed to submit professional data',
        );
      }
      return data;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String errorMessage = 'Failed to submit professional data';
      if (responseData is Map<String, dynamic> &&
          responseData['message'] != null) {
        errorMessage = responseData['message'].toString();
      }
      throw Exception(errorMessage);
    }
  }
}
