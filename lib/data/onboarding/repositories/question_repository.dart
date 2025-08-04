// import 'package:nepika/core/api_base.dart';

// import '../models/api_response.dart';
// import '../../../core/constants/api_endpoints.dart';

// class QuestionRepository {
//   final ApiBase apiBase;
//   QuestionRepository(this.apiBase);

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
//         path: ApiEndpoints.lifestyle,
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
//         path: ApiEndpoints.skinGoals,
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
//         path: ApiEndpoints.skinType,
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
