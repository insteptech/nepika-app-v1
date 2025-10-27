import 'package:equatable/equatable.dart';
import '../../../domain/blocked_users/entities/blocked_user_entities.dart';

abstract class BlockedUsersState extends Equatable {
  const BlockedUsersState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class BlockedUsersInitial extends BlockedUsersState {
  const BlockedUsersInitial();
}

/// Loading state
class BlockedUsersLoading extends BlockedUsersState {
  const BlockedUsersLoading();
}

/// Loaded state with blocked users data
class BlockedUsersLoaded extends BlockedUsersState {
  final List<BlockedUserEntity> users;
  final int total;
  final int currentPage;
  final int pageSize;
  final bool hasMore;
  final bool isLoadingMore;

  const BlockedUsersLoaded({
    required this.users,
    required this.total,
    required this.currentPage,
    required this.pageSize,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  BlockedUsersLoaded copyWith({
    List<BlockedUserEntity>? users,
    int? total,
    int? currentPage,
    int? pageSize,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return BlockedUsersLoaded(
      users: users ?? this.users,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [users, total, currentPage, pageSize, hasMore, isLoadingMore];
}

/// Empty state when no blocked users exist
class BlockedUsersEmpty extends BlockedUsersState {
  const BlockedUsersEmpty();
}

/// Error state
class BlockedUsersError extends BlockedUsersState {
  final String message;
  final bool isNetworkError;

  const BlockedUsersError({
    required this.message,
    this.isNetworkError = false,
  });

  @override
  List<Object?> get props => [message, isNetworkError];
}

/// State when unblocking a user
class UnblockingUser extends BlockedUsersState {
  final String userId;
  final List<BlockedUserEntity> currentUsers;

  const UnblockingUser({
    required this.userId,
    required this.currentUsers,
  });

  @override
  List<Object?> get props => [userId, currentUsers];
}

/// State when unblock operation succeeds
class UserUnblocked extends BlockedUsersState {
  final String userId;
  final String username;
  final List<BlockedUserEntity> updatedUsers;
  final int updatedTotal;

  const UserUnblocked({
    required this.userId,
    required this.username,
    required this.updatedUsers,
    required this.updatedTotal,
  });

  @override
  List<Object?> get props => [userId, username, updatedUsers, updatedTotal];
}

/// State when unblock operation fails
class UnblockUserFailed extends BlockedUsersState {
  final String userId;
  final String username;
  final String error;
  final List<BlockedUserEntity> currentUsers;

  const UnblockUserFailed({
    required this.userId,
    required this.username,
    required this.error,
    required this.currentUsers,
  });

  @override
  List<Object?> get props => [userId, username, error, currentUsers];
}