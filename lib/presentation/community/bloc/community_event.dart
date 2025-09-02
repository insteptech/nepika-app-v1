import '../../../domain/community/entities/community_entities.dart';

abstract class CommunityEvent {}

class FetchCommunityPosts extends CommunityEvent {
  final String token;
  final int page;
  final int limit;

  FetchCommunityPosts({
    required this.token,
    this.page = 1,
    this.limit = 10,
  });
}

class LoadMoreCommunityPosts extends CommunityEvent {
  final String token;
  final int page;
  final int limit;

  LoadMoreCommunityPosts({
    required this.token,
    required this.page,
    this.limit = 10,
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
  final int limit;

  RefreshCommunityPosts({
    required this.token,
    this.limit = 10,
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
