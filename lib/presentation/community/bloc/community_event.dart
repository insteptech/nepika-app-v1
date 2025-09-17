import '../../../domain/community/entities/community_entities.dart';

abstract class CommunityEvent {}

class FetchCommunityPosts extends CommunityEvent {
  final String token;
  final int page;
  final int pageSize;
  final String? userId;
  final bool? followingOnly;

  FetchCommunityPosts({
    required this.token,
    this.page = 1,
    this.pageSize = 20,
    this.userId,
    this.followingOnly,
  });
}

class LoadMoreCommunityPosts extends CommunityEvent {
  final String token;
  final int page;
  final int pageSize;
  final String? userId;
  final bool? followingOnly;

  LoadMoreCommunityPosts({
    required this.token,
    required this.page,
    this.pageSize = 20,
    this.userId,
    this.followingOnly,
  });
}

class SearchUsers extends CommunityEvent {
  final String token;
  final String query;

  SearchUsers({
    required this.token,
    required this.query,
  });
}

class ClearUserSearch extends CommunityEvent {}

class CreatePost extends CommunityEvent {
  final String token;
  final CreatePostEntity postData;

  CreatePost({
    required this.token,
    required this.postData,
  });
}

class RefreshCommunityPosts extends CommunityEvent {
  final String token;
  final int pageSize;
  final String? userId;
  final bool? followingOnly;

  RefreshCommunityPosts({
    required this.token,
    this.pageSize = 20,
    this.userId,
    this.followingOnly,
  });
}

class FetchSinglePost extends CommunityEvent {
  final String token;
  final String postId;

  FetchSinglePost({
    required this.token,
    required this.postId,
  });
}

class LikePost extends CommunityEvent {
  final String token;
  final String postId;

  LikePost({
    required this.token,
    required this.postId,
  });
}

class UnlikePost extends CommunityEvent {
  final String token;
  final String postId;

  UnlikePost({
    required this.token,
    required this.postId,
  });
}

class ToggleLikePost extends CommunityEvent {
  final String token;
  final String postId;
  final bool currentLikeStatus;

  ToggleLikePost({
    required this.token,
    required this.postId,
    required this.currentLikeStatus,
  });
}

class FetchUserProfile extends CommunityEvent {
  final String token;
  final String userId;

  FetchUserProfile({
    required this.token,
    required this.userId,
  });
}

// New events for enhanced functionality

// Comments
class FetchPostComments extends CommunityEvent {
  final String token;
  final String postId;
  final int page;
  final int pageSize;

  FetchPostComments({
    required this.token,
    required this.postId,
    this.page = 1,
    this.pageSize = 20,
  });
}

class LoadMoreComments extends CommunityEvent {
  final String token;
  final String postId;
  final int page;
  final int pageSize;

  LoadMoreComments({
    required this.token,
    required this.postId,
    required this.page,
    this.pageSize = 20,
  });
}

// Post Management
class UpdatePost extends CommunityEvent {
  final String token;
  final String postId;
  final String content;

  UpdatePost({
    required this.token,
    required this.postId,
    required this.content,
  });
}

class DeletePost extends CommunityEvent {
  final String token;
  final String postId;

  DeletePost({
    required this.token,
    required this.postId,
  });
}

// Profile Management
class CreateProfile extends CommunityEvent {
  final String token;
  final CreateProfileEntity profileData;

  CreateProfile({
    required this.token,
    required this.profileData,
  });
}

class FetchMyProfile extends CommunityEvent {
  final String token;
  final String userId;

  FetchMyProfile({
    required this.token,
    required this.userId,
  });
}

class UpdateProfile extends CommunityEvent {
  final String token;
  final UpdateProfileEntity profileData;

  UpdateProfile({
    required this.token,
    required this.profileData,
  });
}

// Follow System
class FollowUser extends CommunityEvent {
  final String token;
  final String userId;

  FollowUser({
    required this.token,
    required this.userId,
  });
}

class UnfollowUser extends CommunityEvent {
  final String token;
  final String userId;

  UnfollowUser({
    required this.token,
    required this.userId,
  });
}

class FetchFollowers extends CommunityEvent {
  final String token;
  final String userId;
  final int page;
  final int pageSize;

  FetchFollowers({
    required this.token,
    required this.userId,
    this.page = 1,
    this.pageSize = 20,
  });
}

class FetchFollowing extends CommunityEvent {
  final String token;
  final String userId;
  final int page;
  final int pageSize;

  FetchFollowing({
    required this.token,
    required this.userId,
    this.page = 1,
    this.pageSize = 20,
  });
}

class CheckFollowStatus extends CommunityEvent {
  final String token;
  final String userId;

  CheckFollowStatus({
    required this.token,
    required this.userId,
  });
}

// Block System
class BlockUser extends CommunityEvent {
  final String token;
  final BlockUserEntity blockData;

  BlockUser({
    required this.token,
    required this.blockData,
  });
}

class UnblockUser extends CommunityEvent {
  final String token;
  final String userId;

  UnblockUser({
    required this.token,
    required this.userId,
  });
}

class CheckBlockStatus extends CommunityEvent {
  final String token;
  final String userId;

  CheckBlockStatus({
    required this.token,
    required this.userId,
  });
}

// User Posts Events
class FetchUserThreads extends CommunityEvent {
  final String token;
  final String userId;
  final int page;
  final int pageSize;

  FetchUserThreads({
    required this.token,
    required this.userId,
    this.page = 1,
    this.pageSize = 20,
  });
}

class FetchUserReplies extends CommunityEvent {
  final String token;
  final String userId;
  final int page;
  final int pageSize;

  FetchUserReplies({
    required this.token,
    required this.userId,
    this.page = 1,
    this.pageSize = 20,
  });
}

class LoadMoreUserThreads extends CommunityEvent {
  final String token;
  final String userId;
  final int page;
  final int pageSize;

  LoadMoreUserThreads({
    required this.token,
    required this.userId,
    required this.page,
    this.pageSize = 20,
  });
}

class LoadMoreUserReplies extends CommunityEvent {
  final String token;
  final String userId;
  final int page;
  final int pageSize;

  LoadMoreUserReplies({
    required this.token,
    required this.userId,
    required this.page,
    this.pageSize = 20,
  });
}

class GetCommunityProfile extends CommunityEvent {
  final String token;
  final String userId;

  GetCommunityProfile({
    required this.token,
    required this.userId,
  });
}

// New User Search Events
class SearchUsersV2 extends CommunityEvent {
  final String token;
  final String query;
  final int page;
  final int pageSize;

  SearchUsersV2({
    required this.token,
    required this.query,
    this.page = 1,
    this.pageSize = 10,
  });
}

class ToggleUserFollow extends CommunityEvent {
  final String token;
  final String userId;
  final bool currentlyFollowing;

  ToggleUserFollow({
    required this.token,
    required this.userId,
    required this.currentlyFollowing,
  });
}
