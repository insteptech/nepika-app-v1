import '../entities/community_entities.dart';

abstract class CommunityRepository {
  Future<CommunityPostEntity> fetchCommunityPosts({
    required String token,
    required int page,
    required int limit,
  });

  Future<UserSearchEntity> searchUsers({
    required String token,
    required String query,
  });

  Future<CreatePostResponseEntity> createPost({
    required String token,
    required CreatePostEntity postData,
  });

  Future<PostDetailEntity> fetchSinglePost({
    required String token,
    required String postId,
  });

  Future<LikePostResponseEntity> likePost({
    required String token,
    required String postId,
  });

  Future<UnlikePostResponseEntity> unlikePost({
    required String token,
    required String postId,
  });

  Future<UserProfileResponseEntity> fetchUserProfile({
    required String token,
    required String userId,
  });
}
