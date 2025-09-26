import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/utils/shared_prefs_helper.dart';
import '../../../core/config/constants/app_constants.dart';
import '../../../domain/community/repositories/community_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized like state management for 100% reliable synchronization
/// Singleton pattern ensures single source of truth across all screens
class LikeStateManager {
  static final LikeStateManager _instance = LikeStateManager._internal();
  factory LikeStateManager() => _instance;
  LikeStateManager._internal();

  /// Stream controller for broadcasting like state changes
  final StreamController<LikeStateEvent> _eventController = StreamController<LikeStateEvent>.broadcast();
  
  /// Current like states for all posts
  final Map<String, LikeState> _likeStates = {};
  
  /// Pending operations queue for offline/error scenarios
  final Map<String, LikePendingOperation> _pendingOperations = {};
  
  /// Debounce timers for API calls
  final Map<String, Timer> _debounceTimers = {};
  
  /// Server validation timers
  final Map<String, Timer> _validationTimers = {};
  
  /// User authentication data
  String? _token;
  String? _userId;
  
  /// Repository for API calls
  CommunityRepository? _repository;
  
  /// Configuration
  static const Duration _debounceDelay = Duration(milliseconds: 500);
  static const Duration _validationDelay = Duration(seconds: 30);
  static const int _maxRetryAttempts = 3;

  /// Initialize the manager with user data and repository
  Future<void> initialize([CommunityRepository? repository]) async {
    if (repository != null) {
      _repository = repository;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await SharedPrefsHelper.init();
      
      _token = prefs.getString(AppConstants.accessTokenKey);
      final userData = prefs.getString(AppConstants.userDataKey);
      
      if (userData != null) {
        final userMap = jsonDecode(userData);
        _userId = userMap['id'];
      }
      
      debugPrint('LikeStateManager: Initialized with token: ${_token != null ? 'present' : 'null'}, userId: $_userId');
      
      // Load persisted like states from cache
      await _loadPersistedStates();
      
    } catch (e) {
      debugPrint('LikeStateManager: Initialization error: $e');
    }
  }

  /// Get stream for listening to like state changes
  Stream<LikeStateEvent> get stateStream => _eventController.stream;

  /// Get current like state for a post
  LikeState? getLikeState(String postId) {
    return _likeStates[postId];
  }

  /// Initialize state for a post if it doesn't exist
  void initializePostState({
    required String postId,
    required bool isLiked,
    required int likeCount,
  }) {
    if (_likeStates[postId] == null) {
      final initialState = LikeState(
        postId: postId,
        isLiked: isLiked,
        likeCount: likeCount,
        isLoading: false,
        lastUpdated: DateTime.now(),
        source: LikeStateSource.external,
      );
      
      _likeStates[postId] = initialState;
      
      // Broadcast the initial state
      if (!_eventController.isClosed) {
        _eventController.add(LikeStateEvent(
          postId: postId,
          state: initialState,
          type: LikeEventType.externalUpdate,
        ));
      }
    }
  }

  /// Get current like status for a post (with fallback to provided default)
  bool isLiked(String postId, {bool defaultValue = false}) {
    return _likeStates[postId]?.isLiked ?? defaultValue;
  }

  /// Get current like count for a post (with fallback to provided default)
  int getLikeCount(String postId, {int defaultValue = 0}) {
    return _likeStates[postId]?.likeCount ?? defaultValue;
  }

  /// Update like state with optimistic UI updates and reliable server sync
  Future<void> toggleLike({
    required String postId,
    required bool currentLikeStatus,
    required int currentLikeCount,
    Function(String)? onError,
  }) async {
    if (_token == null || _userId == null) {
      onError?.call('Authentication required to like posts');
      return;
    }

    final newLikeStatus = !currentLikeStatus;
    final newLikeCount = newLikeStatus ? currentLikeCount + 1 : currentLikeCount - 1;

    // Create optimistic state immediately
    final optimisticState = LikeState(
      postId: postId,
      isLiked: newLikeStatus,
      likeCount: newLikeCount,
      isLoading: true,
      lastUpdated: DateTime.now(),
      source: LikeStateSource.optimistic,
    );

    // Update internal state
    _likeStates[postId] = optimisticState;
    
    // Broadcast change immediately for instant UI updates
    if (!_eventController.isClosed) {
      _eventController.add(LikeStateEvent(
        postId: postId,
        state: optimisticState,
        type: LikeEventType.optimisticUpdate,
      ));
    }

    // Cancel any existing timers for this post
    _debounceTimers[postId]?.cancel();
    _validationTimers[postId]?.cancel();

    // Store pending operation
    _pendingOperations[postId] = LikePendingOperation(
      postId: postId,
      targetLikeStatus: newLikeStatus,
      originalLikeStatus: currentLikeStatus,
      originalLikeCount: currentLikeCount,
      attempts: 0,
      timestamp: DateTime.now(),
    );

    // Debounced API call to prevent rapid-fire requests
    _debounceTimers[postId] = Timer(_debounceDelay, () async {
      await _performServerUpdate(postId, onError: onError);
    });

    // Persist state for recovery
    await _persistState(postId, optimisticState);
  }

