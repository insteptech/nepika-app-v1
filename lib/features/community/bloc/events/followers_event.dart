import 'package:equatable/equatable.dart';

abstract class FollowersEvent extends Equatable {
  const FollowersEvent();

  @override
  List<Object?> get props => [];
}

class FetchFollowersList extends FollowersEvent {
  final String token;
  final String userId;
  final bool isFollowers; // true for followers, false for following
  final int page;
  final int pageSize;

  const FetchFollowersList({
    required this.token,
    required this.userId,
    required this.isFollowers,
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [token, userId, isFollowers, page, pageSize];
}

class LoadMoreFollowers extends FollowersEvent {
  final String token;
  final String userId;
  final bool isFollowers;

  const LoadMoreFollowers({
    required this.token,
    required this.userId,
    required this.isFollowers,
  });

  @override
  List<Object?> get props => [token, userId, isFollowers];
}

class SearchFollowers extends FollowersEvent {
  final String token;
  final String userId;
  final bool isFollowers;
  final String query;

  const SearchFollowers({
    required this.token,
    required this.userId,
    required this.isFollowers,
    required this.query,
  });

  @override
  List<Object?> get props => [token, userId, isFollowers, query];
}

class ToggleFollowUserInList extends FollowersEvent {
  final String token;
  final String userId;
  final bool currentFollowStatus;

  const ToggleFollowUserInList({
    required this.token,
    required this.userId,
    required this.currentFollowStatus,
  });

  @override
  List<Object?> get props => [token, userId, currentFollowStatus];
}
