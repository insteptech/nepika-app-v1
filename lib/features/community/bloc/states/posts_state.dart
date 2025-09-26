import '../../../../domain/community/entities/community_entities.dart';

// Simplified state management with clear hierarchies
abstract class PostsState {
  const PostsState();
}

class PostsInitial extends PostsState {
  const PostsInitial();
}

// Main Posts States - simplified hierarchy
class PostsLoading extends PostsState {
  final bool isRefresh;
  const PostsLoading({this.isRefresh = false});
}

class PostsLoaded extends PostsState {
  final List<PostEntity> posts;
  final bool hasMorePosts;
  final int currentPage;
  final bool isLoadingMore;

  const PostsLoaded({
    required this.posts,
    required this.hasMorePosts,
    required this.currentPage,
    this.isLoadingMore = false,
  });

  PostsLoaded copyWith({
    List<PostEntity>? posts,
    bool? hasMorePosts,
    int? currentPage,
    bool? isLoadingMore,
  }) {
    return PostsLoaded(
      posts: posts ?? this.posts,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class PostsError extends PostsState {
  final String message;
  final bool canRetry;
  
  const PostsError(this.message, {this.canRetry = true});
}

// Single Post States - simplified
class PostDetailState extends PostsState {
  const PostDetailState();
}

class PostDetailLoading extends PostDetailState {
  const PostDetailLoading();
}

class PostDetailLoaded extends PostDetailState {
  final PostDetailEntity post;
  const PostDetailLoaded({required this.post});
}

class PostDetailError extends PostDetailState {
  final String message;
  final bool canRetry;
  const PostDetailError(this.message, {this.canRetry = true});
}

// Post Management States - simplified
class PostOperationState extends PostsState {
  const PostOperationState();
}

class PostOperationLoading extends PostOperationState {
  final String operationType; // 'create', 'update', 'delete'
  const PostOperationLoading(this.operationType);
}

class PostOperationSuccess extends PostOperationState {
  final String operationType;
  final String message;
  final PostEntity? post;
  
  const PostOperationSuccess({
    required this.operationType,
    required this.message,
    this.post,
  });
}

class PostOperationError extends PostOperationState {
  final String operationType;
  final String message;
  final bool canRetry;
  
  const PostOperationError({
    required this.operationType,
    required this.message,
    this.canRetry = true,
  });
}

// Like States - optimized with minimal state changes
class PostLikeState extends PostsState {
  final String postId;
  final bool isLiked;
  final int likeCount;
  final bool isLoading;
  final String? error;
  
  const PostLikeState({
    required this.postId,
    required this.isLiked,
    required this.likeCount,
    this.isLoading = false,
    this.error,
  });
  
  PostLikeState copyWith({
    bool? isLiked,
    int? likeCount,
    bool? isLoading,
    String? error,
  }) {
    return PostLikeState(
      postId: postId,
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Comments States - simplified
class CommentsState extends PostsState {
  final String parentPostId;
  final List<PostEntity> comments;
  final bool hasMoreComments;
  final int currentPage;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  
  const CommentsState({
    required this.parentPostId,
    this.comments = const [],
    this.hasMoreComments = false,
    this.currentPage = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });
  
  CommentsState copyWith({
    List<PostEntity>? comments,
    bool? hasMoreComments,
    int? currentPage,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return CommentsState(
      parentPostId: parentPostId,
      comments: comments ?? this.comments,
      hasMoreComments: hasMoreComments ?? this.hasMoreComments,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error ?? this.error,
    );
  }
}