  /// Perform the actual server update with retry logic
  Future<void> _performServerUpdate(String postId, {Function(String)? onError}) async {
    final pendingOp = _pendingOperations[postId];
    if (pendingOp == null) return;

    try {
      debugPrint('LikeStateManager: Performing server update for post $postId');
      
      if (_repository == null || _token == null) {
        throw Exception('Repository or token not available');
      }
      
      final response = await _repository!.toggleLikePost(
        token: _token!,
        postId: postId,
      );
      
      final serverLikeStatus = response['is_liked'] as bool;
      final serverLikeCount = response['like_count'] as int;

        // Update with authoritative server response
        final serverState = LikeState(
          postId: postId,
          isLiked: serverLikeStatus,
          likeCount: serverLikeCount,
          isLoading: false,
          lastUpdated: DateTime.now(),
          source: LikeStateSource.server,
        );

        _likeStates[postId] = serverState;
        _pendingOperations.remove(postId);

        // Broadcast server confirmation
        if (!_eventController.isClosed) {
          _eventController.add(LikeStateEvent(
            postId: postId,
            state: serverState,
            type: LikeEventType.serverConfirmed,
          ));
        }

        await _persistState(postId, serverState);
        
        // Schedule next validation
        _scheduleValidation(postId);

    } catch (e) {
      debugPrint('LikeStateManager: Server update failed for post $postId: $e');
      
      pendingOp.attempts++;
      
      if (pendingOp.attempts < _maxRetryAttempts) {
        // Retry with exponential backoff
        final retryDelay = Duration(milliseconds: 1000 * (1 << pendingOp.attempts));
        Timer(retryDelay, () => _performServerUpdate(postId, onError: onError));
        
      } else {
        // Max retries reached - revert to original state
        await _revertToOriginalState(postId, pendingOp);
        onError?.call('Failed to update like status. Please try again.');
      }
    }
  }

  /// Revert like state to original values on permanent failure
  Future<void> _revertToOriginalState(String postId, LikePendingOperation pendingOp) async {
    final revertedState = LikeState(
      postId: postId,
      isLiked: pendingOp.originalLikeStatus,
      likeCount: pendingOp.originalLikeCount,
      isLoading: false,
      lastUpdated: DateTime.now(),
      source: LikeStateSource.reverted,
      error: 'Failed to sync with server',
    );

    _likeStates[postId] = revertedState;
    _pendingOperations.remove(postId);

    if (!_eventController.isClosed) {
      _eventController.add(LikeStateEvent(
        postId: postId,
        state: revertedState,
        type: LikeEventType.reverted,
      ));
    }

    await _persistState(postId, revertedState);
  }

  /// Schedule periodic server validation for a post
  void _scheduleValidation(String postId) {
    _validationTimers[postId] = Timer(_validationDelay, () async {
      await _validateWithServer(postId);
    });
  }

  /// Validate local state with server (background operation)
  Future<void> _validateWithServer(String postId) async {
    if (!_likeStates.containsKey(postId)) return;

    try {
      // This will be implemented when integrating with repository
      debugPrint('LikeStateManager: Validating post $postId with server');
      
      // Schedule next validation
      _scheduleValidation(postId);
      
    } catch (e) {
      debugPrint('LikeStateManager: Server validation failed for post $postId: $e');
    }
  }

  /// Update like state from external source (PostsBloc, API response, etc.)
  void updateFromExternal({
    required String postId,
    required bool isLiked,
    required int likeCount,
    LikeStateSource source = LikeStateSource.external,
  }) {
    final externalState = LikeState(
      postId: postId,
      isLiked: isLiked,
      likeCount: likeCount,
      isLoading: false,
      lastUpdated: DateTime.now(),
      source: source,
    );

    _likeStates[postId] = externalState;

    if (!_eventController.isClosed) {
      _eventController.add(LikeStateEvent(
        postId: postId,
        state: externalState,
        type: LikeEventType.externalUpdate,
      ));
    }

    _persistState(postId, externalState);
  }

  /// Bulk update like states (useful for feed refreshes)
  void bulkUpdate(Map<String, LikeStateData> updates) {
    final events = <LikeStateEvent>[];

    for (final entry in updates.entries) {
      final postId = entry.key;
      final data = entry.value;
      
      final state = LikeState(
        postId: postId,
        isLiked: data.isLiked,
        likeCount: data.likeCount,
        isLoading: false,
        lastUpdated: DateTime.now(),
        source: LikeStateSource.bulk,
      );

      _likeStates[postId] = state;
      
      events.add(LikeStateEvent(
        postId: postId,
        state: state,
        type: LikeEventType.bulkUpdate,
      ));
    }

    // Broadcast all updates
    if (!_eventController.isClosed) {
      for (final event in events) {
        _eventController.add(event);
      }
    }
  }

