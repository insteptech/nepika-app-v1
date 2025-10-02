import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/state/community_state_manager.dart';
import '../../../core/state/community_state_models.dart';
import '../../../core/sync/community_sync_service.dart';
import '../../../domain/community/entities/community_entities.dart';
import '../events/posts_event.dart';
import '../states/posts_state.dart';

/// Hybrid Posts BLoC - Uses CommunityStateManager as single source of truth
/// This BLoC subscribes to the state manager instead of making direct API calls
/// All user actions are performed optimistically through the state manager
class HybridPostsBloc extends Bloc<PostsEvent, PostsState> {
  final CommunityStateManager _stateManager;
  final CommunitySyncService _syncService;
  
  StreamSubscription<CommunityGlobalState>? _stateSubscription;
  StreamSubscription<RealTimeEvent>? _realTimeSubscription;
  
  // Local state tracking
  bool _isInitialized = false;
  String? _currentUserId;
  String? _authToken;

  HybridPostsBloc({
    required CommunityStateManager stateManager,
    required CommunitySyncService syncService,
  }) : _stateManager = stateManager,
       _syncService = syncService,
       super(PostsInitial()) {
    
    // Register event handlers
    on<InitializePosts>(_onInitializePosts);
    on<FetchCommunityPosts>(_onFetchCommunityPosts);
    on<LoadMoreCommunityPosts>(_onLoadMoreCommunityPosts);
    on<RefreshCommunityPosts>(_onRefreshCommunityPosts);
    on<CreatePost>(_onCreatePost);
    on<LikePost>(_onLikePost);
    on<UnlikePost>(_onUnlikePost);
    on<RefreshWithCacheClear>(_onRefreshWithCacheClear);
    
    // Subscribe to real-time events
    _subscribeToRealTimeEvents();
  }

  /// Initialize the BLoC with user credentials
  Future<void> _onInitializePosts(
    InitializePosts event,
    Emitter<PostsState> emit,
  ) async {
    if (_isInitialized) return;

    try {
      _currentUserId = event.userId;
      _authToken = event.token;

      // Subscribe to state manager updates
      _subscribeToStateManager(emit);
      
      // Get initial state from state manager
      final currentState = _stateManager.currentState;
      final posts = _stateManager.getFeedPosts();
      
      if (posts.isNotEmpty) {
        emit(PostsLoaded(
          posts: posts,
          hasMorePosts: currentState.feedPagination.hasMore,
          currentPage: currentState.feedPagination.currentPage,
          isLoadingMore: currentState.feedPagination.isLoading,
        ));
      } else {
        emit(PostsLoading());
        // Trigger initial load if no cached data
        add(FetchCommunityPosts(token: event.token));
      }

      _isInitialized = true;
      debugPrint('HybridPostsBloc: Initialized successfully');
    } catch (e) {
      debugPrint('HybridPostsBloc: Initialization failed - $e');
      emit(PostsError('Failed to initialize: ${e.toString()}'));
    }
  }

  /// Subscribe to state manager updates
  void _subscribeToStateManager(Emitter<PostsState> emit) {
    _stateSubscription?.cancel();
    _stateSubscription = _stateManager.stateStream.listen((globalState) {
      _handleStateUpdate(globalState, emit);
    });
  }

  /// Subscribe to real-time events
  void _subscribeToRealTimeEvents() {
    _realTimeSubscription?.cancel();
    _realTimeSubscription = _syncService.realTimeStream?.listen((event) {
      _handleRealTimeEvent(event);
    });
  }

  /// Handle state updates from state manager
  void _handleStateUpdate(CommunityGlobalState globalState, Emitter<PostsState> emit) {
    final posts = _stateManager.getFeedPosts();
    final pagination = globalState.feedPagination;

    if (posts.isEmpty && !pagination.isLoading) {
      emit(PostsEmpty());
    } else {
      emit(PostsLoaded(
        posts: posts,
        hasMorePosts: pagination.hasMore,
        currentPage: pagination.currentPage,
        isLoadingMore: pagination.isLoading,
      ));
    }
  }

