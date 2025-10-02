import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/community_database.dart';
import 'community_state_models.dart';
import '../../domain/community/entities/community_entities.dart';
import '../../domain/community/repositories/community_repository.dart';

/// L1 RAM State Manager - Centralized in-memory state for community features
/// This is the single source of truth for all community data in the app
/// All BLoCs subscribe to this state instead of fetching independently
class CommunityStateManager {
  static final CommunityStateManager _instance = CommunityStateManager._internal();
  factory CommunityStateManager() => _instance;
  CommunityStateManager._internal();

  /// Global state
  CommunityGlobalState _state = CommunityGlobalState(
    feedPagination: PaginationState(lastFetch: DateTime.now()),
    lastGlobalSync: DateTime.now(),
  );

  /// State stream for reactive updates
  final StreamController<CommunityGlobalState> _stateController = StreamController<CommunityGlobalState>.broadcast();

  /// Individual entity streams for fine-grained subscriptions
  final StreamController<Map<String, CommunityPostState>> _postsController = StreamController<Map<String, CommunityPostState>>.broadcast();
  final StreamController<Map<String, CommunityProfileState>> _profilesController = StreamController<Map<String, CommunityProfileState>>.broadcast();
  final StreamController<Map<String, EngagementState>> _engagementsController = StreamController<Map<String, EngagementState>>.broadcast();
  final StreamController<Map<String, SocialRelationshipState>> _relationshipsController = StreamController<Map<String, SocialRelationshipState>>.broadcast();
  final StreamController<List<String>> _feedController = StreamController<List<String>>.broadcast();

  /// Dependencies
  final CommunityDatabase _database = CommunityDatabase();
  CommunityRepository? _repository;
  String? _currentUserId;
  String? _authToken;

  /// Background sync control
  Timer? _backgroundSyncTimer;
  Timer? _actionProcessingTimer;
  bool _isInitialized = false;
  bool _isSyncing = false;

  /// Configuration
  static const Duration _backgroundSyncInterval = Duration(minutes: 5);
  static const Duration _actionProcessingInterval = Duration(seconds: 10);
  static const int _maxRetryAttempts = 3;

  /// Public streams
  Stream<CommunityGlobalState> get stateStream => _stateController.stream;
  Stream<Map<String, CommunityPostState>> get postsStream => _postsController.stream;
  Stream<Map<String, CommunityProfileState>> get profilesStream => _profilesController.stream;
  Stream<Map<String, EngagementState>> get engagementsStream => _engagementsController.stream;
  Stream<Map<String, SocialRelationshipState>> get relationshipsStream => _relationshipsController.stream;
  Stream<List<String>> get feedStream => _feedController.stream;

  /// Current state getters
  CommunityGlobalState get currentState => _state;
  Map<String, CommunityPostState> get posts => _state.posts;
  Map<String, CommunityProfileState> get profiles => _state.profiles;
  Map<String, EngagementState> get engagements => _state.engagements;
  Map<String, SocialRelationshipState> get relationships => _state.relationships;
  List<String> get feedPostIds => _state.feedPostIds;

  /// Initialize the state manager
  Future<void> initialize({
    required String userId,
    required String authToken,
    CommunityRepository? repository,
  }) async {
    if (_isInitialized) return;

    try {
      _currentUserId = userId;
      _authToken = authToken;
      _repository = repository;

      // Initialize database
      await _database.initialize();

      // Load cached state from database
      await _loadStateFromDatabase();

      // Start background processes
      _startBackgroundSync();
      _startActionProcessing();

      _isInitialized = true;
      debugPrint('CommunityStateManager: Initialized successfully for user $userId');

      // Trigger initial sync if we have minimal data
      if (_state.posts.isEmpty) {
        await _performInitialSync();
      }
    } catch (e) {
      debugPrint('CommunityStateManager: Failed to initialize - $e');
      rethrow;
    }
  }

