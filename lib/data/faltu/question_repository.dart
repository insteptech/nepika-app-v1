// import 'package:nepika/core/api_base.dart';
// import 'package:nepika/core/config/constants/app_constants.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../models/api_response.dart';
// import 'package:nepika/core/config/constants/api_endpoints.dart';

// class QuestionRepository {
//   final ApiBase apiBase;
//   QuestionRepository(this.apiBase);



//    Future<ApiResponse<Map<String, dynamic>>> fetchOnboardingQuestionare(
//     String screenSlug,
//    ) async {
//     try {

//       final sharedPrefs = await SharedPreferences.getInstance();
//       final accessToken = sharedPrefs.getString(AppConstants.accessTokenKey);
//       final userData = sharedPrefs.getString(AppConstants.userDataKey);

//       print('Fetching onboarding questionnaire for screen: $userData/$screenSlug');

//       final response = await apiBase.request(
//         path: '${ApiEndpoints.onboardingQuestionnaire}/$userData/$screenSlug',
//         method: 'GET',
//         headers: {
//           'Authorization': 'Bearer $accessToken',
//         },
//       );
//       return ApiResponse(
//         data: Map<String, dynamic>.from(response.data['data']),
//         message: response.data['message'] ?? 'Success',
//         statusCode: response.statusCode ?? 200,
//         success: response.data['success'] ?? true,
//       );
//     } catch (e) {
//       return ApiResponse(
//         data: null,
//         message: 'Failed to fetch user details',
//         statusCode: 500,
//         success: false,
//       );
//     }
//   }


//   Future<ApiResponse<Map<String, dynamic>>> fetchUserDetails() async {
//     try {
//       final response = await apiBase.request(
//         path: ApiEndpoints.userDetails,
//         method: 'GET',
//       );
//       return ApiResponse(
//         data: Map<String, dynamic>.from(response.data['data']),
//         message: response.data['message'] ?? 'Success',
//         statusCode: response.statusCode ?? 200,
//         success: response.data['success'] ?? true,
//       );
//     } catch (e) {
//       return ApiResponse(
//         data: null,
//         message: 'Failed to fetch user details',
//         statusCode: 500,
//         success: false,
//       );
//     }
//   }

//   Future<ApiResponse<Map<String, dynamic>>> fetchLifestyle() async {
//     try {
//       final response = await apiBase.request(
//         path: ApiEndpoints.onboardingLifestyle,
//         method: 'GET',
//       );
//       return ApiResponse(
//         data: Map<String, dynamic>.from(response.data['data']),
//         message: response.data['message'] ?? 'Success',
//         statusCode: response.statusCode ?? 200,
//         success: response.data['success'] ?? true,
//       );
//     } catch (e) {
//       return ApiResponse(
//         data: null,
//         message: 'Failed to fetch lifestyle data',
//         statusCode: 500,
//         success: false,
//       );
//     }
//   }

//   Future<ApiResponse<List<String>>> fetchSkinGoals() async {
//     try {
//       final response = await apiBase.request(
//         path: ApiEndpoints.onboardingSkinGoal,
//         method: 'GET',
//       );
//       return ApiResponse(
//         data: List<String>.from(response.data['data']),
//         message: response.data['message'] ?? 'Success',
//         statusCode: response.statusCode ?? 200,
//         success: response.data['success'] ?? true,
//       );
//     } catch (e) {
//       return ApiResponse(
//         data: [],
//         message: 'Failed to fetch skin goals',
//         statusCode: 500,
//         success: false,
//       );
//     }
//   }

//   Future<ApiResponse<String>> fetchSkinType() async {
//     try {
//       final response = await apiBase.request(
//         path: ApiEndpoints.onboardingSkinType,
//         method: 'GET',
//       );
//       return ApiResponse(
//         data: response.data['data'] as String,
//         message: response.data['message'] ?? 'Success',
//         statusCode: response.statusCode ?? 200,
//         success: response.data['success'] ?? true,
//       );
//     } catch (e) {
//       return ApiResponse(
//         data: '',
//         message: 'Failed to fetch skin type',
//         statusCode: 500,
//         success: false,
//       );
//     }
//   }
// }



// data