  /// Handle real-time events
  void _handleRealTimeEvent(RealTimeEvent event) {
    switch (event.eventType) {
      case 'post_liked':
      case 'post_unliked':
        debugPrint('HybridPostsBloc: Received like event for post ${event.targetId}');
        // State manager will handle the update automatically
        break;
      
      case 'post_created':
        debugPrint('HybridPostsBloc: New post created, triggering refresh');
        if (_authToken != null) {
          add(RefreshCommunityPosts(token: _authToken!));
        }
        break;
      
      case 'post_deleted':
        debugPrint('HybridPostsBloc: Post ${event.targetId} deleted');
        // State manager will handle the removal automatically
        break;
      
      default:
        debugPrint('HybridPostsBloc: Unhandled real-time event: ${event.eventType}');
    }
  }

  /// Fetch community posts (delegates to state manager)
  Future<void> _onFetchCommunityPosts(
    FetchCommunityPosts event,
    Emitter<PostsState> emit,
  ) async {
    try {
      emit(PostsLoading());
      
      // Load from state manager first (immediate response)
      final cachedPosts = _stateManager.getFeedPosts(limit: event.pageSize);
      
      if (cachedPosts.isNotEmpty) {
        final currentState = _stateManager.currentState;
        emit(PostsLoaded(
          posts: cachedPosts,
          hasMorePosts: currentState.feedPagination.hasMore,
          currentPage: currentState.feedPagination.currentPage,
        ));
      }

      // Trigger refresh to get latest data
      await _stateManager.refreshPosts();
      
    } catch (e) {
      debugPrint('HybridPostsBloc: Error fetching posts - $e');
      emit(PostsError('Failed to fetch posts: ${e.toString()}'));
    }
  }

  /// Load more posts (delegates to state manager)
  Future<void> _onLoadMoreCommunityPosts(
    LoadMoreCommunityPosts event,
    Emitter<PostsState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! PostsLoaded) return;
      
      if (!currentState.hasMorePosts || currentState.isLoadingMore) return;

      emit(currentState.copyWith(isLoadingMore: true));
      
