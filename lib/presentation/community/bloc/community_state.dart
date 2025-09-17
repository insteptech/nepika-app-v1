import '../../../domain/community/entities/community_entities.dart';

abstract class CommunityState {}

class CommunityInitial extends CommunityState {}

// Community Posts States
class CommunityPostsLoading extends CommunityState {}

class CommunityPostsLoaded extends CommunityState {
  final List<PostEntity> posts;
  final bool hasMorePosts;
  final int currentPage;

  CommunityPostsLoaded({
    required this.posts,
    required this.hasMorePosts,
    required this.currentPage,
  });

  CommunityPostsLoaded copyWith({
    List<PostEntity>? posts,
    bool? hasMorePosts,
    int? currentPage,
  }) {
    return CommunityPostsLoaded(
      posts: posts ?? this.posts,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class CommunityPostsError extends CommunityState {
  final String message;

  CommunityPostsError(this.message);
}

class CommunityPostsLoadingMore extends CommunityState {
  final List<PostEntity> currentPosts;
  final int currentPage;

  CommunityPostsLoadingMore({
    required this.currentPosts,
    required this.currentPage,
  });
}

// User Search States
class UserSearchLoading extends CommunityState {}

class UserSearchLoaded extends CommunityState {
  final List<SearchUserEntity> users;

  UserSearchLoaded({required this.users});
}

class UserSearchError extends CommunityState {
  final String message;

  UserSearchError(this.message);
}

class UserSearchEmpty extends CommunityState {}

// Create Post States
class CreatePostLoading extends CommunityState {}

class CreatePostSuccess extends CommunityState {
  final Map<String, dynamic> response;

  CreatePostSuccess({required this.response});
}

class CreatePostError extends CommunityState {
  final String message;

  CreatePostError(this.message);
}

// Combined State for handling multiple operations
class CommunityMultipleState extends CommunityState {
  final CommunityState postsState;
  final CommunityState searchState;
  final CommunityState createPostState;

  CommunityMultipleState({
    required this.postsState,
    required this.searchState,
    required this.createPostState,
  });
}

// Single Post Detail States
class PostDetailLoading extends CommunityState {}

class PostDetailLoaded extends CommunityState {
  final PostDetailEntity post;

  PostDetailLoaded({required this.post});
}

class PostDetailError extends CommunityState {
  final String message;

  PostDetailError(this.message);
}

// Like/Unlike Post States
class PostLikeLoading extends CommunityState {
  final String postId;
  final bool isLiking; // true for like, false for unlike

  PostLikeLoading({
    required this.postId,
    required this.isLiking,
  });
}

class PostLikeSuccess extends CommunityState {
  final String postId;
  final bool isLiked;
  final LikePostResponseEntity? likeResponse;
  final UnlikePostResponseEntity? unlikeResponse;

  PostLikeSuccess({
    required this.postId,
    required this.isLiked,
    this.likeResponse,
    this.unlikeResponse,
  });
}

class PostLikeError extends CommunityState {
  final String postId;
  final String message;
  final bool wasLiking; // true if error occurred while liking, false if while unliking

  PostLikeError({
    required this.postId,
    required this.message,
    required this.wasLiking,
  });
}

class PostLikeToggled extends CommunityState {
  final String postId;
  final bool isLiked;

  PostLikeToggled({
    required this.postId,
    required this.isLiked,
  });
}

// User Profile States
class UserProfileLoading extends CommunityState {}

class UserProfileLoaded extends CommunityState {
  final UserProfileResponseEntity profileData;

  UserProfileLoaded({required this.profileData});
}

class UserProfileError extends CommunityState {
  final String message;

  UserProfileError(this.message);
}

// New states for enhanced functionality

// Comments States
class CommentsLoading extends CommunityState {}

class CommentsLoaded extends CommunityState {
  final List<PostEntity> comments;
  final String parentPostId;
  final bool hasMoreComments;
  final int currentPage;
  final int total;

  CommentsLoaded({
    required this.comments,
    required this.parentPostId,
    required this.hasMoreComments,
    required this.currentPage,
    required this.total,
  });

  CommentsLoaded copyWith({
    List<PostEntity>? comments,
    String? parentPostId,
    bool? hasMoreComments,
    int? currentPage,
    int? total,
  }) {
    return CommentsLoaded(
      comments: comments ?? this.comments,
      parentPostId: parentPostId ?? this.parentPostId,
      hasMoreComments: hasMoreComments ?? this.hasMoreComments,
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
    );
  }
}

class CommentsError extends CommunityState {
  final String message;
  CommentsError(this.message);
}

class CommentsLoadingMore extends CommunityState {
  final List<PostEntity> currentComments;
  final String parentPostId;
  final int currentPage;

  CommentsLoadingMore({
    required this.currentComments,
    required this.parentPostId,
    required this.currentPage,
  });
}

// Post Management States
class PostUpdateLoading extends CommunityState {}

class PostUpdateSuccess extends CommunityState {
  final PostEntity updatedPost;
  PostUpdateSuccess({required this.updatedPost});
}

class PostUpdateError extends CommunityState {
  final String message;
  PostUpdateError(this.message);
}

class PostDeleteLoading extends CommunityState {}

class PostDeleteSuccess extends CommunityState {
  final String deletedPostId;
  PostDeleteSuccess({required this.deletedPostId});
}

class PostDeleteError extends CommunityState {
  final String message;
  PostDeleteError(this.message);
}

// Profile Management States
class ProfileCreateLoading extends CommunityState {}

class ProfileCreateSuccess extends CommunityState {
  final CommunityProfileEntity profile;
  ProfileCreateSuccess({required this.profile});
}

class ProfileCreateError extends CommunityState {
  final String message;
  ProfileCreateError(this.message);
}

class MyProfileLoading extends CommunityState {}

class MyProfileLoaded extends CommunityState {
  final CommunityProfileEntity profile;
  MyProfileLoaded({required this.profile});
}

class MyProfileError extends CommunityState {
  final String message;
  MyProfileError(this.message);
}

class ProfileUpdateLoading extends CommunityState {}

class ProfileUpdateSuccess extends CommunityState {
  final CommunityProfileEntity updatedProfile;
  ProfileUpdateSuccess({required this.updatedProfile});
}

class ProfileUpdateError extends CommunityState {
  final String message;
  ProfileUpdateError(this.message);
}

// Follow System States
class FollowLoading extends CommunityState {
  final String userId;
  final bool isFollowing; // true for follow, false for unfollow
  
  FollowLoading({
    required this.userId,
    required this.isFollowing,
  });
}

class FollowSuccess extends CommunityState {
  final String userId;
  final bool isFollowing;
  final String message;

  FollowSuccess({
    required this.userId,
    required this.isFollowing,
    required this.message,
  });
}

class FollowError extends CommunityState {
  final String userId;
  final String message;
  final bool wasFollowing;

  FollowError({
    required this.userId,
    required this.message,
    required this.wasFollowing,
  });
}

class FollowStatusLoading extends CommunityState {}

class FollowStatusLoaded extends CommunityState {
  final String userId;
  final bool isFollowing;

  FollowStatusLoaded({
    required this.userId,
    required this.isFollowing,
  });
}

class FollowStatusError extends CommunityState {
  final String message;
  FollowStatusError(this.message);
}

// Followers/Following States
class FollowersLoading extends CommunityState {}

class FollowersLoaded extends CommunityState {
  final List<CommunityProfileEntity> followers;
  final String userId;
  final bool hasMoreFollowers;
  final int currentPage;
  final int total;

  FollowersLoaded({
    required this.followers,
    required this.userId,
    required this.hasMoreFollowers,
    required this.currentPage,
    required this.total,
  });

  FollowersLoaded copyWith({
    List<CommunityProfileEntity>? followers,
    String? userId,
    bool? hasMoreFollowers,
    int? currentPage,
    int? total,
  }) {
    return FollowersLoaded(
      followers: followers ?? this.followers,
      userId: userId ?? this.userId,
      hasMoreFollowers: hasMoreFollowers ?? this.hasMoreFollowers,
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
    );
  }
}

class FollowersError extends CommunityState {
  final String message;
  FollowersError(this.message);
}

class FollowingLoading extends CommunityState {}

class FollowingLoaded extends CommunityState {
  final List<CommunityProfileEntity> following;
  final String userId;
  final bool hasMoreFollowing;
  final int currentPage;
  final int total;

  FollowingLoaded({
    required this.following,
    required this.userId,
    required this.hasMoreFollowing,
    required this.currentPage,
    required this.total,
  });

  FollowingLoaded copyWith({
    List<CommunityProfileEntity>? following,
    String? userId,
    bool? hasMoreFollowing,
    int? currentPage,
    int? total,
  }) {
    return FollowingLoaded(
      following: following ?? this.following,
      userId: userId ?? this.userId,
      hasMoreFollowing: hasMoreFollowing ?? this.hasMoreFollowing,
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
    );
  }
}

class FollowingError extends CommunityState {
  final String message;
  FollowingError(this.message);
}

// Enhanced Like States (updated for new API)
class PostLikeToggleSuccess extends CommunityState {
  final String postId;
  final bool isLiked;
  final int likeCount;
  final String message;

  PostLikeToggleSuccess({
    required this.postId,
    required this.isLiked,
    required this.likeCount,
    required this.message,
  });
}

// Block System States
class BlockUserLoading extends CommunityState {
  final String userId;
  
  BlockUserLoading({required this.userId});
}

class BlockUserSuccess extends CommunityState {
  final String userId;
  final bool isBlocked;
  final String message;

  BlockUserSuccess({
    required this.userId,
    required this.isBlocked,
    required this.message,
  });
}

class BlockUserError extends CommunityState {
  final String userId;
  final String message;

  BlockUserError({
    required this.userId,
    required this.message,
  });
}

class UnblockUserLoading extends CommunityState {
  final String userId;
  
  UnblockUserLoading({required this.userId});
}

class UnblockUserSuccess extends CommunityState {
  final String userId;
  final bool isBlocked;
  final String message;

  UnblockUserSuccess({
    required this.userId,
    required this.isBlocked,
    required this.message,
  });
}

class UnblockUserError extends CommunityState {
  final String userId;
  final String message;

  UnblockUserError({
    required this.userId,
    required this.message,
  });
}

class BlockStatusLoading extends CommunityState {}

class BlockStatusLoaded extends CommunityState {
  final String userId;
  final bool isBlocked;

  BlockStatusLoaded({
    required this.userId,
    required this.isBlocked,
  });
}

class BlockStatusError extends CommunityState {
  final String message;
  BlockStatusError(this.message);
}

// User Threads States
class UserThreadsLoading extends CommunityState {
  final String userId;
  UserThreadsLoading({required this.userId});
}

class UserThreadsLoaded extends CommunityState {
  final String userId;
  final List<PostEntity> threads;
  final bool hasMoreThreads;
  final int currentPage;
  final int total;

  UserThreadsLoaded({
    required this.userId,
    required this.threads,
    required this.hasMoreThreads,
    required this.currentPage,
    required this.total,
  });
}

class UserThreadsLoadingMore extends CommunityState {
  final String userId;
  UserThreadsLoadingMore({required this.userId});
}

class UserThreadsError extends CommunityState {
  final String userId;
  final String message;
  
  UserThreadsError({
    required this.userId,
    required this.message,
  });
}

// User Replies States
class UserRepliesLoading extends CommunityState {
  final String userId;
  UserRepliesLoading({required this.userId});
}

class UserRepliesLoaded extends CommunityState {
  final String userId;
  final List<PostEntity> replies;
  final bool hasMoreReplies;
  final int currentPage;
  final int total;

  UserRepliesLoaded({
    required this.userId,
    required this.replies,
    required this.hasMoreReplies,
    required this.currentPage,
    required this.total,
  });
}

class UserRepliesLoadingMore extends CommunityState {
  final String userId;
  UserRepliesLoadingMore({required this.userId});
}

class UserRepliesError extends CommunityState {
  final String userId;
  final String message;
  
  UserRepliesError({
    required this.userId,
    required this.message,
  });
}

// Community Profile States
class CommunityProfileLoading extends CommunityState {
  final String userId;
  CommunityProfileLoading({required this.userId});
}

class CommunityProfileLoaded extends CommunityState {
  final CommunityProfileEntity profile;

  CommunityProfileLoaded({required this.profile});
}

class CommunityProfileError extends CommunityState {
  final String userId;
  final String message;
  
  CommunityProfileError({
    required this.userId,
    required this.message,
  });
}

// New User Search States
class UserSearchV2Loading extends CommunityState {
  final String query;
  UserSearchV2Loading({required this.query});
}

class UserSearchV2Loaded extends CommunityState {
  final UserSearchResponseEntity response;
  final List<UserSearchResultEntity> users;

  UserSearchV2Loaded({
    required this.response,
    required this.users,
  });
}

class UserSearchV2Error extends CommunityState {
  final String query;
  final String message;
  
  UserSearchV2Error({
    required this.query,
    required this.message,
  });
}

class UserSearchV2Empty extends CommunityState {}

// User Follow States
class UserFollowToggling extends CommunityState {
  final String userId;
  UserFollowToggling({required this.userId});
}

class UserFollowToggled extends CommunityState {
  final String userId;
  final bool isFollowing;
  final String message;

  UserFollowToggled({
    required this.userId,
    required this.isFollowing,
    required this.message,
  });
}

class UserFollowError extends CommunityState {
  final String userId;
  final String message;
  
  UserFollowError({
    required this.userId,
    required this.message,
  });
}
