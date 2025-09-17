import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/constants/api_endpoints.dart';
import '../../../domain/community/entities/community_entities.dart';
import '../../../domain/community/repositories/community_repository.dart';
import '../datasources/community_local_datasource.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final ApiBase apiBase;
  final CommunityLocalDataSource localDataSource;
  
  CommunityRepositoryImpl(this.apiBase, this.localDataSource);

  // Helper method to get user ID from preferences
  Future<String> _getUserId() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final user = sharedPreferences.getString(AppConstants.userDataKey);
    if (user != null) {
      final userMap = jsonDecode(user);
      return userMap['id'];
    }
    throw Exception('User not found');
  }

  @override
  Future<CommunityPostEntity> fetchCommunityPosts({
    required String token,
    required int page,
    required int pageSize,
    String? userId,
    bool? followingOnly,
  }) async {
    try {
      // Try to load from cache first for better UX
      if (page == 1) {
        final cachedPosts = await localDataSource.getCachedPosts();
        if (cachedPosts.isNotEmpty) {
          debugPrint('Repository: Returning ${cachedPosts.length} cached posts');
          // Return cached data immediately, then fetch fresh data
          _fetchAndUpdateCache(token, page, pageSize, userId, followingOnly);
          return CommunityPostEntity(
            posts: cachedPosts,
            total: cachedPosts.length,
            page: page,
            pageSize: pageSize,
            hasMore: true, // Assume more for UX
          );
        }
      }
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
      
      if (userId != null) queryParams['user_id'] = userId;
      if (followingOnly != null) queryParams['following_only'] = followingOnly.toString();

      final response = await apiBase.request(
        path: ApiEndpoints.communityPosts,
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        query: queryParams,
      );
      
      debugPrint('Repository: fetchCommunityPosts response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final communityPost = CommunityPostEntity.fromJson(response.data);
        
        // Cache the posts
        if (page == 1) {
          await localDataSource.cachePosts(communityPost.posts);
        } else {
          // Add to existing cache for pagination
          for (final post in communityPost.posts) {
            await localDataSource.cachePost(post);
          }
        }
        
        return communityPost;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch community posts');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in fetchCommunityPosts: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      
      // Fall back to cache if network fails
      if (page == 1) {
        final cachedPosts = await localDataSource.getCachedPosts();
        if (cachedPosts.isNotEmpty) {
          debugPrint('Repository: Network failed, returning cached posts');
          return CommunityPostEntity(
            posts: cachedPosts,
            total: cachedPosts.length,
            page: page,
            pageSize: pageSize,
            hasMore: false,
          );
        }
      }
      
      rethrow;
    }
  }

  // Background cache update
  void _fetchAndUpdateCache(String token, int page, int pageSize, String? userId, bool? followingOnly) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
      
      if (userId != null) queryParams['user_id'] = userId;
      if (followingOnly != null) queryParams['following_only'] = followingOnly.toString();

      final response = await apiBase.request(
        path: ApiEndpoints.communityPosts,
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        query: queryParams,
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final communityPost = CommunityPostEntity.fromJson(response.data);
        await localDataSource.cachePosts(communityPost.posts);
        debugPrint('Repository: Background cache updated with ${communityPost.posts.length} posts');
      }
    } catch (e) {
      debugPrint('Repository: Background cache update failed: $e');
    }
  }

  @override
  Future<PostEntity> createPost({
    required String token,
    required CreatePostEntity postData,
  }) async {
    try {
      final response = await apiBase.request(
        path: ApiEndpoints.createCommunityPost,
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        body: postData.toJson(),
      );
      
      debugPrint('Repository: createPost response: ${response.statusCode}');
      
      if (response.statusCode == 201 && response.data['success'] == true) {
        return PostEntity.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create post');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in createPost: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<PostEntity> fetchSinglePost({
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
      
      debugPrint('Repository: fetchSinglePost response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return PostEntity.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch post');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in fetchSinglePost: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<CommentListEntity> getPostComments({
    required String token,
    required String postId,
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await apiBase.request(
        path: '${ApiEndpoints.getPostComments}/$postId/comments',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        query: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      
      debugPrint('Repository: getPostComments response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return CommentListEntity.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch comments');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in getPostComments: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<PostEntity> updatePost({
    required String token,
    required String postId,
    required String content,
  }) async {
    try {
      final response = await apiBase.request(
        path: '${ApiEndpoints.updatePost}/$postId',
        method: 'PUT',
        headers: {'Authorization': 'Bearer $token'},
        body: {'content': content},
      );
      
      debugPrint('Repository: updatePost response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return PostEntity.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update post');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in updatePost: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> deletePost({
    required String token,
    required String postId,
  }) async {
    try {
      final response = await apiBase.request(
        path: '${ApiEndpoints.deletePost}/$postId',
        method: 'DELETE',
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Repository: deletePost response: ${response.statusCode}');
      
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete post');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in deletePost: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> toggleLikePost({
    required String token,
    required String postId,
  }) async {
    try {
      debugPrint('Repository: Toggling like for post: $postId');
      
      // Get current cached status
      final cachedStatus = await localDataSource.getCachedLikeStatus(postId);
      final currentLikeStatus = cachedStatus?['is_liked'] as bool? ?? false;
      final currentLikeCount = cachedStatus?['like_count'] as int? ?? 0;
      
      // Optimistically update cache
      final newLikeStatus = !currentLikeStatus;
      final newLikeCount = newLikeStatus ? currentLikeCount + 1 : currentLikeCount - 1;
      await localDataSource.cacheLikeStatus(postId, newLikeStatus, newLikeCount);
      
      // Update cached post
      final cachedPost = await localDataSource.getCachedPost(postId);
      if (cachedPost != null) {
        final updatedPost = PostEntity(
          id: cachedPost.id,
          userId: cachedPost.userId,
          tenantId: cachedPost.tenantId,
          content: cachedPost.content,
          parentPostId: cachedPost.parentPostId,
          likeCount: newLikeCount,
          commentCount: cachedPost.commentCount,
          isEdited: cachedPost.isEdited,
          isDeleted: cachedPost.isDeleted,
          createdAt: cachedPost.createdAt,
          updatedAt: cachedPost.updatedAt,
          username: cachedPost.username,
          userAvatar: cachedPost.userAvatar,
          isLikedByUser: newLikeStatus,
        );
        await localDataSource.updateCachedPost(updatedPost);
      }
      
      final response = await apiBase.request(
        path: '${ApiEndpoints.likePost}/$postId/like',
        method: 'PUT',
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Repository: toggleLikePost response: ${response.statusCode}');
      debugPrint('Repository: toggleLikePost data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final responseData = response.data['data'] as Map<String, dynamic>;
        
        // Update cache with server response
        final serverLikeStatus = responseData['is_liked'] as bool;
        final serverLikeCount = responseData['like_count'] as int;
        await localDataSource.cacheLikeStatus(postId, serverLikeStatus, serverLikeCount);
        
        // Update cached post with server data
        if (cachedPost != null) {
          final updatedPost = PostEntity(
            id: cachedPost.id,
            userId: cachedPost.userId,
            tenantId: cachedPost.tenantId,
            content: cachedPost.content,
            parentPostId: cachedPost.parentPostId,
            likeCount: serverLikeCount,
            commentCount: cachedPost.commentCount,
            isEdited: cachedPost.isEdited,
            isDeleted: cachedPost.isDeleted,
            createdAt: cachedPost.createdAt,
            updatedAt: cachedPost.updatedAt,
            username: cachedPost.username,
            userAvatar: cachedPost.userAvatar,
            isLikedByUser: serverLikeStatus,
          );
          await localDataSource.updateCachedPost(updatedPost);
        }
        
        return responseData;
      } else {
        // Revert optimistic update on error
        await localDataSource.cacheLikeStatus(postId, currentLikeStatus, currentLikeCount);
        if (cachedPost != null) {
          await localDataSource.updateCachedPost(cachedPost);
        }
        throw Exception(response.data['message'] ?? 'Failed to toggle like');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in toggleLikePost: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Profile Management
  @override
  Future<CommunityProfileEntity> createProfile({
    required String token,
    required CreateProfileEntity profileData,
  }) async {
    try {
      debugPrint('Repository: createProfile called');
      debugPrint('Repository: Token: $token');
      debugPrint('Repository: Profile data: ${profileData.toJson()}');
      debugPrint('Repository: API endpoint: ${ApiEndpoints.createProfile}');
      
      final response = await apiBase.request(
        path: ApiEndpoints.createProfile,
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        body: profileData.toJson(),
      );
      
      debugPrint('Repository: createProfile response: ${response.statusCode}');
      debugPrint('Repository: createProfile response data: ${response.data}');
      
      if (response.statusCode == 201 && response.data['success'] == true) {
        debugPrint('Repository: Profile created successfully, parsing response');
        return CommunityProfileEntity.fromJson(response.data['data']);
      } else {
        debugPrint('Repository: Profile creation failed with status: ${response.statusCode}');
        throw Exception(response.data['message'] ?? 'Failed to create profile');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in createProfile: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<CommunityProfileEntity> getMyProfile({
    required String token,
    required String userId,
  }) async {
    try {
      final response = await apiBase.request(
        path: '${ApiEndpoints.getMyProfile}/$userId',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Repository: getMyProfile response: ${response.statusCode}');
      debugPrint('Repository: getMyProfile endpoint: ${ApiEndpoints.getMyProfile}/$userId');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return CommunityProfileEntity.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch profile');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in getMyProfile: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<CommunityProfileEntity> getUserProfile({
    required String token,
    required String userId,
  }) async {
    try {
      final response = await apiBase.request(
        path: '${ApiEndpoints.getUserProfile}/$userId',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Repository: getUserProfile response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return CommunityProfileEntity.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch user profile');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in getUserProfile: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<CommunityProfileEntity> updateProfile({
    required String token,
    required UpdateProfileEntity profileData,
  }) async {
    try {
      final response = await apiBase.request(
        path: ApiEndpoints.updateProfile,
        method: 'PUT',
        headers: {'Authorization': 'Bearer $token'},
        body: profileData.toJson(),
      );
      
      debugPrint('Repository: updateProfile response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return CommunityProfileEntity.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update profile');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in updateProfile: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Follow System
  @override
  Future<FollowResponseEntity> followUser({
    required String token,
    required String userId,
  }) async {
    try {
      final response = await apiBase.request(
        path: ApiEndpoints.followUser,
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        body: {'user_id': userId},
      );
      
      debugPrint('Repository: followUser response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return FollowResponseEntity.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to follow user');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in followUser: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<FollowResponseEntity> unfollowUser({
    required String token,
    required String userId,
  }) async {
    try {
      final response = await apiBase.request(
        path: '${ApiEndpoints.unfollowUser}/$userId',
        method: 'DELETE',
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Repository: unfollowUser response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return FollowResponseEntity.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to unfollow user');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in unfollowUser: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<UserListEntity> getFollowers({
    required String token,
    required String userId,
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await apiBase.request(
        path: '${ApiEndpoints.getFollowers}/$userId/followers',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        query: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      
      debugPrint('Repository: getFollowers response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return UserListEntity.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch followers');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in getFollowers: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<UserListEntity> getFollowing({
    required String token,
    required String userId,
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await apiBase.request(
        path: '${ApiEndpoints.getFollowing}/$userId/following',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        query: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      
      debugPrint('Repository: getFollowing response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return UserListEntity.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch following');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in getFollowing: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<FollowStatusEntity> checkFollowStatus({
    required String token,
    required String userId,
  }) async {
    try {
      final response = await apiBase.request(
        path: '${ApiEndpoints.checkFollowStatus}/$userId',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Repository: checkFollowStatus response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return FollowStatusEntity.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to check follow status');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in checkFollowStatus: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Legacy methods for backward compatibility
  @override
  Future<UserSearchEntity> searchUsers({
    required String token,
    required String query,
  }) async {
    try {
      final response = await apiBase.request(
        path: ApiEndpoints.userSearch,
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        query: {'q': query},
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return UserSearchEntity(
          users: List<Map<String, dynamic>>.from(response.data['data'])
        );
      } else {
        throw Exception(response.data['message'] ?? 'Failed to search users');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in searchUsers: $e');
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
        path: '${ApiEndpoints.getUserProfile}/$userId',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Repository: fetchUserProfile response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data') && data['success'] == true) {
            return UserProfileResponseEntity.fromJson(data['data']);
          }
          return UserProfileResponseEntity.fromJson(data);
        }
        throw Exception('Invalid response format: ${data.runtimeType}');
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch user profile');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in fetchUserProfile: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Block System Implementation
  @override
  Future<BlockResponseEntity> blockUser({
    required String token,
    required BlockUserEntity blockData,
  }) async {
    try {
      debugPrint('Repository: Blocking user with ID: ${blockData.userId}');
      final response = await apiBase.request(
        path: '/community/block',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        body: blockData.toJson(),
      );
      
      debugPrint('Repository: blockUser response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return BlockResponseEntity.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to block user');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in blockUser: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<BlockResponseEntity> unblockUser({
    required String token,
    required String userId,
  }) async {
    try {
      debugPrint('Repository: Unblocking user with ID: $userId');
      final response = await apiBase.request(
        path: '/community/block/$userId',
        method: 'DELETE',
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Repository: unblockUser response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return BlockResponseEntity.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to unblock user');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in unblockUser: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<BlockStatusEntity> checkBlockStatus({
    required String token,
    required String userId,
  }) async {
    try {
      debugPrint('Repository: Checking block status for user ID: $userId');
      final response = await apiBase.request(
        path: '/community/block/status/$userId',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Repository: checkBlockStatus response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return BlockStatusEntity.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to check block status');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in checkBlockStatus: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<CommunityPostEntity> getUserThreads({
    required String token,
    required String userId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      debugPrint('Repository: Fetching user threads for user ID: $userId, page: $page');
      final response = await apiBase.request(
        path: '/community/users/posts/$userId',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        query: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      
      debugPrint('Repository: getUserThreads response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return CommunityPostEntity.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch user threads');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in getUserThreads: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<CommunityPostEntity> getUserReplies({
    required String token,
    required String userId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      debugPrint('Repository: Fetching user replies for user ID: $userId, page: $page');
      final response = await apiBase.request(
        path: '/community/users/posts/$userId/comments',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        query: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      
      debugPrint('Repository: getUserReplies response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return CommunityPostEntity.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch user replies');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in getUserReplies: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getBlockedUsers({
    required String token,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      debugPrint('Repository: Fetching blocked users, page: $page');
      final response = await apiBase.request(
        path: '/community/blocks',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        query: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      
      debugPrint('Repository: getBlockedUsers response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch blocked users');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in getBlockedUsers: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<UserSearchResponseEntity> searchUsersV2({
    required String token,
    required String query,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      debugPrint('Repository: Searching users V2 with query: $query, page: $page');
      final response = await apiBase.request(
        path: ApiEndpoints.userSearch,
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        query: {
          'q': query,
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      
      debugPrint('Repository: searchUsersV2 response: ${response.statusCode}');
      debugPrint('Repository: searchUsersV2 data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return UserSearchResponseEntity.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to search users');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in searchUsersV2: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }
}