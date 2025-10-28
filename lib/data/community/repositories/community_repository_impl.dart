import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/utils/debug_logger.dart';
import '../../../core/config/constants/api_endpoints.dart';
import '../../../domain/community/entities/community_entities.dart';
import '../../../domain/community/repositories/community_repository.dart';
import '../datasources/community_local_datasource.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final ApiBase apiBase;
  final CommunityLocalDataSource localDataSource;
  
  // Request deduplication and caching
  final Map<String, Completer<dynamic>> _activeRequests = {};
  final Map<String, DateTime> _lastRequestTimes = {};
  final Map<String, dynamic> _responseCache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);
  static const Duration _requestDelay = Duration(milliseconds: 100);
  
  CommunityRepositoryImpl(this.apiBase, this.localDataSource);

  // Clear all caches (useful for logout or cache invalidation)
  void clearAllCaches() {
    _responseCache.clear();
    _lastRequestTimes.clear();
    _activeRequests.clear();
    // Note: Clear local cache if method is available
    debugPrint('Repository: All caches cleared');
  }

  @override
  Future<CommunityPostEntity> fetchCommunityPosts({
    required String token,
    required int page,
    required int pageSize,
    String? userId,
    bool? followingOnly,
    bool bypassCache = false,
  }) async {
    final requestKey = 'posts_${page}_${pageSize}_${userId ?? 'all'}_${followingOnly ?? false}';
    
    // Check for active request
    if (_activeRequests.containsKey(requestKey)) {
      return await _activeRequests[requestKey]!.future;
    }
    
    // Check cache first (skip if bypassCache is true)
    if (!bypassCache && _isCacheValid(requestKey)) {
      debugPrint('Repository: Returning cached posts for $requestKey');
      return _responseCache[requestKey] as CommunityPostEntity;
    }
    
    // Try to load from local cache for first page (skip if bypassCache is true)
    if (!bypassCache && page == 1) {
      final cachedPosts = await localDataSource.getCachedPosts();
      if (cachedPosts.isNotEmpty) {
        debugPrint('Repository: Returning ${cachedPosts.length} local cached posts');
        final result = CommunityPostEntity(
          posts: cachedPosts,
          total: cachedPosts.length,
          page: page,
          pageSize: pageSize,
          hasMore: true,
        );
        
        // Update in background
        _fetchAndUpdateCacheInBackground(token, page, pageSize, userId, followingOnly, requestKey);
        return result;
      }
    }
    
    // Log when bypassing cache
    if (bypassCache) {
      debugPrint('Repository: Bypassing cache for home screen - fetching fresh data from server');
    }
    
    final completer = Completer<CommunityPostEntity>();
    _activeRequests[requestKey] = completer;
    
    try {
      
      // Rate limiting
      await _ensureRequestDelay();
      
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
        
        // Cache the response
        _cacheResponse(requestKey, communityPost);
        
        // Cache posts locally
        if (page == 1) {
          await localDataSource.cachePosts(communityPost.posts);
        } else {
          for (final post in communityPost.posts) {
            await localDataSource.cachePost(post);
          }
        }
        
        completer.complete(communityPost);
        return communityPost;
      } else {
        final error = Exception(response.data['message'] ?? 'Failed to fetch community posts');
        completer.completeError(error);
        throw error;
      }
    } catch (e) {
      debugPrint('Repository: Error in fetchCommunityPosts: $e');
      
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      
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
    } finally {
      _activeRequests.remove(requestKey);
    }
  }

  // Optimized background cache update
  void _fetchAndUpdateCacheInBackground(
    String token, 
    int page, 
    int pageSize, 
    String? userId, 
    bool? followingOnly,
    String requestKey,
  ) {
    // Run in microtask to avoid blocking
    Future.microtask(() async {
      try {
        await _ensureRequestDelay();
        
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
          
          // Update both caches
          _cacheResponse(requestKey, communityPost);
          await localDataSource.cachePosts(communityPost.posts);
          
          debugPrint('Repository: Background cache updated with ${communityPost.posts.length} posts');
        }
      } catch (e) {
        debugPrint('Repository: Background cache update failed: $e');
      }
    });
  }
  
  // Cache management utilities
  bool _isCacheValid(String key) {
    if (!_responseCache.containsKey(key) || !_lastRequestTimes.containsKey(key)) {
      return false;
    }
    
    final lastRequest = _lastRequestTimes[key]!;
    return DateTime.now().difference(lastRequest) < _cacheDuration;
  }
  
  void _cacheResponse(String key, dynamic response) {
    _responseCache[key] = response;
    _lastRequestTimes[key] = DateTime.now();
    
    // Clean old cache entries
    _cleanOldCacheEntries();
  }
  
  void _cleanOldCacheEntries() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    _lastRequestTimes.forEach((key, timestamp) {
      if (now.difference(timestamp) > _cacheDuration) {
        keysToRemove.add(key);
      }
    });
    
    for (final key in keysToRemove) {
      _responseCache.remove(key);
      _lastRequestTimes.remove(key);
    }
  }
  
  Future<void> _ensureRequestDelay() async {
    final now = DateTime.now();
    final lastRequest = _lastRequestTimes.values.isNotEmpty 
        ? _lastRequestTimes.values.reduce((a, b) => a.isAfter(b) ? a : b)
        : DateTime(2020);
    
    final timeSinceLastRequest = now.difference(lastRequest);
    if (timeSinceLastRequest < _requestDelay) {
      await Future.delayed(_requestDelay - timeSinceLastRequest);
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
    int? cacheBuster,
  }) async {
    final requestKey = cacheBuster != null 
        ? 'single_post_${postId}_$cacheBuster' 
        : 'single_post_$postId';
    
    // Check for active request
    if (_activeRequests.containsKey(requestKey)) {
      return await _activeRequests[requestKey]!.future;
    }
    
    // Check cache (skip cache when cacheBuster is provided for fresh data)
    if (cacheBuster == null && _isCacheValid(requestKey)) {
      debugPrint('Repository: Returning cached post $postId');
      return _responseCache[requestKey] as PostEntity;
    }
    
    final completer = Completer<PostEntity>();
    _activeRequests[requestKey] = completer;
    
    try {
      await _ensureRequestDelay();
      
      debugPrint('Repository: Fetching single post with ID: $postId${cacheBuster != null ? ' (cache-buster: $cacheBuster)' : ''}');
      
      // Build query parameters for cache-busting
      final queryParams = cacheBuster != null ? {'_t': cacheBuster.toString()} : <String, String>{};
      
      final response = await apiBase.request(
        path: '${ApiEndpoints.getSinglePost}/$postId',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        query: queryParams,
      );
      
      debugPrint('Repository: fetchSinglePost response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final post = PostEntity.fromJson(response.data['data']);
        _cacheResponse(requestKey, post);
        completer.complete(post);
        return post;
      } else {
        final error = Exception(response.data['message'] ?? 'Failed to fetch post');
        completer.completeError(error);
        throw error;
      }
    } catch (e) {
      debugPrint('Repository: Error in fetchSinglePost: $e');
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      rethrow;
    } finally {
      _activeRequests.remove(requestKey);
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
    final requestKey = 'like_$postId';
    
    // Prevent duplicate like requests
    if (_activeRequests.containsKey(requestKey)) {
      return await _activeRequests[requestKey]!.future;
    }
    
    final completer = Completer<Map<String, dynamic>>();
    _activeRequests[requestKey] = completer;
    
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
      
      await _ensureRequestDelay();
      
      final response = await apiBase.request(
        path: '${ApiEndpoints.likePost}/$postId/like',
        method: 'PUT',
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Repository: toggleLikePost response: ${response.statusCode}');
      
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
        
        completer.complete(responseData);
        return responseData;
      } else {
        // Revert optimistic update on error
        await localDataSource.cacheLikeStatus(postId, currentLikeStatus, currentLikeCount);
        if (cachedPost != null) {
          await localDataSource.updateCachedPost(cachedPost);
        }
        final error = Exception(response.data['message'] ?? 'Failed to toggle like');
        completer.completeError(error);
        throw error;
      }
    } catch (e) {
      debugPrint('Repository: Error in toggleLikePost: $e');
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      rethrow;
    } finally {
      _activeRequests.remove(requestKey);
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

  // Image Management
  @override
  Future<Map<String, dynamic>> uploadProfileImage({
    required String token,
    required String imagePath,
    String? userId,
  }) async {
    try {
      debugPrint('Repository: uploadProfileImage called');
      debugPrint('Repository: Image path: $imagePath');
      debugPrint('Repository: User ID: $userId');
      
      // Determine the correct MIME type from file
      final mimeType = lookupMimeType(imagePath) ?? 'image/jpeg';
      final extension = imagePath.toLowerCase().split('.').last;
      final filename = 'profile_image_${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      debugPrint('Repository: Using MIME type: $mimeType for file: $filename');
      
      // Create multipart form data with correct content type using the bytes approach
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      
      // Create MultipartFile with explicit content type
      late MultipartFile multipartFile;
      
      // Validate MIME type and create MultipartFile accordingly
      if (mimeType == 'image/jpeg' || mimeType == 'image/jpg') {
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: filename.endsWith('.jpg') ? filename : '$filename.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        );
      } else if (mimeType == 'image/png') {
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: filename.endsWith('.png') ? filename : '$filename.png',
          contentType: DioMediaType('image', 'png'),
        );
      } else if (mimeType == 'image/gif') {
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: filename.endsWith('.gif') ? filename : '$filename.gif',
          contentType: DioMediaType('image', 'gif'),
        );
      } else if (mimeType == 'image/webp') {
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: filename.endsWith('.webp') ? filename : '$filename.webp',
          contentType: DioMediaType('image', 'webp'),
        );
      } else {
        // Default to JPEG for any other format
        debugPrint('Repository: Unknown MIME type $mimeType, defaulting to JPEG');
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: 'profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        );
      }
      
      final formData = FormData.fromMap({
        'file': multipartFile,
        if (userId != null) 'user_id': userId,
      });
      
      final response = await apiBase.uploadMultipart(
        path: ApiEndpoints.uploadProfileImage,
        formData: formData,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
      );
      
      debugPrint('\n\nRepository: uploadProfileImage response: ${response.statusCode}');
      debugPrint('Repository: uploadProfileImage response data:\n');
      logJson(response.data);
      debugPrint('\n');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to upload profile image');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in uploadProfileImage: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getSecureImageUrl({
    required String token,
    required String s3Url,
    int? expiresIn,
  }) async {
    try {
      debugPrint('Repository: getSecureImageUrl called');
      debugPrint('Repository: S3 URL: $s3Url');
      debugPrint('Repository: Expires in: $expiresIn');
      
      final queryParams = <String, String>{
        's3_url': s3Url,
        if (expiresIn != null) 'expires_in': expiresIn.toString(),
      };
      
      final response = await apiBase.request(
        path: ApiEndpoints.getSecureImageUrl,
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        query: queryParams,
      );
      
      debugPrint('Repository: getSecureImageUrl response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get secure image URL');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in getSecureImageUrl: $e');
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

  // Follow Request System
  @override
  Future<FollowRequestsListEntity> getReceivedFollowRequests({
    required String token,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await apiBase.request(
        path: '/community/follow-requests/received',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        query: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      
      debugPrint('Repository: getReceivedFollowRequests response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return FollowRequestsListEntity.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch received follow requests');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in getReceivedFollowRequests: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<FollowRequestsListEntity> getSentFollowRequests({
    required String token,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await apiBase.request(
        path: '/community/follow-requests/sent',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
        query: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );
      
      debugPrint('Repository: getSentFollowRequests response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return FollowRequestsListEntity.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch sent follow requests');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in getSentFollowRequests: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<FollowRequestActionEntity> acceptFollowRequest({
    required String token,
    required String requestId,
  }) async {
    try {
      final response = await apiBase.request(
        path: '/community/follow-requests/accept/$requestId',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Repository: acceptFollowRequest response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return FollowRequestActionEntity.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to accept follow request');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in acceptFollowRequest: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<FollowRequestActionEntity> declineFollowRequest({
    required String token,
    required String requestId,
  }) async {
    try {
      final response = await apiBase.request(
        path: '/community/follow-requests/decline/$requestId',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Repository: declineFollowRequest response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return FollowRequestActionEntity.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to decline follow request');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in declineFollowRequest: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<FollowRequestActionEntity> cancelFollowRequest({
    required String token,
    required String targetUserId,
  }) async {
    try {
      final response = await apiBase.request(
        path: '/community/follow-requests/cancel/$targetUserId',
        method: 'DELETE',
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Repository: cancelFollowRequest response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return FollowRequestActionEntity.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to cancel follow request');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in cancelFollowRequest: $e');
      debugPrint('Repository: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<FollowRequestStatusEntity> checkFollowRequestStatus({
    required String token,
    required String targetUserId,
  }) async {
    try {
      final response = await apiBase.request(
        path: '/community/follow-requests/status/$targetUserId',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Repository: checkFollowRequestStatus response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return FollowRequestStatusEntity.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to check follow request status');
      }
    } catch (e, stackTrace) {
      debugPrint('Repository: Error in checkFollowRequestStatus: $e');
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