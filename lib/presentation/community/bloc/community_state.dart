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
