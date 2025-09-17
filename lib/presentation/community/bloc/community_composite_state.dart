import '../../../domain/community/entities/community_entities.dart';
import 'community_state.dart';

/// Composite state that manages multiple aspects of community functionality
/// This solves the state overwrite problem by maintaining separate state sections
class CommunityCompositeState extends CommunityState {
  final PostsState postsState;
  final CommentsState commentsState;
  final LikesState likesState;
  final UserProfileState userProfileState;
  final FollowState followState;
  final SearchState searchState;
  final CreatePostState createPostState;
  final BlockState blockState;

  CommunityCompositeState({
    required this.postsState,
    required this.commentsState,
    required this.likesState,
    required this.userProfileState,
    required this.followState,
    required this.searchState,
    required this.createPostState,
    required this.blockState,
  });

  /// Factory method to create initial state
  factory CommunityCompositeState.initial() {
    return CommunityCompositeState(
      postsState: PostsInitial(),
      commentsState: CommentsInitial(),
      likesState: LikesInitial(),
      userProfileState: UserProfileInitial(),
      followState: FollowInitial(),
      searchState: SearchInitial(),
      createPostState: CreatePostInitial(),
      blockState: BlockInitial(),
    );
  }

  /// Copy with method for immutable updates
  CommunityCompositeState copyWith({
    PostsState? postsState,
    CommentsState? commentsState,
    LikesState? likesState,
    UserProfileState? userProfileState,
    FollowState? followState,
    SearchState? searchState,
    CreatePostState? createPostState,
    BlockState? blockState,
  }) {
    return CommunityCompositeState(
      postsState: postsState ?? this.postsState,
      commentsState: commentsState ?? this.commentsState,
      likesState: likesState ?? this.likesState,
      userProfileState: userProfileState ?? this.userProfileState,
      followState: followState ?? this.followState,
      searchState: searchState ?? this.searchState,
      createPostState: createPostState ?? this.createPostState,
      blockState: blockState ?? this.blockState,
    );
  }
}

// Posts State Management
abstract class PostsState {}

class PostsInitial extends PostsState {}

class PostsLoading extends PostsState {}

class PostsLoaded extends PostsState {
  final List<PostEntity> posts;
  final bool hasMorePosts;
  final int currentPage;
  final bool isRefreshing;
  final bool isLoadingMore;

  PostsLoaded({
    required this.posts,
    required this.hasMorePosts,
    required this.currentPage,
    this.isRefreshing = false,
    this.isLoadingMore = false,
  });

