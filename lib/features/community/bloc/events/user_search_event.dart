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
  final String? query;
  final int page;
  final int pageSize;
  final bool isProfessional;
  final String? country;
  final List<String>? skinConditions;

  SearchUsersV2({
    required this.token,
    this.query,
    this.page = 1,
    this.pageSize = 10,
    this.isProfessional = false,
    this.country,
    this.skinConditions,
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