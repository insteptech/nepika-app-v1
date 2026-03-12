abstract class UserSearchEvent {}

class SearchUsers extends UserSearchEvent {
  final String token;
  final String query;

  SearchUsers({
    required this.token,
    required this.query,
  });
}

class ClearUserSearch extends UserSearchEvent {}

class SearchUsersV2 extends UserSearchEvent {
  final String token;
  final String query;
  final int page;
  final int pageSize;
  final bool isProfessional;

  SearchUsersV2({
    required this.token,
    required this.query,
    this.page = 1,
    this.pageSize = 10,
    this.isProfessional = false,
  });
}

class ToggleUserFollow extends UserSearchEvent {
  final String token;
  final String userId;
  final bool currentlyFollowing;

  ToggleUserFollow({
    required this.token,
    required this.userId,
    required this.currentlyFollowing,
  });
}