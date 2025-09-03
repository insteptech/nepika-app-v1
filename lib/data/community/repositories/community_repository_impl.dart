import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/constants/api_endpoints.dart';
import '../../../domain/community/entities/community_entities.dart';
import '../../../domain/community/repositories/community_repository.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final ApiBase apiBase;
  CommunityRepositoryImpl(this.apiBase);

  @override
  Future<CommunityPostEntity> fetchCommunityPosts({
    required String token,
    required int page,
    required int limit,
  }) async {
    final response = await apiBase.request(
      path: ApiEndpoints.communityPosts,
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
      query: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    
    if (response.statusCode == 200 && response.data['success'] == true) {
      // debugPrint(response.data['data']);
      return CommunityPostEntity(
        posts: List<Map<String, dynamic>>.from(response.data['data'])
      );
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch community posts');
    }
  }

  @override
  Future<UserSearchEntity> searchUsers({
    required String token,
    required String query,
  }) async {
    final response = await apiBase.request(
      path: ApiEndpoints.userSearch,
      method: 'GET',
      headers: {'Authorization': 'Bearer $token'},
      query: {'query': query},
    );
    
    if (response.statusCode == 200 && response.data['success'] == true) {
      return UserSearchEntity(
        users: List<Map<String, dynamic>>.from(response.data['data'])
      );
    } else {
      throw Exception(response.data['message'] ?? 'Failed to search users');
    }
  }

  @override
  Future<CreatePostResponseEntity> createPost({
    required String token,
    required CreatePostEntity postData,
  }) async {
    final response = await apiBase.request(
      path: ApiEndpoints.createCommunityPost,
      method: 'POST',
      headers: {'Authorization': 'Bearer $token'},
      body: postData.toJson(),
    );
    
    if (response.statusCode == 200 && response.data['success'] == true) {
      return CreatePostResponseEntity(
        response: Map<String, dynamic>.from(response.data)
      );
    } else {
      throw Exception(response.data['message'] ?? 'Failed to create post');
    }
  }

  @override
  Future<PostDetailEntity> fetchSinglePost({
    required String token,
    required String postId,
  }) async {
    try {
      debugPrint('Repository: Fetching single post with ID: $postId');
      final response = await apiBase.request(
        path: '${ApiEndpoints.getSinglePost}/$postId',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Repository: Response status: ${response.statusCode}');
      debugPrint('Repository: Response data: ${response.data}');
      
      if (response.statusCode == 200) {
        // Handle both success wrapper and direct response formats
        final data = response.data;
        if (data is Map<String, dynamic>) {
          // If wrapped in success response, extract data
          if (data.containsKey('data') && data['success'] == true) {
            debugPrint('Repository: Using wrapped response format');
            return PostDetailEntity.fromJson(data['data']);
          }
          // Otherwise use direct response
          debugPrint('Repository: Using direct response format');
          return PostDetailEntity.fromJson(data);
        }
        throw Exception('Invalid response format: ${data.runtimeType}');
      } else {
        final errorMessage = response.data is Map<String, dynamic> 
            ? response.data['message'] ?? 'Failed to fetch post details'
            : 'Failed to fetch post details';
        throw Exception('HTTP ${response.statusCode}: $errorMessage');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in fetchSinglePost: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<LikePostResponseEntity> likePost({
    required String token,
    required String postId,
  }) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      late String userId;
      final user = sharedPreferences.getString(AppConstants.userDataKey);

      if (user != null) {
        final userMap = jsonDecode(user);
        userId = userMap['id'];
      }
      
      debugPrint('Repository: Liking post with ID: $postId');
      debugPrint('Repository: User ID: $userId');
      
      final response = await apiBase.request(
        path: '${ApiEndpoints.likePost}/$postId/like',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        body: {'user_id': userId}
      );
      
      debugPrint('Repository: Like response status: ${response.statusCode}');
      debugPrint('Repository: Like response data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return LikePostResponseEntity.fromJson(response.data);
      } else {
        final errorMessage = response.data is Map<String, dynamic> 
            ? response.data['message'] ?? 'Failed to like post'
            : 'Failed to like post';
        throw Exception('HTTP ${response.statusCode}: $errorMessage');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in likePost: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<UnlikePostResponseEntity> unlikePost({
    required String token,
    required String postId,
  }) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      late String userId;
      final user = sharedPreferences.getString(AppConstants.userDataKey);

      if (user != null) {
        final userMap = jsonDecode(user);
        userId = userMap['id'];
      }
      
      debugPrint('Repository: Unliking post with ID: $postId');
      debugPrint('Repository: User ID: $userId');
      
      final response = await apiBase.request(
        path: '${ApiEndpoints.unlikePost}/$postId/unlike',
        method: 'DELETE',
        headers: {'Authorization': 'Bearer $token'},
        body: {'user_id': userId}
      );
      
      debugPrint('Repository: Unlike response status: ${response.statusCode}');
      debugPrint('Repository: Unlike response data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return UnlikePostResponseEntity.fromJson(response.data ?? {});
      } else {
        final errorMessage = response.data is Map<String, dynamic> 
            ? response.data['message'] ?? 'Failed to unlike post'
            : 'Failed to unlike post';
        throw Exception('HTTP ${response.statusCode}: $errorMessage');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in unlikePost: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<UserProfileResponseEntity> fetchUserProfile({
    required String token,
    required String userId,
  }) async {
    try {
      debugPrint('Repository: Fetching user profile with ID: $userId');
      final response = await apiBase.request(
        path: '${ApiEndpoints.userProfile}/$userId',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Repository: Profile response status: ${response.statusCode}');
      debugPrint('Repository: Profile response data: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          // If wrapped in success response, extract data
          if (data.containsKey('data') && data['success'] == true) {
            debugPrint('Repository: Using wrapped response format');
            return UserProfileResponseEntity.fromJson(data['data']);
          }
          // Otherwise use direct response
          debugPrint('Repository: Using direct response format');
          return UserProfileResponseEntity.fromJson(data);
        }
        throw Exception('Invalid response format: ${data.runtimeType}');
      } else {
        final errorMessage = response.data is Map<String, dynamic> 
            ? response.data['message'] ?? 'Failed to fetch user profile'
            : 'Failed to fetch user profile';
        throw Exception('HTTP ${response.statusCode}: $errorMessage');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in fetchUserProfile: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }
}