  /// Clear like state for a specific post
  void clearPostState(String postId) {
    _likeStates.remove(postId);
    _pendingOperations.remove(postId);
    _debounceTimers[postId]?.cancel();
    _validationTimers[postId]?.cancel();
    _debounceTimers.remove(postId);
    _validationTimers.remove(postId);
  }

  /// Clear all like states (useful for logout)
  void clearAllStates() {
    _likeStates.clear();
    _pendingOperations.clear();
    
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    for (final timer in _validationTimers.values) {
      timer.cancel();
    }
    
    _debounceTimers.clear();
    _validationTimers.clear();
  }

  /// Persist like state to local storage
  Future<void> _persistState(String postId, LikeState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateData = {
        'isLiked': state.isLiked,
        'likeCount': state.likeCount,
        'lastUpdated': state.lastUpdated.millisecondsSinceEpoch,
        'source': state.source.toString(),
      };
      await prefs.setString('like_state_$postId', jsonEncode(stateData));
    } catch (e) {
      debugPrint('LikeStateManager: Error persisting state: $e');
    }
  }

  /// Load persisted like states from local storage
  Future<void> _loadPersistedStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('like_state_'));
      
      for (final key in keys) {
        final postId = key.replaceFirst('like_state_', '');
        final stateJson = prefs.getString(key);
        
        if (stateJson != null) {
          final stateData = jsonDecode(stateJson);
          final state = LikeState(
            postId: postId,
            isLiked: stateData['isLiked'] as bool,
            likeCount: stateData['likeCount'] as int,
            isLoading: false,
            lastUpdated: DateTime.fromMillisecondsSinceEpoch(stateData['lastUpdated'] as int),
            source: LikeStateSource.persisted,
          );
          
          _likeStates[postId] = state;
        }
      }
      
      debugPrint('LikeStateManager: Loaded ${_likeStates.length} persisted like states');
      
    } catch (e) {
      debugPrint('LikeStateManager: Error loading persisted states: $e');
    }
  }


  /// Dispose resources
  void dispose() {
    _eventController.close();
    
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    for (final timer in _validationTimers.values) {
      timer.cancel();
    }
    
    _debounceTimers.clear();
    _validationTimers.clear();
    _likeStates.clear();
    _pendingOperations.clear();
  }
}

/// Represents the current like state for a post
class LikeState {
  final String postId;
  final bool isLiked;
  final int likeCount;
  final bool isLoading;
  final DateTime lastUpdated;
  final LikeStateSource source;
  final String? error;

  const LikeState({
    required this.postId,
    required this.isLiked,
    required this.likeCount,
    required this.isLoading,
    required this.lastUpdated,
    required this.source,
    this.error,
  });

  LikeState copyWith({
    bool? isLiked,
    int? likeCount,
    bool? isLoading,
    DateTime? lastUpdated,
    LikeStateSource? source,
    String? error,
  }) {
    return LikeState(
      postId: postId,
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
      isLoading: isLoading ?? this.isLoading,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      source: source ?? this.source,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'LikeState(postId: $postId, isLiked: $isLiked, count: $likeCount, loading: $isLoading, source: $source)';
  }
}

/// Event broadcast when like state changes
class LikeStateEvent {
  final String postId;
  final LikeState state;
  final LikeEventType type;

  const LikeStateEvent({
    required this.postId,
    required this.state,
    required this.type,
  });
}

/// Types of like state events
enum LikeEventType {
  optimisticUpdate,  // Immediate UI update
  serverConfirmed,   // Server response received
  reverted,         // Reverted due to error
  externalUpdate,   // Updated from external source
  bulkUpdate,       // Part of bulk state update
}

/// Source of like state data
enum LikeStateSource {
  optimistic,   // User interaction (not confirmed)
  server,       // Confirmed by server
  external,     // From PostsBloc or API
  persisted,    // Loaded from local storage
  reverted,     // Reverted due to error
  bulk,         // Part of bulk update
}

/// Pending like operation awaiting server confirmation
class LikePendingOperation {
  final String postId;
  final bool targetLikeStatus;
  final bool originalLikeStatus;
  final int originalLikeCount;
  int attempts;
  final DateTime timestamp;

  LikePendingOperation({
    required this.postId,
    required this.targetLikeStatus,
    required this.originalLikeStatus,
    required this.originalLikeCount,
    this.attempts = 0,
    required this.timestamp,
  });
}

/// Simplified data structure for bulk updates
class LikeStateData {
  final bool isLiked;
  final int likeCount;

  const LikeStateData({
    required this.isLiked,
    required this.likeCount,
  });
}