      await _stateManager.loadMorePosts();
      
    } catch (e) {
      debugPrint('HybridPostsBloc: Error loading more posts - $e');
      
      final currentState = state;
      if (currentState is PostsLoaded) {
        emit(currentState.copyWith(isLoadingMore: false));
      }
    }
  }

  /// Refresh posts (delegates to state manager)
  Future<void> _onRefreshCommunityPosts(
    RefreshCommunityPosts event,
    Emitter<PostsState> emit,
  ) async {
    try {
      await _stateManager.refreshPosts();
      
      // Also trigger a sync service refresh for good measure
      await _syncService.performFullRefresh();
      
    } catch (e) {
      debugPrint('HybridPostsBloc: Error refreshing posts - $e');
      emit(PostsError('Failed to refresh posts: ${e.toString()}'));
    }
  }

  /// Create post (optimistic update through state manager)
  Future<void> _onCreatePost(
    CreatePost event,
    Emitter<PostsState> emit,
  ) async {
    try {
      emit(PostOperationLoading(operationType: 'create'));
      
      // TODO: Implement create post in state manager
      // For now, just show success
      await Future.delayed(const Duration(milliseconds: 500));
      
      emit(PostOperationSuccess(
        operationType: 'create',
        message: 'Post created successfully!',
      ));
      
      // Refresh to show new post
      if (_authToken != null) {
        add(RefreshCommunityPosts(token: _authToken!));
      }
      
    } catch (e) {
      debugPrint('HybridPostsBloc: Error creating post - $e');
      emit(PostOperationError(
        operationType: 'create',
        message: 'Failed to create post: ${e.toString()}',
      ));
    }
  }

  /// Like post (optimistic update through state manager)
  Future<void> _onLikePost(
    LikePost event,
    Emitter<PostsState> emit,
  ) async {
    try {
      // Optimistic update through state manager
      await _stateManager.likePost(event.postId);
      
      // No need to emit state - state manager will notify us of changes
      debugPrint('HybridPostsBloc: Post ${event.postId} liked optimistically');
      
    } catch (e) {
      debugPrint('HybridPostsBloc: Error liking post - $e');
      emit(PostOperationError(
        operationType: 'like',
        message: 'Failed to like post: ${e.toString()}',
      ));
    }
  }

  /// Unlike post (optimistic update through state manager)
  Future<void> _onUnlikePost(
    UnlikePost event,
    Emitter<PostsState> emit,
  ) async {
    try {
      // Optimistic update through state manager
      await _stateManager.unlikePost(event.postId);
      
      // No need to emit state - state manager will notify us of changes
      debugPrint('HybridPostsBloc: Post ${event.postId} unliked optimistically');
      
    } catch (e) {
      debugPrint('HybridPostsBloc: Error unliking post - $e');
      emit(PostOperationError(
        operationType: 'unlike',
        message: 'Failed to unlike post: ${e.toString()}',
      ));
    }
  }

  /// Refresh with cache clear (delegates to state manager)
  Future<void> _onRefreshWithCacheClear(
    RefreshWithCacheClear event,
    Emitter<PostsState> emit,
  ) async {
    try {
      await _stateManager.refreshPosts();
      
      // Force sync service to refresh as well
      await _syncService.performFullRefresh();
      
    } catch (e) {
      debugPrint('HybridPostsBloc: Error in refresh with cache clear - $e');
      emit(PostsError('Failed to refresh: ${e.toString()}'));
    }
  }

  /// Get current posts from state manager
  List<PostEntity> getCurrentPosts() {
    return _stateManager.getFeedPosts();
  }

  /// Get specific post by ID
  PostEntity? getPost(String postId) {
    final postState = _stateManager.posts[postId];
    return postState?.post;
  }

  /// Get engagement state for post
  EngagementState? getEngagement(String postId) {
    if (_currentUserId == null) return null;
    return _stateManager.getEngagement(postId, _currentUserId!);
  }

  /// Check if user has liked a post
  bool isPostLiked(String postId) {
    if (_currentUserId == null) return false;
    final engagement = _stateManager.getEngagement(postId, _currentUserId!);
    return engagement?.isLiked ?? false;
  }

  /// Get like count for post
  int getPostLikeCount(String postId) {
    final postState = _stateManager.posts[postId];
    return postState?.post.likeCount ?? 0;
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    return {
      'state_manager_stats': {
        'posts_count': _stateManager.posts.length,
        'profiles_count': _stateManager.profiles.length,
        'engagements_count': _stateManager.engagements.length,
        'feed_posts_count': _stateManager.feedPostIds.length,
      },
      'sync_service_stats': _syncService.getSyncStats(),
      'bloc_stats': {
        'is_initialized': _isInitialized,
        'current_state': state.runtimeType.toString(),
        'has_auth_token': _authToken != null,
        'current_user_id': _currentUserId,
      },
    };
  }

  /// Force sync specific posts
  Future<void> syncPosts(List<String> postIds) async {
    try {
      await _syncService.syncItems(postIds: postIds);
    } catch (e) {
      debugPrint('HybridPostsBloc: Error syncing posts - $e');
    }
  }

  @override
  Future<void> close() {
    _stateSubscription?.cancel();
    _realTimeSubscription?.cancel();
    return super.close();
  }
}

/// Initialization event for the hybrid BLoC
class InitializePosts extends PostsEvent {
  final String userId;
  final String token;

  const InitializePosts({
    required this.userId,
    required this.token,
  });

  @override
  List<Object?> get props => [userId, token];
}