  PostsLoaded copyWith({
    List<PostEntity>? posts,
    bool? hasMorePosts,
    int? currentPage,
    bool? isRefreshing,
    bool? isLoadingMore,
  }) {
    return PostsLoaded(
      posts: posts ?? this.posts,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      currentPage: currentPage ?? this.currentPage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class PostsError extends PostsState {
  final String message;
  final List<PostEntity>? cachedPosts;

  PostsError(this.message, {this.cachedPosts});
}

// Comments State Management
abstract class CommentsState {}

class CommentsInitial extends CommentsState {}

class CommentsLoading extends CommentsState {
  final String postId;
  CommentsLoading(this.postId);
}

class CommentsLoaded extends CommentsState {
  final String postId;
  final List<PostEntity> comments;
  final bool hasMoreComments;
  final int currentPage;
  final bool isLoadingMore;

  CommentsLoaded({
    required this.postId,
    required this.comments,
    required this.hasMoreComments,
    required this.currentPage,
    this.isLoadingMore = false,
  });

  CommentsLoaded copyWith({
    String? postId,
    List<PostEntity>? comments,
    bool? hasMoreComments,
    int? currentPage,
    bool? isLoadingMore,
  }) {
    return CommentsLoaded(
      postId: postId ?? this.postId,
      comments: comments ?? this.comments,
      hasMoreComments: hasMoreComments ?? this.hasMoreComments,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class CommentsError extends CommentsState {
  final String postId;
  final String message;
  CommentsError(this.postId, this.message);
}

// Likes State Management
abstract class LikesState {}

class LikesInitial extends LikesState {}

class LikeToggling extends LikesState {
  final String postId;
  final bool optimisticLikeStatus;
  final int optimisticLikeCount;

  LikeToggling({
    required this.postId,
    required this.optimisticLikeStatus,
    required this.optimisticLikeCount,
  });
}

class LikeToggled extends LikesState {
  final String postId;
  final bool isLiked;
  final int likeCount;

  LikeToggled({
    required this.postId,
    required this.isLiked,
    required this.likeCount,
  });
}

class LikeError extends LikesState {
  final String postId;
  final String message;
  final bool revertedLikeStatus;
  final int revertedLikeCount;

  LikeError({
    required this.postId,
    required this.message,
    required this.revertedLikeStatus,
    required this.revertedLikeCount,
  });
}

// User Profile State Management
abstract class UserProfileState {}

class UserProfileInitial extends UserProfileState {}

class UserProfileLoading extends UserProfileState {
  final String userId;
  UserProfileLoading(this.userId);
}

class UserProfileLoaded extends UserProfileState {
  final CommunityProfileEntity profile;
  UserProfileLoaded(this.profile);
}

class UserProfileError extends UserProfileState {
  final String userId;
  final String message;
  UserProfileError(this.userId, this.message);
}

// Follow State Management
abstract class FollowState {}

class FollowInitial extends FollowState {}

class FollowToggling extends FollowState {
  final String userId;
  final bool optimisticFollowStatus;

  FollowToggling({
    required this.userId,
    required this.optimisticFollowStatus,
  });
}

class FollowToggled extends FollowState {
  final String userId;
  final bool isFollowing;
  final String message;

  FollowToggled({
    required this.userId,
    required this.isFollowing,
    required this.message,
  });
}

class FollowError extends FollowState {
  final String userId;
  final String message;
  final bool revertedFollowStatus;

  FollowError({
    required this.userId,
    required this.message,
    required this.revertedFollowStatus,
  });
}

// Search State Management
abstract class SearchState {}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {
  final String query;
  SearchLoading(this.query);
}

class SearchLoaded extends SearchState {
  final String query;
  final List<UserSearchResultEntity> users;
  final bool hasMoreResults;

  SearchLoaded({
    required this.query,
    required this.users,
    required this.hasMoreResults,
  });
}

class SearchError extends SearchState {
  final String query;
  final String message;
  SearchError(this.query, this.message);
}

class SearchEmpty extends SearchState {}

// Create Post State Management
abstract class CreatePostState {}

class CreatePostInitial extends CreatePostState {}

class CreatePostLoading extends CreatePostState {}

class CreatePostSuccess extends CreatePostState {
  final PostEntity post;
  CreatePostSuccess(this.post);
}

class CreatePostError extends CreatePostState {
  final String message;
  CreatePostError(this.message);
}

// Block State Management
abstract class BlockState {}

class BlockInitial extends BlockState {}

class BlockToggling extends BlockState {
  final String userId;
  final bool optimisticBlockStatus;

  BlockToggling({
    required this.userId,
    required this.optimisticBlockStatus,
  });
}

class BlockToggled extends BlockState {
  final String userId;
  final bool isBlocked;
  final String message;

  BlockToggled({
    required this.userId,
    required this.isBlocked,
    required this.message,
  });
}

class BlockError extends BlockState {
  final String userId;
  final String message;
  final bool revertedBlockStatus;

  BlockError({
    required this.userId,
    required this.message,
    required this.revertedBlockStatus,
  });
}

class BlockedUsersLoading extends BlockState {}

class BlockedUsersLoaded extends BlockState {
  final List<Map<String, dynamic>> blockedUsers;
  final bool hasMore;
  final int currentPage;

  BlockedUsersLoaded({
    required this.blockedUsers,
    required this.hasMore,
    required this.currentPage,
  });
}