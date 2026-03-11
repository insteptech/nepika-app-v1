import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/community/entities/community_entities.dart';
import '../../../../domain/community/repositories/community_repository.dart';
import '../events/followers_event.dart';
import '../states/followers_state.dart';

class FollowersBloc extends Bloc<FollowersEvent, FollowersState> {
  final CommunityRepository repository;

  FollowersBloc({required this.repository}) : super(FollowersInitial()) {
    on<FetchFollowersList>(_onFetchFollowersList);
    on<LoadMoreFollowers>(_onLoadMoreFollowers);
    on<SearchFollowers>(_onSearchFollowers);
    on<ToggleFollowUserInList>(_onToggleFollowUserInList);
  }

  Future<void> _onFetchFollowersList(
    FetchFollowersList event,
    Emitter<FollowersState> emit,
  ) async {
    emit(FollowersListLoading());
    try {
      final UserListEntity data;
      if (event.isFollowers) {
        data = await repository.getFollowers(
          token: event.token,
          userId: event.userId,
          page: event.page,
          pageSize: event.pageSize,
        );
      } else {
        data = await repository.getFollowing(
          token: event.token,
          userId: event.userId,
          page: event.page,
          pageSize: event.pageSize,
        );
      }

      emit(FollowersListLoaded(
        users: data.users,
        filteredUsers: data.users,
        hasMore: data.hasMore,
        currentPage: data.page,
        isFollowers: event.isFollowers,
      ));
    } catch (e) {
      emit(FollowersListError(e.toString()));
    }
  }

  Future<void> _onLoadMoreFollowers(
    LoadMoreFollowers event,
    Emitter<FollowersState> emit,
  ) async {
    final currentState = state;
    if (currentState is FollowersListLoaded && currentState.hasMore) {
      emit(FollowersListLoadingMore(
        users: currentState.users,
        filteredUsers: currentState.filteredUsers,
        hasMore: currentState.hasMore,
        currentPage: currentState.currentPage,
        searchQuery: currentState.searchQuery,
        isFollowers: currentState.isFollowers,
      ));

      try {
        final UserListEntity data;
        final nextPage = currentState.currentPage + 1;
        
        if (event.isFollowers) {
          data = await repository.getFollowers(
            token: event.token,
            userId: event.userId,
            page: nextPage,
            pageSize: 20,
            searchQuery: currentState.searchQuery,
          );
        } else {
          data = await repository.getFollowing(
            token: event.token,
            userId: event.userId,
            page: nextPage,
            pageSize: 20,
            searchQuery: currentState.searchQuery,
          );
        }

        final updatedUsers = List<CommunityProfileEntity>.from(currentState.users);
        for (var user in data.users) {
          if (!updatedUsers.any((u) => u.userId == user.userId)) {
            updatedUsers.add(user);
          }
        }

        emit(FollowersListLoaded(
          users: updatedUsers,
          filteredUsers: updatedUsers, // Backend handles filtering now
          hasMore: data.hasMore,
          currentPage: data.page,
          searchQuery: currentState.searchQuery,
          isFollowers: event.isFollowers,
        ));
      } catch (e) {
        emit(FollowersListError(e.toString()));
      }
    }
  }

  Future<void> _onSearchFollowers(
    SearchFollowers event,
    Emitter<FollowersState> emit,
  ) async {
    final currentState = state;
      emit(FollowersListLoading());
      try {
        final UserListEntity data;
        if (event.isFollowers) {
          data = await repository.getFollowers(
            token: event.token,
            userId: event.userId,
            page: 1, // Reset page
            pageSize: 20,
            searchQuery: event.query,
          );
        } else {
          data = await repository.getFollowing(
            token: event.token,
            userId: event.userId,
            page: 1, // Reset page
            pageSize: 20,
            searchQuery: event.query,
          );
        }

        emit(FollowersListLoaded(
          users: data.users,
          filteredUsers: data.users, // Backend search already filters these
          hasMore: data.hasMore,
          currentPage: data.page,
          searchQuery: event.query,
          isFollowers: event.isFollowers,
        ));
      } catch (e) {
        emit(FollowersListError(e.toString()));
      }
    }

  Future<void> _onToggleFollowUserInList(
    ToggleFollowUserInList event,
    Emitter<FollowersState> emit,
  ) async {
    final currentState = state;
    if (currentState is FollowersListLoaded) {
      final updatedUsers = currentState.users.map((user) {
        if (user.userId == event.userId) {
          return user.copyWith(isFollowing: !event.currentFollowStatus);
        }
        return user;
      }).toList();

      final updatedFilteredUsers = currentState.filteredUsers.map((user) {
        if (user.userId == event.userId) {
          return user.copyWith(isFollowing: !event.currentFollowStatus);
        }
        return user;
      }).toList();

      emit(currentState.copyWith(
        users: updatedUsers,
        filteredUsers: updatedFilteredUsers,
      ));

      try {
        if (event.currentFollowStatus) {
          await repository.unfollowUser(token: event.token, userId: event.userId);
        } else {
          await repository.followUser(token: event.token, userId: event.userId);
        }
      } catch (e) {
        // Revert on error
        final revertedUsers = currentState.users.map((user) {
          if (user.userId == event.userId) {
            return user.copyWith(isFollowing: event.currentFollowStatus);
          }
          return user;
        }).toList();

        final revertedFilteredUsers = currentState.filteredUsers.map((user) {
          if (user.userId == event.userId) {
            return user.copyWith(isFollowing: event.currentFollowStatus);
          }
          return user;
        }).toList();

        emit(currentState.copyWith(
          users: revertedUsers,
          filteredUsers: revertedFilteredUsers,
        ));
      }
    }
  }
}
