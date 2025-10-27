import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/blocked_users/entities/blocked_user_entities.dart';
import '../../../domain/blocked_users/repositories/blocked_users_repository.dart';
import 'blocked_users_event.dart';
import 'blocked_users_state.dart';

class BlockedUsersBloc extends Bloc<BlockedUsersEvent, BlockedUsersState> {
  final BlockedUsersRepository repository;

  // State management
  List<BlockedUserEntity> _allUsers = [];
  int _currentPage = 1;
  int _totalUsers = 0;
  bool _hasMore = false;
  int _pageSize = 20;

  BlockedUsersBloc({required this.repository}) : super(const BlockedUsersInitial()) {
    debugPrint('🔍 BlockedUsersBloc: Constructor called with repository: $repository');
    // Register event handlers
    on<FetchBlockedUsers>(_onFetchBlockedUsers);
    on<LoadMoreBlockedUsers>(_onLoadMoreBlockedUsers);
    on<UnblockUser>(_onUnblockUser);
    on<RefreshBlockedUsers>(_onRefreshBlockedUsers);
    debugPrint('🔍 BlockedUsersBloc: Event handlers registered successfully');
  }

  Future<void> _onFetchBlockedUsers(
    FetchBlockedUsers event,
    Emitter<BlockedUsersState> emit,
  ) async {
    try {
      debugPrint('🔍 BlockedUsersBloc: _onFetchBlockedUsers called with page: ${event.page}, token: ${event.token.substring(0, 10)}...');
      
      // If it's a refresh or first load, show loading
      if (event.isRefresh || event.page == 1) {
        debugPrint('🔍 BlockedUsersBloc: Emitting loading state...');
        emit(const BlockedUsersLoading());
        _currentPage = 1;
        _allUsers.clear();
      }

      final response = await repository.getBlockedUsers(
        token: event.token,
        page: event.page,
        pageSize: event.pageSize,
      );

      debugPrint('BlockedUsersBloc: Received ${response.users.length} users, total: ${response.total}');

      // Update state management
      if (event.page == 1) {
        _allUsers = response.users;
      } else {
        _allUsers.addAll(response.users);
      }

      _currentPage = response.page;
      _totalUsers = response.total;
      _hasMore = response.hasMore;
      _pageSize = response.pageSize;

      if (_allUsers.isEmpty) {
        emit(const BlockedUsersEmpty());
      } else {
        emit(BlockedUsersLoaded(
          users: List.from(_allUsers),
          total: _totalUsers,
          currentPage: _currentPage,
          pageSize: _pageSize,
          hasMore: _hasMore,
        ));
      }
    } catch (e) {
      debugPrint('BlockedUsersBloc: Error fetching blocked users: $e');
      
      final isNetworkError = e.toString().contains('SocketException') || 
                             e.toString().contains('TimeoutException') ||
                             e.toString().contains('No address associated with hostname');
      
      emit(BlockedUsersError(
        message: isNetworkError 
            ? 'Network error. Please check your connection and try again.'
            : 'Failed to load blocked users. Please try again.',
        isNetworkError: isNetworkError,
      ));
    }
  }

  Future<void> _onLoadMoreBlockedUsers(
    LoadMoreBlockedUsers event,
    Emitter<BlockedUsersState> emit,
  ) async {
    // Only load more if we have more data and we're not already loading
    if (!_hasMore || state is UnblockingUser) return;

    try {
      debugPrint('BlockedUsersBloc: Loading more blocked users - page: ${_currentPage + 1}');

      // Emit loading more state
      if (state is BlockedUsersLoaded) {
        emit((state as BlockedUsersLoaded).copyWith(isLoadingMore: true));
      }

      final response = await repository.getBlockedUsers(
        token: event.token,
        page: _currentPage + 1,
        pageSize: _pageSize,
      );

      // Add new users to existing list
      _allUsers.addAll(response.users);
      _currentPage = response.page;
      _hasMore = response.hasMore;

      emit(BlockedUsersLoaded(
        users: List.from(_allUsers),
        total: _totalUsers,
        currentPage: _currentPage,
        pageSize: _pageSize,
        hasMore: _hasMore,
        isLoadingMore: false,
      ));

      debugPrint('BlockedUsersBloc: Loaded ${response.users.length} more users. Total: ${_allUsers.length}');
    } catch (e) {
      debugPrint('BlockedUsersBloc: Error loading more blocked users: $e');
      
      // Emit error but keep existing data
      if (state is BlockedUsersLoaded) {
        emit((state as BlockedUsersLoaded).copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> _onUnblockUser(
    UnblockUser event,
    Emitter<BlockedUsersState> emit,
  ) async {
    try {
      debugPrint('BlockedUsersBloc: Unblocking user: ${event.username} (${event.userId})');

      // Emit unblocking state
      emit(UnblockingUser(
        userId: event.userId,
        currentUsers: List.from(_allUsers),
      ));

      final success = await repository.unblockUser(
        token: event.token,
        userId: event.userId,
      );

      if (success) {
        // Remove user from local list
        _allUsers.removeWhere((user) => user.userId == event.userId);
        _totalUsers = _totalUsers > 0 ? _totalUsers - 1 : 0;

        debugPrint('BlockedUsersBloc: Successfully unblocked ${event.username}');

        // Emit success state
        emit(UserUnblocked(
          userId: event.userId,
          username: event.username,
          updatedUsers: List.from(_allUsers),
          updatedTotal: _totalUsers,
        ));

        // Check if list is now empty
        if (_allUsers.isEmpty) {
          emit(const BlockedUsersEmpty());
        } else {
          emit(BlockedUsersLoaded(
            users: List.from(_allUsers),
            total: _totalUsers,
            currentPage: _currentPage,
            pageSize: _pageSize,
            hasMore: _hasMore,
          ));
        }
      } else {
        debugPrint('BlockedUsersBloc: Failed to unblock ${event.username}');
        
        emit(UnblockUserFailed(
          userId: event.userId,
          username: event.username,
          error: 'Failed to unblock user. Please try again.',
          currentUsers: List.from(_allUsers),
        ));

        // Return to loaded state
        emit(BlockedUsersLoaded(
          users: List.from(_allUsers),
          total: _totalUsers,
          currentPage: _currentPage,
          pageSize: _pageSize,
          hasMore: _hasMore,
        ));
      }
    } catch (e) {
      debugPrint('BlockedUsersBloc: Error unblocking user: $e');
      
      emit(UnblockUserFailed(
        userId: event.userId,
        username: event.username,
        error: 'An error occurred while unblocking. Please try again.',
        currentUsers: List.from(_allUsers),
      ));

      // Return to loaded state
      emit(BlockedUsersLoaded(
        users: List.from(_allUsers),
        total: _totalUsers,
        currentPage: _currentPage,
        pageSize: _pageSize,
        hasMore: _hasMore,
      ));
    }
  }

  Future<void> _onRefreshBlockedUsers(
    RefreshBlockedUsers event,
    Emitter<BlockedUsersState> emit,
  ) async {
    debugPrint('BlockedUsersBloc: Refreshing blocked users');
    
    // Reset pagination and fetch first page
    _currentPage = 1;
    _allUsers.clear();
    
    add(FetchBlockedUsers(
      token: event.token,
      page: 1,
      pageSize: _pageSize,
      isRefresh: true,
    ));
  }
}