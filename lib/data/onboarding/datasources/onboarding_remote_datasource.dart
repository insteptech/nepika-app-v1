import 'package:nepika/data/onboarding/models/onboarding_models.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/constants/api_endpoints.dart';

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
  final ApiBase apiBase;
  OnboardingRemoteDataSource(this.apiBase);

  @override
  Future<UserBasicsModel> fetchUserBasics(String token) async {
    final response = await apiBase.request(
      path: ApiEndpoints.onboardingUserInfo,
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
    );
    return UserBasicsModel.fromJson(response.data['data']);
  }

  @override
  Future<void> submitUserBasics(String token, UserBasicsModel model) async {
    await apiBase.request(
      path: ApiEndpoints.onboardingUserInfo,
      method: 'POST',
      headers: {'Authorization': 'Bearer $token'},
      body: model.toJson(),
    );
  }

  @override
  Future<UserDetailsModel> fetchUserDetails(String token) async {
    final response = await apiBase.request(
      path: ApiEndpoints.onboardingUserDetail,
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
    );
    return UserDetailsModel.fromJson(response.data['data']);
  }

  @override
  Future<void> submitUserDetails(String token, UserDetailsModel model) async {
    await apiBase.request(
      path: ApiEndpoints.onboardingUserDetail,
      method: 'POST',
      headers: {'Authorization': 'Bearer $token'},
      body: model.toJson(),
    );
  }

  @override
  Future<LifestyleModel> fetchLifestyle(String token) async {
    final response = await apiBase.request(
      path: ApiEndpoints.onboardingLifestyle,
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
    );
    return LifestyleModel.fromJson(response.data['data']);
  }

  @override
  Future<void> submitLifestyle(String token, LifestyleModel model) async {
    await apiBase.request(
      path: ApiEndpoints.onboardingLifestyle,
      method: 'POST',
      headers: {'Authorization': 'Bearer $token'},
      body: model.toJson(),
    );
  }

  @override
  Future<SkinTypeModel> fetchSkinType(String token, String productId) async {
    final response = await apiBase.request(
      path: ApiEndpoints.onboardingSkinType,
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
      query: {'product_id': productId},
    );
    return SkinTypeModel.fromJson(response.data['data']);
  }

  @override
  Future<void> submitSkinType(String token, SkinTypeModel model) async {
    await apiBase.request(
      path: ApiEndpoints.onboardingSkinType,
      method: 'POST',
      headers: {'Authorization': 'Bearer $token'},
      body: model.toJson(),
    );
  }

  @override
  Future<NaturalRhythmModel> fetchNaturalRhythm(String token) async {
    final response = await apiBase.request(
      path: ApiEndpoints.onboardingUserNaturalRhythm,
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
    );
    return NaturalRhythmModel.fromJson(response.data['data']);
  }

  @override
  Future<void> submitNaturalRhythm(String token, NaturalRhythmModel model) async {
    await apiBase.request(
      path: ApiEndpoints.onboardingUserNaturalRhythm,
      method: 'POST',
      headers: {'Authorization': 'Bearer $token'},
      body: model.toJson(),
    );
  }

  @override
  Future<MenstrualCycleOverviewModel> fetchCycleOverview(String token, String productId) async {
    final response = await apiBase.request(
      path: ApiEndpoints.onboardingCycleInfo,
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
      query: {'product_id': productId},
    );
    return MenstrualCycleOverviewModel.fromJson(response.data['data']);
  }

  @override
  Future<void> submitCycleOverview(String token, MenstrualCycleOverviewModel model) async {
    await apiBase.request(
      path: ApiEndpoints.onboardingCycleInfo,
      method: 'POST',
      headers: {'Authorization': 'Bearer $token'},
      body: model.toJson(),
    );
  }

  @override
  Future<CycleDetailsModel> fetchCycleDetails(String token) async {
    final response = await apiBase.request(
      path: ApiEndpoints.onboardingCycleDetail,
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
    );
    return CycleDetailsModel.fromJson(response.data['data']);
  }

  @override
  Future<void> submitCycleDetails(String token, CycleDetailsModel model) async {
    await apiBase.request(
      path: ApiEndpoints.onboardingCycleDetail,
      method: 'POST',
      headers: {'Authorization': 'Bearer $token'},
      body: model.toJson(),
    );
  }

  @override
  Future<MenopauseModel> fetchMenopauseStatus(String token) async {
    final response = await apiBase.request(
      path: ApiEndpoints.onboardingMenopauseStatus,
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
    );
    return MenopauseModel.fromJson(response.data['data']);
  }

  @override
  Future<void> submitMenopauseStatus(String token, MenopauseModel model) async {
    await apiBase.request(
      path: ApiEndpoints.onboardingMenopauseStatus,
      method: 'POST',
      headers: {'Authorization': 'Bearer $token'},
      body: model.toJson(),
    );
  }

  @override
  Future<SkinGoalsModel> fetchSkinGoals(String token, String productId) async {
    final response = await apiBase.request(
      path: ApiEndpoints.onboardingSkinGoal,
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
      query: {'product_id': productId},
    );
    return SkinGoalsModel.fromJson(response.data['data']);
  }

  @override
  Future<void> submitSkinGoals(String token, SkinGoalsModel model) async {
    await apiBase.request(
      path: ApiEndpoints.onboardingSkinGoal,
      method: 'POST',
      headers: {'Authorization': 'Bearer $token'},
      body: model.toJson(),
    );
  }
}
