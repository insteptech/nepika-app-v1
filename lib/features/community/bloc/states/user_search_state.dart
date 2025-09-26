import '../../../../domain/community/entities/community_entities.dart';

abstract class UserSearchState {}

class UserSearchInitial extends UserSearchState {}

// Legacy User Search States
class UserSearchLoading extends UserSearchState {}

class UserSearchLoaded extends UserSearchState {
  final List<SearchUserEntity> users;

  UserSearchLoaded({required this.users});
}

class UserSearchError extends UserSearchState {
  final String message;

  UserSearchError(this.message);
}

class UserSearchEmpty extends UserSearchState {}

// New User Search States (V2)
class UserSearchV2Loading extends UserSearchState {
  final String query;

  UserSearchV2Loading({required this.query});
}

class UserSearchV2Loaded extends UserSearchState {
  final UserSearchResponseEntity response;
  final List<UserSearchResultEntity> users;

  UserSearchV2Loaded({
    required this.response,
    required this.users,
  });
}

class UserSearchV2Error extends UserSearchState {
  final String query;
  final String message;
  
  UserSearchV2Error({
    required this.query,
    required this.message,
  });
}

class UserSearchV2Empty extends UserSearchState {}

// Follow States for Search Results
class UserFollowToggling extends UserSearchState {
  final String userId;

  UserFollowToggling({required this.userId});
}

class UserFollowToggled extends UserSearchState {
  final String userId;
  final bool isFollowing;
  final String message;

  UserFollowToggled({
    required this.userId,
    required this.isFollowing,
    required this.message,
  });
}

class UserFollowError extends UserSearchState {
  final String userId;
  final String message;
  
  UserFollowError({
    required this.userId,
    required this.message,
  });
}