import '../entities/community_entities.dart';

abstract class CommunityRepository {
  // Post Management
  Future<CommunityPostEntity> fetchCommunityPosts({
    required String token,
    required int page,
    required int pageSize,
    String? userId,
    bool? followingOnly,
    bool bypassCache = false, // Bypass local client-side cache only
  });

  Future<PostEntity> createPost({
    required String token,
    required CreatePostEntity postData,
  });

  Future<PostEntity> fetchSinglePost({
    required String token,
    required String postId,
    int? cacheBuster,
  });

  Future<CommentListEntity> getPostComments({
    required String token,
    required String postId,
    required int page,
    required int pageSize,
  });

  Future<PostEntity> updatePost({
    required String token,
    required String postId,
    required String content,
  });

  Future<void> deletePost({
    required String token,
    required String postId,
  });

  Future<Map<String, dynamic>> toggleLikePost({
    required String token,
    required String postId,
  });

  // Profile Management
  Future<CommunityProfileEntity> createProfile({
    required String token,
    required CreateProfileEntity profileData,
  });

  Future<CommunityProfileEntity> getMyProfile({
    required String token,
    required String userId,
  });

  Future<CommunityProfileEntity> getUserProfile({
    required String token,
    required String userId,
  });

  Future<CommunityProfileEntity> updateProfile({
    required String token,
    required UpdateProfileEntity profileData,
  });

  // Image Management
  Future<Map<String, dynamic>> uploadProfileImage({
    required String token,
    required String imagePath,
    String? userId,
  });

  Future<Map<String, dynamic>> getSecureImageUrl({
    required String token,
    required String s3Url,
    int? expiresIn,
  });

  // Follow System
  Future<FollowResponseEntity> followUser({
    required String token,
    required String userId,
  });

  Future<FollowResponseEntity> unfollowUser({
    required String token,
    required String userId,
  });

  Future<UserListEntity> getFollowers({
    required String token,
    required String userId,
    required int page,
    required int pageSize,
  });

  Future<UserListEntity> getFollowing({
    required String token,
    required String userId,
    required int page,
    required int pageSize,
  });

  Future<FollowStatusEntity> checkFollowStatus({
    required String token,
    required String userId,
  });

  // Block System
  Future<BlockResponseEntity> blockUser({
    required String token,
    required BlockUserEntity blockData,
  });

  Future<BlockResponseEntity> unblockUser({
    required String token,
    required String userId,
  });

  Future<BlockStatusEntity> checkBlockStatus({
    required String token,
    required String userId,
  });

  Future<Map<String, dynamic>> getBlockedUsers({
    required String token,
    int page = 1,
    int pageSize = 20,
  });

  // Legacy methods for backward compatibility
  Future<UserSearchEntity> searchUsers({
    required String token,
    required String query,
  });

  Future<UserProfileResponseEntity> fetchUserProfile({
    required String token,
    required String userId,
  });

  // User Posts Methods
  Future<CommunityPostEntity> getUserThreads({
    required String token,
    required String userId,
    int page = 1,
    int pageSize = 20,
  });

  Future<CommunityPostEntity> getUserReplies({
    required String token,
    required String userId,
    int page = 1,
    int pageSize = 20,
  });

  // New User Search Methods
  Future<UserSearchResponseEntity> searchUsersV2({
    required String token,
    required String query,
    int page = 1,
    int pageSize = 10,
  });
}
