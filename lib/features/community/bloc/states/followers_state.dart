import 'package:equatable/equatable.dart';
import '../../../../domain/community/entities/community_entities.dart';

abstract class FollowersState extends Equatable {
  const FollowersState();

  @override
  List<Object?> get props => [];
}

class FollowersInitial extends FollowersState {}

class FollowersListLoading extends FollowersState {}

class FollowersListLoaded extends FollowersState {
  final List<CommunityProfileEntity> users;
  final List<CommunityProfileEntity> filteredUsers;
  final bool hasMore;
  final int currentPage;
  final String? searchQuery;
  final bool isFollowers;

  const FollowersListLoaded({
    required this.users,
    required this.filteredUsers,
    required this.hasMore,
    required this.currentPage,
    this.searchQuery,
    required this.isFollowers,
  });

  FollowersListLoaded copyWith({
    List<CommunityProfileEntity>? users,
    List<CommunityProfileEntity>? filteredUsers,
    bool? hasMore,
    int? currentPage,
    String? searchQuery,
    bool? isFollowers,
  }) {
    return FollowersListLoaded(
      users: users ?? this.users,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      isFollowers: isFollowers ?? this.isFollowers,
    );
  }

  @override
  List<Object?> get props => [users, filteredUsers, hasMore, currentPage, searchQuery, isFollowers];
}

class FollowersListError extends FollowersState {
  final String message;

  const FollowersListError(this.message);

  @override
  List<Object?> get props => [message];
}

class FollowersListLoadingMore extends FollowersListLoaded {
  const FollowersListLoadingMore({
    required super.users,
    required super.filteredUsers,
    required super.hasMore,
    required super.currentPage,
    super.searchQuery,
    required super.isFollowers,
  });
}
