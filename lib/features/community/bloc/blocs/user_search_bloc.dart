import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/community/entities/community_entities.dart';
import '../../../../domain/community/repositories/community_repository.dart';
import '../events/user_search_event.dart';
import '../states/user_search_state.dart';

/// User Search BLoC responsible for user search and follow operations
/// Follows Single Responsibility Principle - only handles user search
class UserSearchBloc extends Bloc<UserSearchEvent, UserSearchState> {
  final CommunityRepository repository;

  // Follow/Unfollow debouncing
  final Map<String, Timer?> _followDebounceTimers = {};
  final Map<String, bool> _pendingFollowStates = {};
  final Map<String, bool> _currentFollowStates = {};

  UserSearchBloc({required this.repository}) : super(UserSearchInitial()) {
    on<SearchUsers>(_onSearchUsers);
    on<ClearUserSearch>(_onClearUserSearch);
    on<SearchUsersV2>(_onSearchUsersV2);
    on<ToggleUserFollow>(_onToggleUserFollow);
  }

  Future<void> _onSearchUsers(
    SearchUsers event,
    Emitter<UserSearchState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(UserSearchEmpty());
      return;
    }
    
    emit(UserSearchLoading());
    try {
      final data = await repository.searchUsers(
        token: event.token,
        query: event.query,
      );
      
      final users = data.users.map((user) => SearchUserEntity.fromJson(user)).toList();
      emit(UserSearchLoaded(users: users));
    } catch (e, stackTrace) {
      debugPrint('UserSearchBloc: Error in _onSearchUsers: $e');
      debugPrint('UserSearchBloc: Stack trace: $stackTrace');
      emit(UserSearchError(e.toString()));
    }
  }

  Future<void> _onClearUserSearch(
    ClearUserSearch event,
    Emitter<UserSearchState> emit,
  ) async {
    emit(UserSearchEmpty());
  }

  Future<void> _onSearchUsersV2(
    SearchUsersV2 event,
    Emitter<UserSearchState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(UserSearchV2Empty());
      return;
    }
    
    emit(UserSearchV2Loading(query: event.query));
    try {
      final response = await repository.searchUsersV2(
        token: event.token,
        query: event.query,
        page: event.page,
        pageSize: event.pageSize,
      );
      
      emit(UserSearchV2Loaded(
        response: response,
        users: response.users,
      ));
    } catch (e, stackTrace) {
      debugPrint('UserSearchBloc: Error in _onSearchUsersV2: $e');
      debugPrint('UserSearchBloc: Stack trace: $stackTrace');
      emit(UserSearchV2Error(
        query: event.query,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onToggleUserFollow(
    ToggleUserFollow event,
    Emitter<UserSearchState> emit,
  ) async {
    final userId = event.userId;
    final currentlyFollowing = event.currentlyFollowing;
    final newFollowingState = !currentlyFollowing;
    
    // Store current follow state for this user
    _currentFollowStates[userId] = newFollowingState;
    
    // Emit immediate UI update (optimistic)
    emit(UserFollowToggled(
      userId: userId,
      isFollowing: newFollowingState,
      message: newFollowingState ? 'Following' : 'Unfollowing',
    ));
    
    // Cancel any existing timer for this user
    _followDebounceTimers[userId]?.cancel();
    
    // Store the pending state
    _pendingFollowStates[userId] = newFollowingState;
    
    // Start new debounce timer
    _followDebounceTimers[userId] = Timer(const Duration(milliseconds: 800), () async {
      final finalState = _pendingFollowStates[userId] ?? newFollowingState;
      
      try {
        emit(UserFollowToggling(userId: userId));
        
        if (finalState) {
          // Follow user
          final response = await repository.followUser(
            token: event.token,
            userId: userId,
          );
          emit(UserFollowToggled(
            userId: userId,
            isFollowing: response.isFollowing,
            message: response.message,
          ));
        } else {
          // Unfollow user
          final response = await repository.unfollowUser(
            token: event.token,
            userId: userId,
          );
          emit(UserFollowToggled(
            userId: userId,
            isFollowing: response.isFollowing,
            message: response.message,
          ));
        }
        
        // Update the current state
        _currentFollowStates[userId] = finalState;
        
      } catch (e) {
        // Revert the UI state on error
        _currentFollowStates[userId] = currentlyFollowing;
        emit(UserFollowError(
          userId: userId,
          message: e.toString(),
        ));
        // Emit the reverted state
        emit(UserFollowToggled(
          userId: userId,
          isFollowing: currentlyFollowing,
          message: currentlyFollowing ? 'Following' : 'Follow',
        ));
      } finally {
        // Clean up
        _followDebounceTimers.remove(userId);
        _pendingFollowStates.remove(userId);
      }
    });
  }

  // Getters for accessing current state
  bool getCurrentFollowState(String userId) {
    return _currentFollowStates[userId] ?? false;
  }

  @override
  Future<void> close() {
    // Cancel all pending timers
    for (final timer in _followDebounceTimers.values) {
      timer?.cancel();
    }
    _followDebounceTimers.clear();
    _pendingFollowStates.clear();
    _currentFollowStates.clear();
    return super.close();
  }
}