  /// Load state from database on app startup
  Future<void> _loadStateFromDatabase() async {
    try {
      // Load all cached data in parallel
      final results = await Future.wait([
        _database.loadPosts(limit: 100),
        _database.loadProfiles(),
        _database.loadEngagements(),
        _database.loadSocialRelationships(),
        _database.loadFeedOrder(),
        _database.loadPendingActions(),
      ]);

      final cachedPosts = results[0] as List<CommunityPostState>;
      final cachedProfiles = results[1] as List<CommunityProfileState>;
      final cachedEngagements = results[2] as List<EngagementState>;
      final cachedRelationships = results[3] as List<SocialRelationshipState>;
      final cachedFeedOrder = results[4] as List<String>;
      final pendingActions = results[5] as List<CommunityAction>;

      // Build maps from cached data
      final postsMap = <String, CommunityPostState>{};
      for (final post in cachedPosts) {
        postsMap[post.post.id] = post;
      }

      final profilesMap = <String, CommunityProfileState>{};
      for (final profile in cachedProfiles) {
        profilesMap[profile.profile.userId] = profile;
      }

      final engagementsMap = <String, EngagementState>{};
      for (final engagement in cachedEngagements) {
        engagementsMap['${engagement.postId}_${engagement.userId}'] = engagement;
      }

      final relationshipsMap = <String, SocialRelationshipState>{};
      for (final relationship in cachedRelationships) {
        relationshipsMap['${relationship.userId}_${relationship.targetUserId}'] = relationship;
      }

      // Update state
      _updateState(_state.copyWith(
        posts: postsMap,
        profiles: profilesMap,
        engagements: engagementsMap,
        relationships: relationshipsMap,
        feedPostIds: cachedFeedOrder,
        pendingActions: pendingActions,
      ));

      debugPrint('CommunityStateManager: Loaded ${postsMap.length} posts, ${profilesMap.length} profiles from database');
    } catch (e) {
      debugPrint('CommunityStateManager: Error loading from database - $e');
    }
  }

