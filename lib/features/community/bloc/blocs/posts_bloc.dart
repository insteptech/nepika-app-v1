import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../domain/community/entities/community_entities.dart';
import '../../../../domain/community/repositories/community_repository.dart';
import '../../../../data/community/repositories/community_repository_impl.dart';
import '../../../../data/community/datasources/community_local_datasource.dart';
import '../events/posts_event.dart';
import '../states/posts_state.dart';
import '../../managers/like_state_manager.dart';

/// Optimized Posts BLoC with simplified state management
/// Reduced complexity and improved error handling
class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final CommunityRepository repository;
  final LikeStateManager likeStateManager;
  
  // Simplified state management
  List<PostEntity> _allPosts = [];
  int _currentPage = 1;
  bool _hasMorePosts = true;
  bool _isLoading = false;

  // Comments cache with simplified structure
  final Map<String, CommentsState> _commentsCache = {};

  // Stream subscription for like state changes
  StreamSubscription<LikeStateEvent>? _likeStateSubscription;
  
  // Request deduplication
  final Map<String, Completer<void>> _activeRequests = {};

  PostsBloc({
    required this.repository, 
    required this.likeStateManager,
  }) : super(const PostsInitial()) {
    // Post fetching events
    on<FetchCommunityPosts>(_onFetchCommunityPosts);
    on<LoadMoreCommunityPosts>(_onLoadMoreCommunityPosts);
    on<RefreshCommunityPosts>(_onRefreshCommunityPosts);
    on<FetchSinglePost>(_onFetchSinglePost);

    // Post management events
    on<CreatePost>(_onCreatePost);
    on<UpdatePost>(_onUpdatePost);
    on<DeletePost>(_onDeletePost);

    // Like events with debouncing
    on<ToggleLikePost>(_onToggleLikePost);
    on<LikePost>(_onLikePost);
    on<UnlikePost>(_onUnlikePost);

    // Comments events
    on<FetchPostComments>(_onFetchPostComments);
    on<LoadMoreComments>(_onLoadMoreComments);

    // Cache management events
    on<ClearAllCaches>(_onClearAllCaches);
    on<RefreshWithCacheClear>(_onRefreshWithCacheClear);
    
    // Sync events
    on<SyncLikeStatesEvent>(_onSyncLikeStates);
    
    // Subscribe to like state changes from LikeStateManager
    _likeStateSubscription = likeStateManager.stateStream.listen((event) {
      _handleLikeStateUpdate(event);
    });
  }

  // Handle like state updates from LikeStateManager
  void _handleLikeStateUpdate(LikeStateEvent event) {
    // Update the post in our cached list
    final postIndex = _allPosts.indexWhere((p) => p.id == event.postId);
    if (postIndex != -1) {
      final post = _allPosts[postIndex];
      final updatedPost = PostEntity(
        id: post.id,
        userId: post.userId,
        tenantId: post.tenantId,
        content: post.content,
        parentPostId: post.parentPostId,
        likeCount: event.state.likeCount,
        commentCount: post.commentCount,
        isEdited: post.isEdited,
        isDeleted: post.isDeleted,
        createdAt: post.createdAt,
        updatedAt: post.updatedAt,
        username: post.username,
        userAvatar: post.userAvatar,
        isLikedByUser: event.state.isLiked,
      );
      
      _allPosts[postIndex] = updatedPost;
      
      // UI updates are handled by LikeStateListener widgets
      // We just need to keep our cache in sync
      debugPrint('PostsBloc: INSTANTLY updated post ${event.postId} in cache - liked: ${event.state.isLiked}, count: ${event.state.likeCount} (${event.type})');
      
      // Update local cache immediately (don't await to avoid blocking)
      _updateLocalCache(updatedPost);
    }
  }
  
  // Update local cache with like changes
  void _updateLocalCache(PostEntity updatedPost) {
    // Start cache update immediately but don't block UI
    () async {
      try {
        final localDataSource = ServiceLocator.get<CommunityLocalDataSource>();
        await localDataSource.updateCachedPost(updatedPost);
        await localDataSource.cacheLikeStatus(
          updatedPost.id,
          updatedPost.isLikedByUser ?? false,
          updatedPost.likeCount,
        );
        debugPrint('PostsBloc: Local cache updated for post ${updatedPost.id}');
      } catch (e) {
        debugPrint('PostsBloc: Error updating local cache: $e');
      }
    }();
  }

  // Sync posts with current like states from LikeStateManager
  void _syncPostsWithLikeStates() {
    for (int i = 0; i < _allPosts.length; i++) {
      final post = _allPosts[i];
      final likeState = likeStateManager.getLikeState(post.id);
      
      if (likeState != null) {
        // Update post with current like state
        _allPosts[i] = PostEntity(
          id: post.id,
          userId: post.userId,
          tenantId: post.tenantId,
          content: post.content,
          parentPostId: post.parentPostId,
          likeCount: likeState.likeCount,
          commentCount: post.commentCount,
          isEdited: post.isEdited,
          isDeleted: post.isDeleted,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
          username: post.username,
          userAvatar: post.userAvatar,
          isLikedByUser: likeState.isLiked,
        );
        
        debugPrint('PostsBloc: Synced post ${post.id} with like state - liked: ${likeState.isLiked}, count: ${likeState.likeCount}');
      }
    }
  }

  // Initialize like states from server response data
  void _initializeLikeStatesFromPosts(List<PostEntity> posts) {
    final likeStateUpdates = <String, LikeStateData>{};
    
    for (final post in posts) {
      likeStateUpdates[post.id] = LikeStateData(
        isLiked: post.isLikedByUser,
        likeCount: post.likeCount,
      );
    }
    
    if (likeStateUpdates.isNotEmpty) {
      likeStateManager.bulkUpdate(likeStateUpdates);
      debugPrint('PostsBloc: Initialized like states for ${likeStateUpdates.length} posts from server response');
    }
  }

  // Optimized Post Fetching with request deduplication
  Future<void> _onFetchCommunityPosts(
    FetchCommunityPosts event,
    Emitter<PostsState> emit,
  ) async {
    final requestKey = 'fetch_posts_${event.page}';
    
    // Prevent duplicate requests
    if (_activeRequests.containsKey(requestKey)) {
      await _activeRequests[requestKey]!.future;
      return;
    }
    
    final completer = Completer<void>();
    _activeRequests[requestKey] = completer;
    
    try {
      if (!_isLoading) {
        _isLoading = true;
        emit(const PostsLoading());
      }
      
      _currentPage = event.page;
      final data = await repository.fetchCommunityPosts(
        token: event.token,
        page: event.page,
        pageSize: event.pageSize,
        userId: event.userId,
        followingOnly: event.followingOnly,
        bypassCache: event.bypassCache,
      );
      
      _allPosts = data.posts;
      _hasMorePosts = data.hasMore;
      _isLoading = false;
      
      // Initialize like states from server response data
      _initializeLikeStatesFromPosts(data.posts);
      
      // Sync with current like states to ensure consistency
      _syncPostsWithLikeStates();
      
      emit(PostsLoaded(
        posts: _allPosts,
        hasMorePosts: _hasMorePosts,
        currentPage: _currentPage,
      ));
      
      completer.complete();
    } catch (e, stackTrace) {
      _isLoading = false;
      debugPrint('PostsBloc: Error in _onFetchCommunityPosts: $e');
      emit(PostsError(e.toString()));
      completer.completeError(e);
    } finally {
      _activeRequests.remove(requestKey);
    }
  }

  Future<void> _onLoadMoreCommunityPosts(
    LoadMoreCommunityPosts event,
    Emitter<PostsState> emit,
  ) async {
    if (state is! PostsLoaded || !_hasMorePosts || _isLoading) return;
    
    final currentState = state as PostsLoaded;
    
    try {
      emit(currentState.copyWith(isLoadingMore: true));
      
      final data = await repository.fetchCommunityPosts(
        token: event.token,
        page: event.page,
        pageSize: event.pageSize,
        userId: event.userId,
        followingOnly: event.followingOnly,
        bypassCache: event.bypassCache,
      );
      
      _allPosts.addAll(data.posts);
      _currentPage = event.page;
      _hasMorePosts = data.hasMore;
      
      // Initialize like states from new posts
      _initializeLikeStatesFromPosts(data.posts);
      
      emit(PostsLoaded(
        posts: List.from(_allPosts), // Create new list for proper state comparison
        hasMorePosts: _hasMorePosts,
        currentPage: _currentPage,
        isLoadingMore: false,
      ));
    } catch (e, stackTrace) {
      debugPrint('PostsBloc: Error in _onLoadMoreCommunityPosts: $e');
      emit(currentState.copyWith(isLoadingMore: false));
      // Show error but keep existing posts
      emit(PostsError(e.toString()));
    }
  }

  Future<void> _onRefreshCommunityPosts(
    RefreshCommunityPosts event,
    Emitter<PostsState> emit,
  ) async {
    try {
      _currentPage = 1;
      final data = await repository.fetchCommunityPosts(
        token: event.token,
        page: 1,
        pageSize: event.pageSize,
        userId: event.userId,
        followingOnly: event.followingOnly,
      );
      
      _allPosts = data.posts;
      _hasMorePosts = data.hasMore;
      
      // Initialize like states from server response data
      _initializeLikeStatesFromPosts(data.posts);
      
      emit(PostsLoaded(
        posts: _allPosts,
        hasMorePosts: _hasMorePosts,
        currentPage: _currentPage,
      ));
    } catch (e, stackTrace) {
      debugPrint('PostsBloc: Error in _onRefreshCommunityPosts: $e');
      debugPrint('PostsBloc: Stack trace: $stackTrace');
      emit(PostsError(e.toString()));
    }
  }

  Future<void> _onFetchSinglePost(
    FetchSinglePost event,
    Emitter<PostsState> emit,
  ) async {
    debugPrint('PostsBloc: _onFetchSinglePost called for postId: ${event.postId}');
    debugPrint('PostsBloc: Current cache has ${_allPosts.length} posts');
    
    final requestKey = 'fetch_single_${event.postId}';
    
    // Check cache first
    PostEntity? cachedPost;
    try {
      for (final post in _allPosts) {
        if (post.id == event.postId) {
          cachedPost = post;
          break;
        }
      }
      debugPrint('PostsBloc: Cache search completed. Found: ${cachedPost != null}');
    } catch (e) {
      debugPrint('PostsBloc: Error during cache search: $e');
      cachedPost = null;
    }
    
    if (cachedPost != null) {
      debugPrint('PostsBloc: Found cached post ${cachedPost.id}, emitting PostDetailLoaded');
      final postDetail = _convertToPostDetail(cachedPost);
      emit(PostDetailLoaded(post: postDetail));
      debugPrint('PostsBloc: PostDetailLoaded state emitted for post ${postDetail.id}');
      return;
    } else {
      debugPrint('PostsBloc: No cached post found for ${event.postId}, will fetch from API');
      // Log all cached post IDs for debugging
      final cachedIds = _allPosts.map((p) => p.id).toList();
      debugPrint('PostsBloc: Available cached post IDs: $cachedIds');
    }
    
    // Prevent duplicate requests
    if (_activeRequests.containsKey(requestKey)) {
      await _activeRequests[requestKey]!.future;
      return;
    }
    
    final completer = Completer<void>();
    _activeRequests[requestKey] = completer;
    
    try {
      emit(const PostDetailLoading());
      
      final post = await repository.fetchSinglePost(
        token: event.token,
        postId: event.postId,
        cacheBuster: event.cacheBuster,
      );
      
      final postDetail = _convertToPostDetail(post);
      emit(PostDetailLoaded(post: postDetail));
      
      completer.complete();
    } catch (e, stackTrace) {
      debugPrint('PostsBloc: Error in _onFetchSinglePost: $e');
      emit(PostDetailError(e.toString()));
      completer.completeError(e);
    } finally {
      _activeRequests.remove(requestKey);
    }
  }
  
  PostDetailEntity _convertToPostDetail(PostEntity post) {
    debugPrint('PostsBloc: Converting post ${post.id} to PostDetailEntity');
    try {
      return PostDetailEntity(
      id: post.id,
      userId: post.userId,
      tenantId: post.tenantId,
      content: post.content,
      parentPostId: post.parentPostId,
      likeCount: post.likeCount,
      commentCount: post.commentCount,
      isEdited: post.isEdited,
      isDeleted: post.isDeleted,
      createdAt: post.createdAt,
      updatedAt: post.updatedAt ?? post.createdAt,
      author: AuthorEntity(
        id: post.userId,
        fullName: post.username,
        avatarUrl: post.userAvatar ?? '',
      ),
        likes: [],
        comments: [],
        isLikedByUser: post.isLikedByUser,
      );
    } catch (e) {
      debugPrint('PostsBloc: Error converting post to PostDetailEntity: $e');
      rethrow;
    }
  }

  // Optimized Post Management
  Future<void> _onCreatePost(
    CreatePost event,
    Emitter<PostsState> emit,
  ) async {
    try {
      emit(const PostOperationLoading('create'));
      
      final newPost = await repository.createPost(
        token: event.token,
        postData: event.postData,
      );
      
      // Add to local cache instead of full refresh
      if (event.postData.parentPostId == null) {
        // Main post - add to beginning
        _allPosts.insert(0, newPost);
        
        // Update posts state immediately to reflect new post
        emit(PostsLoaded(
          posts: List.from(_allPosts),
          hasMorePosts: _hasMorePosts,
          currentPage: _currentPage,
          isLoadingMore: false,
        ));
      } else {
        // Comment - update comments cache
        final parentId = event.postData.parentPostId!;
        if (_commentsCache.containsKey(parentId)) {
          final currentComments = _commentsCache[parentId]!;
          final updatedComments = [newPost, ...currentComments.comments];
          _commentsCache[parentId] = currentComments.copyWith(
            comments: updatedComments,
          );
          emit(_commentsCache[parentId]!);
        }
      }
      
      emit(const PostOperationSuccess(
        operationType: 'create',
        message: 'Post created successfully',
      ));
      
      // Update main posts if needed
      if (state is PostsLoaded && event.postData.parentPostId == null) {
        final currentState = state as PostsLoaded;
        emit(currentState.copyWith(posts: List.from(_allPosts)));
      }
    } catch (e, stackTrace) {
      debugPrint('PostsBloc: Error in _onCreatePost: $e');
      emit(PostOperationError(
        operationType: 'create',
        message: e.toString(),
      ));
    }
  }
  
  Future<void> _onUpdatePost(
    UpdatePost event,
    Emitter<PostsState> emit,
  ) async {
    try {
      emit(const PostOperationLoading('update'));
      
      final updatedPost = await repository.updatePost(
        token: event.token,
        postId: event.postId,
        content: event.content,
      );
      
      // Update local cache
      final postIndex = _allPosts.indexWhere((p) => p.id == event.postId);
      if (postIndex != -1) {
        _allPosts[postIndex] = updatedPost;
        
        // Update posts state if currently loaded
        if (state is PostsLoaded) {
          final currentState = state as PostsLoaded;
          emit(currentState.copyWith(posts: List.from(_allPosts)));
        }
      }
      
      emit(PostOperationSuccess(
        operationType: 'update',
        message: 'Post updated successfully',
        post: updatedPost,
      ));
    } catch (e) {
      debugPrint('PostsBloc: Error in _onUpdatePost: $e');
      emit(PostOperationError(
        operationType: 'update',
        message: e.toString(),
      ));
    }
  }
  
  Future<void> _onDeletePost(
    DeletePost event,
    Emitter<PostsState> emit,
  ) async {
    try {
      emit(const PostOperationLoading('delete'));
      
      await repository.deletePost(
        token: event.token,
        postId: event.postId,
      );
      
      // Remove from local cache
      _allPosts.removeWhere((post) => post.id == event.postId);
      
      // Update posts state if currently loaded
      if (state is PostsLoaded) {
        final currentState = state as PostsLoaded;
        emit(currentState.copyWith(posts: List.from(_allPosts)));
      }
      
      // Remove from comments cache
      _commentsCache.remove(event.postId);
      
      emit(const PostOperationSuccess(
        operationType: 'delete',
        message: 'Post deleted successfully',
      ));
    } catch (e) {
      debugPrint('PostsBloc: Error in _onDeletePost: $e');
      emit(PostOperationError(
        operationType: 'delete',
        message: e.toString(),
      ));
    }
  }


  // Delegate like handling to LikeStateManager
  Future<void> _onToggleLikePost(
    ToggleLikePost event,
    Emitter<PostsState> emit,
  ) async {
    // Get current like count from our posts
    final currentPost = _allPosts.cast<PostEntity?>().firstWhere(
      (post) => post?.id == event.postId,
      orElse: () => null,
    );
    
    if (currentPost == null) return;
    
    // Delegate to LikeStateManager
    await likeStateManager.toggleLike(
      postId: event.postId,
      currentLikeStatus: event.currentLikeStatus,
      currentLikeCount: currentPost.likeCount,
      onError: (error) {
        debugPrint('PostsBloc: Like toggle error: $error');
      },
    );
  }
  

  Future<void> _onLikePost(
    LikePost event,
    Emitter<PostsState> emit,
  ) async {
    final postId = event.postId;
    
    // Get current post state
    final currentPost = _allPosts.cast<PostEntity?>().firstWhere(
      (post) => post?.id == postId,
      orElse: () => null,
    );
    
    if (currentPost == null) return;
    
    // Delegate to LikeStateManager only if not already liked
    if (!(currentPost.isLikedByUser ?? false)) {
      await likeStateManager.toggleLike(
        postId: postId,
        currentLikeStatus: false,
        currentLikeCount: currentPost.likeCount,
        onError: (error) {
          debugPrint('PostsBloc: Like error: $error');
        },
      );
    }
  }

  Future<void> _onUnlikePost(
    UnlikePost event,
    Emitter<PostsState> emit,
  ) async {
    final postId = event.postId;
    
    // Get current post state
    final currentPost = _allPosts.cast<PostEntity?>().firstWhere(
      (post) => post?.id == postId,
      orElse: () => null,
    );
    
    if (currentPost == null) return;
    
    // Delegate to LikeStateManager only if currently liked
    if (currentPost.isLikedByUser ?? false) {
      await likeStateManager.toggleLike(
        postId: postId,
        currentLikeStatus: true,
        currentLikeCount: currentPost.likeCount,
        onError: (error) {
          debugPrint('PostsBloc: Unlike error: $error');
        },
      );
    }
  }


  // Optimized Comments Handlers
  Future<void> _onFetchPostComments(
    FetchPostComments event,
    Emitter<PostsState> emit,
  ) async {
    // Check cache first
    if (_commentsCache.containsKey(event.postId) && event.page == 1) {
      emit(_commentsCache[event.postId]!);
      return;
    }
    
    try {
      final currentState = _commentsCache[event.postId] ?? CommentsState(
        parentPostId: event.postId,
        isLoading: true,
      );
      
      emit(currentState.copyWith(isLoading: true));
      
      final data = await repository.getPostComments(
        token: event.token,
        postId: event.postId,
        page: event.page,
        pageSize: event.pageSize,
      );
      
      final newState = CommentsState(
        parentPostId: event.postId,
        comments: data.comments,
        hasMoreComments: data.hasMore,
        currentPage: event.page,
        isLoading: false,
      );
      
      _commentsCache[event.postId] = newState;
      emit(newState);
    } catch (e, stackTrace) {
      debugPrint('PostsBloc: Error in _onFetchPostComments: $e');
      final errorState = _commentsCache[event.postId]?.copyWith(
        isLoading: false,
        error: e.toString(),
      ) ?? CommentsState(
        parentPostId: event.postId,
        isLoading: false,
        error: e.toString(),
      );
      emit(errorState);
    }
  }

  Future<void> _onLoadMoreComments(
    LoadMoreComments event,
    Emitter<PostsState> emit,
  ) async {
    final currentState = _commentsCache[event.postId];
    if (currentState == null || !currentState.hasMoreComments || currentState.isLoadingMore) {
      return;
    }
    
    try {
      emit(currentState.copyWith(isLoadingMore: true));
      
      final data = await repository.getPostComments(
        token: event.token,
        postId: event.postId,
        page: event.page,
        pageSize: event.pageSize,
      );
      
      final updatedComments = [...currentState.comments, ...data.comments];
      
      final newState = currentState.copyWith(
        comments: updatedComments,
        hasMoreComments: data.hasMore,
        currentPage: event.page,
        isLoadingMore: false,
      );
      
      _commentsCache[event.postId] = newState;
      emit(newState);
    } catch (e, stackTrace) {
      debugPrint('PostsBloc: Error in _onLoadMoreComments: $e');
      emit(currentState.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      ));
    }
  }

  // Cache Management Event Handlers
  Future<void> _onClearAllCaches(ClearAllCaches event, Emitter<PostsState> emit) async {
    try {
      debugPrint('PostsBloc: Clearing all caches');
      
      // Clear repository caches
      if (repository is CommunityRepositoryImpl) {
        (repository as dynamic).clearAllCaches();
      }
      
      // Clear local data source cache
      try {
        final localDataSource = ServiceLocator.get<CommunityLocalDataSource>();
        await localDataSource.clearAllCache();
      } catch (e) {
        debugPrint('PostsBloc: Error clearing local cache: $e');
      }
      
      // Clear BLoC internal caches
      _allPosts.clear();
      _commentsCache.clear();
      _activeRequests.clear();
      _currentPage = 1;
      _hasMorePosts = true;
      
      emit(const PostsInitial());
      debugPrint('PostsBloc: All caches cleared successfully');
      
    } catch (e) {
      debugPrint('PostsBloc: Error clearing caches: $e');
      emit(PostsError('Failed to clear caches: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshWithCacheClear(RefreshWithCacheClear event, Emitter<PostsState> emit) async {
    try {
      debugPrint('PostsBloc: Refreshing with cache clear');
      
      // First clear all caches
      await _onClearAllCaches(ClearAllCaches(), emit);
      
      // Then fetch fresh data
      final fetchEvent = FetchCommunityPosts(
        token: event.token,
        page: 1,
        pageSize: event.pageSize,
        userId: event.userId,
        followingOnly: event.followingOnly,
      );
      
      await _onFetchCommunityPosts(fetchEvent, emit);
      
    } catch (e) {
      debugPrint('PostsBloc: Error in refresh with cache clear: $e');
      emit(PostsError('Failed to refresh: ${e.toString()}'));
    }
  }

  // Sync like states after navigation from other screens
  Future<void> _onSyncLikeStates(SyncLikeStatesEvent event, Emitter<PostsState> emit) async {
    try {
      debugPrint('PostsBloc: Syncing like states after navigation');
      
      // Sync current posts with like state manager
      _syncPostsWithLikeStates();
      
      // Update local cache with current states
      for (final post in _allPosts) {
        _updateLocalCache(post);
      }
      
      // Re-emit current state to trigger UI updates
      if (state is PostsLoaded) {
        final currentState = state as PostsLoaded;
        emit(PostsLoaded(
          posts: List.from(_allPosts),
          hasMorePosts: currentState.hasMorePosts,
          currentPage: currentState.currentPage,
          isLoadingMore: currentState.isLoadingMore,
        ));
      }
      
      debugPrint('PostsBloc: Like states synchronized successfully');
    } catch (e) {
      debugPrint('PostsBloc: Error syncing like states: $e');
    }
  }

  @override
  Future<void> close() {
    // Cancel like state subscription
    _likeStateSubscription?.cancel();
    
    // Cancel active requests
    for (final completer in _activeRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError('BLoC closed');
      }
    }
    
    // Clear all caches
    _commentsCache.clear();
    _activeRequests.clear();
    _allPosts.clear();
    
    return super.close();
  }
  
  // Public getters for cached data
  CommentsState? getCommentsState(String postId) => _commentsCache[postId];
  List<PostEntity> get currentPosts => List.unmodifiable(_allPosts);
  bool get isLoadingPosts => _isLoading;
}