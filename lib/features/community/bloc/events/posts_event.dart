import '../../../../domain/community/entities/community_entities.dart';

abstract class PostsEvent {}

// Post Fetching Events
class FetchCommunityPosts extends PostsEvent {
  final String token;
  final int page;
  final int pageSize;
  final String? userId;
  final bool? followingOnly;
  final bool bypassCache;

  FetchCommunityPosts({
    required this.token,
    this.page = 1,
    this.pageSize = 20,
    this.userId,
    this.followingOnly,
    this.bypassCache = true, // Default to true for home screen no-cache behavior
  });
}

class LoadMoreCommunityPosts extends PostsEvent {
  final String token;
  final int page;
  final int pageSize;
  final String? userId;
  final bool? followingOnly;
  final bool bypassCache;

  LoadMoreCommunityPosts({
    required this.token,
    required this.page,
    this.pageSize = 20,
    this.userId,
    this.followingOnly,
    this.bypassCache = true, // Default to true for home screen no-cache behavior
  });
}

class RefreshCommunityPosts extends PostsEvent {
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

class FetchSinglePost extends PostsEvent {
  final String token;
  final String postId;
  final int? cacheBuster; // Timestamp to prevent backend caching issues

  FetchSinglePost({
    required this.token,
    required this.postId,
    this.cacheBuster,
  });
}

// Post Management Events
class CreatePost extends PostsEvent {
  final String token;
  final CreatePostEntity postData;

  CreatePost({
    required this.token,
    required this.postData,
  });
}

class UpdatePost extends PostsEvent {
  final String token;
  final String postId;
  final String content;

  UpdatePost({
    required this.token,
    required this.postId,
    required this.content,
  });
}

class DeletePost extends PostsEvent {
  final String token;
  final String postId;

  DeletePost({
    required this.token,
    required this.postId,
  });
}

// Like/Unlike Events
class ToggleLikePost extends PostsEvent {
  final String token;
  final String postId;
  final bool currentLikeStatus;

  ToggleLikePost({
    required this.token,
    required this.postId,
    required this.currentLikeStatus,
  });
}

class LikePost extends PostsEvent {
  final String token;
  final String postId;

  LikePost({
    required this.token,
    required this.postId,
  });
}

class UnlikePost extends PostsEvent {
  final String token;
  final String postId;

  UnlikePost({
    required this.token,
    required this.postId,
  });
}

// Comments Events
class FetchPostComments extends PostsEvent {
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

class LoadMoreComments extends PostsEvent {
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

// Cache Management Events
class ClearAllCaches extends PostsEvent {
  ClearAllCaches();
}

class RefreshWithCacheClear extends PostsEvent {
  final String token;
  final int pageSize;
  final String? userId;
  final bool? followingOnly;

  RefreshWithCacheClear({
    required this.token,
    this.pageSize = 20,
    this.userId,
    this.followingOnly,
  });
}

// Sync Event for Like States
class SyncLikeStatesEvent extends PostsEvent {
  SyncLikeStatesEvent();
}