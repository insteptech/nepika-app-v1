import 'package:equatable/equatable.dart';

abstract class BlockedUsersEvent extends Equatable {
  const BlockedUsersEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch blocked users list
class FetchBlockedUsers extends BlockedUsersEvent {
  final String token;
  final int page;
  final int pageSize;
  final bool isRefresh;

  const FetchBlockedUsers({
    required this.token,
    this.page = 1,
    this.pageSize = 20,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [token, page, pageSize, isRefresh];
}

/// Event to load more blocked users (pagination)
class LoadMoreBlockedUsers extends BlockedUsersEvent {
  final String token;

  const LoadMoreBlockedUsers({required this.token});

  @override
  List<Object?> get props => [token];
}

/// Event to unblock a user
class UnblockUser extends BlockedUsersEvent {
  final String token;
  final String userId;
  final String username;

  const UnblockUser({
    required this.token,
    required this.userId,
    required this.username,
  });

  @override
  List<Object?> get props => [token, userId, username];
}

/// Event to refresh the blocked users list
class RefreshBlockedUsers extends BlockedUsersEvent {
  final String token;

  const RefreshBlockedUsers({required this.token});

  @override
  List<Object?> get props => [token];
}