  /// Perform initial sync with server
  Future<void> _performInitialSync() async {
    if (_isSyncing || _repository == null || _authToken == null) return;

    try {
      _isSyncing = true;
      debugPrint('CommunityStateManager: Starting initial sync');

      // Fetch initial posts
      final response = await _repository!.fetchCommunityPosts(
        token: _authToken!,
        page: 1,
        pageSize: 20,
      );

      // Process posts and update state
      await _processPosts(response.posts, clearExisting: true);

      // Update pagination
      _updatePagination(
        currentPage: response.page,
        totalItems: response.total,
        hasMore: response.hasMore,
      );

      debugPrint('CommunityStateManager: Initial sync completed with ${response.posts.length} posts');
    } catch (e) {
      debugPrint('CommunityStateManager: Error in initial sync - $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Update global state and notify subscribers
  void _updateState(CommunityGlobalState newState) {
    _state = newState;
    _stateController.add(_state);

    // Update individual streams
    _postsController.add(_state.posts);
    _profilesController.add(_state.profiles);
    _engagementsController.add(_state.engagements);
    _relationshipsController.add(_state.relationships);
    _feedController.add(_state.feedPostIds);
  }

  /// Start background sync process
  void _startBackgroundSync() {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = Timer.periodic(_backgroundSyncInterval, (_) {
      _performBackgroundSync();
    });
  }

  /// Start action processing for offline support
  void _startActionProcessing() {
    _actionProcessingTimer?.cancel();
    _actionProcessingTimer = Timer.periodic(_actionProcessingInterval, (_) {
      _processQueuedActions();
    });
  }

  /// Background sync with server
  Future<void> _performBackgroundSync() async {
    if (_isSyncing || _repository == null || _authToken == null) return;

    try {
      _isSyncing = true;
      final lastSync = _state.lastGlobalSync;
      debugPrint('CommunityStateManager: Starting background sync (last sync: $lastSync)');

      // TODO: Implement delta sync when server supports it
      // For now, fetch recent posts and update existing data
      
      _isSyncing = false;
    } catch (e) {
      debugPrint('CommunityStateManager: Error in background sync - $e');
      _isSyncing = false;
    }
  }

  /// Process queued actions (offline support)
  Future<void> _processQueuedActions() async {
    if (_repository == null || _authToken == null) return;

    final pendingActions = _state.pendingActions
        .where((action) => action.status == SyncStatus.pending || action.status == SyncStatus.failed)
        .toList();

    if (pendingActions.isEmpty) return;

    debugPrint('CommunityStateManager: Processing ${pendingActions.length} queued actions');

    for (final action in pendingActions) {
      await _processAction(action);
    }
  }

  /// Process individual action
  Future<void> _processAction(CommunityAction action) async {
    if (_repository == null || _authToken == null) return;

    try {
      // Mark as syncing
      await _updateActionStatus(action.id, SyncStatus.syncing);

      switch (action.type) {
        case CommunityActionType.likePost:
          await _processLikeAction(action);
          break;
        case CommunityActionType.unlikePost:
          await _processUnlikeAction(action);
          break;
        case CommunityActionType.createPost:
          await _processCreatePostAction(action);
          break;
        case CommunityActionType.followUser:
          await _processFollowAction(action);
          break;
        case CommunityActionType.unfollowUser:
          await _processUnfollowAction(action);
          break;
        default:
          debugPrint('CommunityStateManager: Unhandled action type: ${action.type}');
      }

      // Mark as synced
      await _updateActionStatus(action.id, SyncStatus.synced);
    } catch (e) {
      debugPrint('CommunityStateManager: Error processing action ${action.id} - $e');
      
      // Increment retry count
      final newRetryCount = action.retryCount + 1;
      if (newRetryCount >= _maxRetryAttempts) {
        await _updateActionStatus(action.id, SyncStatus.failed, retryCount: newRetryCount);
      } else {
        await _updateActionStatus(action.id, SyncStatus.pending, retryCount: newRetryCount);
      }
    }
  }

  /// Process posts from server response
  Future<void> _processPosts(List<PostEntity> serverPosts, {bool clearExisting = false}) async {
    final updatedPosts = <String, CommunityPostState>{};
    final updatedEngagements = <String, EngagementState>{};
    final updatedProfiles = <String, CommunityProfileState>{};
    final feedPostIds = <String>[];

    if (!clearExisting) {
      updatedPosts.addAll(_state.posts);
      updatedEngagements.addAll(_state.engagements);
      updatedProfiles.addAll(_state.profiles);
    }

    final now = DateTime.now();

    for (final post in serverPosts) {
      // Update post state
      updatedPosts[post.id] = CommunityPostState(
        post: post,
        lastUpdated: now,
        syncStatus: SyncStatus.synced,
      );

      // Add to feed order
      feedPostIds.add(post.id);

      // Update engagement state if user has liked
      if (post.isLikedByUser != null && _currentUserId != null) {
        final engagementKey = '${post.id}_$_currentUserId';
        updatedEngagements[engagementKey] = EngagementState(
          postId: post.id,
          userId: _currentUserId!,
          isLiked: post.isLikedByUser!,
          likeCount: post.likeCount,
          lastUpdated: now,
          syncStatus: SyncStatus.synced,
        );
      }

      // Update profile state from post author data
      if (post.username.isNotEmpty) {
        final existingProfile = updatedProfiles[post.userId];
        if (existingProfile == null) {
          // Create minimal profile from post data
          final profile = CommunityProfileEntity(
            id: post.userId,
            userId: post.userId,
            tenantId: post.tenantId,
            username: post.username,
            bio: '',
            profileImageUrl: post.userAvatar,
            bannerImageUrl: null,
            isPrivate: false,
            isVerified: false,
            followersCount: 0,
            followingCount: 0,
            postsCount: 0,
            settings: null,
            createdAt: now,
            updatedAt: now,
          );

          updatedProfiles[post.userId] = CommunityProfileState(
            profile: profile,
            lastUpdated: now,
            syncStatus: SyncStatus.synced,
          );
        }
      }
    }

    // Update state
    _updateState(_state.copyWith(
      posts: updatedPosts,
      engagements: updatedEngagements,
      profiles: updatedProfiles,
      feedPostIds: clearExisting ? feedPostIds : [..._state.feedPostIds, ...feedPostIds],
      lastGlobalSync: now,
    ));

    // Persist to database
    await _persistToDatabase();
  }

  /// Update pagination state
  void _updatePagination({
    int? currentPage,
    int? totalItems,
    bool? hasMore,
    bool? isLoading,
  }) {
    final updatedPagination = _state.feedPagination.copyWith(
      currentPage: currentPage,
      totalItems: totalItems,
      hasMore: hasMore,
      isLoading: isLoading,
      lastFetch: DateTime.now(),
    );

    _updateState(_state.copyWith(feedPagination: updatedPagination));
  }

  /// Persist current state to database
  Future<void> _persistToDatabase() async {
    try {
      await Future.wait([
        _database.savePosts(_state.posts.values.toList()),
        _database.saveProfiles(_state.profiles.values.toList()),
        _database.saveEngagements(_state.engagements.values.toList()),
        _database.saveSocialRelationships(_state.relationships.values.toList()),
        _database.saveFeedOrder(_state.feedPostIds),
        _database.saveActions(_state.pendingActions),
      ]);
    } catch (e) {
      debugPrint('CommunityStateManager: Error persisting to database - $e');
    }
  }

  /// Public API Methods

  /// Get posts for feed
  List<PostEntity> getFeedPosts({int? limit, int? offset}) {
    final feedIds = _state.feedPostIds;
    final startIndex = offset ?? 0;
    final endIndex = limit != null ? (startIndex + limit).clamp(0, feedIds.length) : feedIds.length;
    
    final posts = <PostEntity>[];
    for (int i = startIndex; i < endIndex; i++) {
      final postId = feedIds[i];
      final postState = _state.posts[postId];
      if (postState != null) {
        posts.add(postState.post);
      }
    }

    return posts;
  }

  /// Get user profile
  CommunityProfileEntity? getUserProfile(String userId) {
    return _state.profiles[userId]?.profile;
  }

  /// Get engagement state for post
  EngagementState? getEngagement(String postId, String userId) {
    return _state.engagements['${postId}_$userId'];
  }

  /// Get social relationship
  SocialRelationshipState? getRelationship(String userId, String targetUserId) {
    return _state.relationships['${userId}_$targetUserId'];
  }

  /// Optimistic like operation
  Future<void> likePost(String postId) async {
    if (_currentUserId == null) return;

    final currentPost = _state.posts[postId];
    if (currentPost == null) return;

    final now = DateTime.now();
    final engagementKey = '${postId}_$_currentUserId';

    // Optimistic update
    final updatedPosts = Map<String, CommunityPostState>.from(_state.posts);
    final updatedEngagements = Map<String, EngagementState>.from(_state.engagements);

    updatedPosts[postId] = currentPost.copyWith(
      post: currentPost.post.copyWith(
        isLikedByUser: true,
        likeCount: currentPost.post.likeCount + 1,
      ),
      lastUpdated: now,
      isOptimistic: true,
    );

    updatedEngagements[engagementKey] = EngagementState(
      postId: postId,
      userId: _currentUserId!,
      isLiked: true,
      likeCount: currentPost.post.likeCount + 1,
      lastUpdated: now,
      isOptimistic: true,
    );

    _updateState(_state.copyWith(
      posts: updatedPosts,
      engagements: updatedEngagements,
    ));

    // Queue action for server sync
    await _queueAction(CommunityAction(
      id: '${DateTime.now().millisecondsSinceEpoch}_like_$postId',
      type: CommunityActionType.likePost,
      payload: {'post_id': postId},
      timestamp: now,
      userId: _currentUserId,
      targetId: postId,
    ));
  }

  /// Optimistic unlike operation
  Future<void> unlikePost(String postId) async {
    if (_currentUserId == null) return;

    final currentPost = _state.posts[postId];
    if (currentPost == null) return;

    final now = DateTime.now();
    final engagementKey = '${postId}_$_currentUserId';

    // Optimistic update
    final updatedPosts = Map<String, CommunityPostState>.from(_state.posts);
    final updatedEngagements = Map<String, EngagementState>.from(_state.engagements);

    updatedPosts[postId] = currentPost.copyWith(
      post: currentPost.post.copyWith(
        isLikedByUser: false,
        likeCount: (currentPost.post.likeCount - 1).clamp(0, double.infinity).toInt(),
      ),
      lastUpdated: now,
      isOptimistic: true,
    );

    updatedEngagements[engagementKey] = EngagementState(
      postId: postId,
      userId: _currentUserId!,
      isLiked: false,
      likeCount: (currentPost.post.likeCount - 1).clamp(0, double.infinity).toInt(),
      lastUpdated: now,
      isOptimistic: true,
    );

    _updateState(_state.copyWith(
      posts: updatedPosts,
      engagements: updatedEngagements,
    ));

    // Queue action for server sync
    await _queueAction(CommunityAction(
      id: '${DateTime.now().millisecondsSinceEpoch}_unlike_$postId',
      type: CommunityActionType.unlikePost,
      payload: {'post_id': postId},
      timestamp: now,
      userId: _currentUserId,
      targetId: postId,
    ));
  }

  /// Queue action for offline processing
  Future<void> _queueAction(CommunityAction action) async {
    final updatedActions = List<CommunityAction>.from(_state.pendingActions);
    updatedActions.add(action);

    _updateState(_state.copyWith(pendingActions: updatedActions));
    
    // Persist action to database
    await _database.saveActions([action]);
  }

  /// Update action status
  Future<void> _updateActionStatus(String actionId, SyncStatus status, {int? retryCount}) async {
    final updatedActions = _state.pendingActions.map((action) {
      if (action.id == actionId) {
        return action.copyWith(status: status, retryCount: retryCount);
      }
      return action;
    }).toList();

    _updateState(_state.copyWith(pendingActions: updatedActions));
    
    // Update in database
    await _database.updateActionStatus(actionId, status, retryCount: retryCount);
  }

  /// Action processors

  Future<void> _processLikeAction(CommunityAction action) async {
    if (_repository == null || _authToken == null) return;
    
    final postId = action.payload['post_id'] as String;
    await _repository!.likePost(token: _authToken!, postId: postId);
  }

  Future<void> _processUnlikeAction(CommunityAction action) async {
    if (_repository == null || _authToken == null) return;
    
    final postId = action.payload['post_id'] as String;
    await _repository!.unlikePost(token: _authToken!, postId: postId);
  }

  Future<void> _processCreatePostAction(CommunityAction action) async {
    if (_repository == null || _authToken == null) return;
    
    final content = action.payload['content'] as String;
    final postData = CreatePostEntity(content: content, parentPostId: null);
    await _repository!.createPost(token: _authToken!, postData: postData);
  }

  Future<void> _processFollowAction(CommunityAction action) async {
    if (_repository == null || _authToken == null) return;
    
    final targetUserId = action.payload['target_user_id'] as String;
    await _repository!.followUser(token: _authToken!, userId: targetUserId);
  }

  Future<void> _processUnfollowAction(CommunityAction action) async {
    if (_repository == null || _authToken == null) return;
    
    final targetUserId = action.payload['target_user_id'] as String;
    await _repository!.unfollowUser(token: _authToken!, userId: targetUserId);
  }

  /// Load more posts (pagination)
  Future<void> loadMorePosts() async {
    if (_isSyncing || _repository == null || _authToken == null) return;
    if (!_state.feedPagination.hasMore || _state.feedPagination.isLoading) return;

    try {
      _updatePagination(isLoading: true);

      final nextPage = _state.feedPagination.currentPage + 1;
      final response = await _repository!.fetchCommunityPosts(
        token: _authToken!,
        page: nextPage,
        pageSize: _state.feedPagination.pageSize,
      );

      // Process new posts
      await _processPosts(response.posts, clearExisting: false);

      // Update pagination
      _updatePagination(
        currentPage: response.page,
        totalItems: response.total,
        hasMore: response.hasMore,
        isLoading: false,
      );

      debugPrint('CommunityStateManager: Loaded page $nextPage with ${response.posts.length} posts');
    } catch (e) {
      debugPrint('CommunityStateManager: Error loading more posts - $e');
      _updatePagination(isLoading: false);
    }
  }

  /// Refresh posts (pull-to-refresh)
  Future<void> refreshPosts() async {
    if (_repository == null || _authToken == null) return;

    try {
      debugPrint('CommunityStateManager: Refreshing posts');

      final response = await _repository!.fetchCommunityPosts(
        token: _authToken!,
        page: 1,
        pageSize: _state.feedPagination.pageSize,
      );

      // Clear existing and load fresh data
      await _processPosts(response.posts, clearExisting: true);

      // Reset pagination
      _updatePagination(
        currentPage: response.page,
        totalItems: response.total,
        hasMore: response.hasMore,
        isLoading: false,
      );

      debugPrint('CommunityStateManager: Refresh completed with ${response.posts.length} posts');
    } catch (e) {
      debugPrint('CommunityStateManager: Error refreshing posts - $e');
    }
  }

  /// Clear all data (logout)
  Future<void> clearAllData() async {
    // Stop background processes
    _backgroundSyncTimer?.cancel();
    _actionProcessingTimer?.cancel();

    // Clear database
    await _database.clearAllData();

    // Reset state
    _updateState(CommunityGlobalState(
      feedPagination: PaginationState(lastFetch: DateTime.now()),
      lastGlobalSync: DateTime.now(),
    ));

    // Reset flags
    _isInitialized = false;
    _isSyncing = false;
    _currentUserId = null;
    _authToken = null;
    _repository = null;

    debugPrint('CommunityStateManager: All data cleared');
  }

  /// Dispose resources
  Future<void> dispose() async {
    _backgroundSyncTimer?.cancel();
    _actionProcessingTimer?.cancel();
    
    await _stateController.close();
    await _postsController.close();
    await _profilesController.close();
    await _engagementsController.close();
    await _relationshipsController.close();
    await _feedController.close();
    
    await _database.close();
    
    debugPrint('CommunityStateManager: Disposed');
  }
}