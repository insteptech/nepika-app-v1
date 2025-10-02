import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../state/community_state_models.dart';
import '../state/community_state_manager.dart';
import '../../domain/community/entities/community_entities.dart';
import '../../domain/community/repositories/community_repository.dart';
import '../../core/network/api_base.dart';

/// L3 Server Sync Layer - Handles delta sync and real-time updates
/// Manages communication with the server for community data synchronization
class CommunitySyncService {
  static final CommunitySyncService _instance = CommunitySyncService._internal();
  factory CommunitySyncService() => _instance;
  CommunitySyncService._internal();

  /// Dependencies
  final CommunityStateManager _stateManager = CommunityStateManager();
  CommunityRepository? _repository;
  ApiBase? _apiBase;
  String? _authToken;
  String? _currentUserId;

  /// Real-time connection management
  StreamController<RealTimeEvent>? _realTimeController;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;

  /// Sync state
  bool _isSyncing = false;
  DateTime? _lastDeltaSync;
  final List<String> _syncQueue = [];

  /// Configuration
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _reconnectInterval = Duration(seconds: 5);
  static const Duration _deltaSyncInterval = Duration(minutes: 2);
  static const int _maxReconnectAttempts = 5;

  /// Public streams
  Stream<RealTimeEvent>? get realTimeStream => _realTimeController?.stream;

  /// Initialize the sync service
  Future<void> initialize({
    required String userId,
    required String authToken,
    required CommunityRepository repository,
    required ApiBase apiBase,
  }) async {
    try {
      _currentUserId = userId;
      _authToken = authToken;
      _repository = repository;
      _apiBase = apiBase;

      // Initialize real-time stream
      _realTimeController = StreamController<RealTimeEvent>.broadcast();

      // Start real-time connection
      await _initializeRealTimeConnection();

      // Schedule initial delta sync
      _scheduleDeltaSync();

      debugPrint('CommunitySyncService: Initialized successfully for user $userId');
    } catch (e) {
      debugPrint('CommunitySyncService: Failed to initialize - $e');
      rethrow;
    }
  }

  /// Initialize real-time connection (Server-Sent Events)
  Future<void> _initializeRealTimeConnection() async {
    if (_apiBase == null || _authToken == null) return;

    try {
      debugPrint('CommunitySyncService: Establishing real-time connection');

      // For now, simulate real-time connection since SSE might not be available
      // TODO: Implement actual SSE connection when server supports it
      _simulateRealTimeConnection();

      _isConnected = true;
      _reconnectAttempts = 0;
      _startHeartbeat();

      debugPrint('CommunitySyncService: Real-time connection established');
    } catch (e) {
      debugPrint('CommunitySyncService: Failed to establish real-time connection - $e');
      _scheduleReconnect();
    }
  }

  /// Simulate real-time connection for demo purposes
  void _simulateRealTimeConnection() {
    // Simulate periodic events
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }

      // Simulate a random like event
      final event = RealTimeEvent(
        eventType: 'post_liked',
        userId: 'simulated_user_${DateTime.now().millisecondsSinceEpoch % 1000}',
        targetId: 'post_${DateTime.now().millisecondsSinceEpoch % 100}',
        data: {
          'like_count': DateTime.now().millisecondsSinceEpoch % 50,
          'is_liked': true,
        },
        timestamp: DateTime.now(),
      );

      _handleRealTimeEvent(event);
    });
  }

  /// Start heartbeat to maintain connection
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _sendHeartbeat();
    });
  }

  /// Send heartbeat to server
  Future<void> _sendHeartbeat() async {
    try {
      // TODO: Implement actual heartbeat when server supports it
      debugPrint('CommunitySyncService: Heartbeat sent');
    } catch (e) {
      debugPrint('CommunitySyncService: Heartbeat failed - $e');
      _handleConnectionLoss();
    }
  }

  /// Handle connection loss
  void _handleConnectionLoss() {
    _isConnected = false;
    _heartbeatTimer?.cancel();
    _scheduleReconnect();
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_isReconnecting || _reconnectAttempts >= _maxReconnectAttempts) return;

    _isReconnecting = true;
    _reconnectTimer?.cancel();
    
    final delay = Duration(seconds: (_reconnectInterval.inSeconds * (_reconnectAttempts + 1)).clamp(5, 60));
    
    _reconnectTimer = Timer(delay, () async {
      _reconnectAttempts++;
      debugPrint('CommunitySyncService: Reconnection attempt ${_reconnectAttempts}');
      
      try {
        await _initializeRealTimeConnection();
        _isReconnecting = false;
      } catch (e) {
        debugPrint('CommunitySyncService: Reconnection failed - $e');
        _isReconnecting = false;
        _scheduleReconnect();
      }
    });
  }

  /// Handle incoming real-time events
  void _handleRealTimeEvent(RealTimeEvent event) {
    try {
      _realTimeController?.add(event);

      // Process event based on type
      switch (event.eventType) {
        case 'post_liked':
        case 'post_unliked':
          _handleLikeEvent(event);
          break;
        case 'post_created':
          _handlePostCreatedEvent(event);
          break;
        case 'post_updated':
          _handlePostUpdatedEvent(event);
          break;
        case 'post_deleted':
          _handlePostDeletedEvent(event);
          break;
        case 'user_followed':
        case 'user_unfollowed':
          _handleFollowEvent(event);
          break;
        case 'comment_created':
          _handleCommentEvent(event);
          break;
        default:
          debugPrint('CommunitySyncService: Unhandled event type: ${event.eventType}');
      }
    } catch (e) {
      debugPrint('CommunitySyncService: Error handling real-time event - $e');
    }
  }

  /// Handle like/unlike events
  void _handleLikeEvent(RealTimeEvent event) {
    final postId = event.targetId;
    final likeCount = event.data['like_count'] as int?;
    final isLiked = event.data['is_liked'] as bool?;

    if (postId != null && likeCount != null) {
      // Update like count in state manager
      final currentPosts = _stateManager.posts;
      final post = currentPosts[postId];
      
      if (post != null) {
        final updatedPost = post.copyWith(
          post: post.post.copyWith(
            likeCount: likeCount,
            // Only update isLikedByUser if this event is for current user
            isLikedByUser: event.userId == _currentUserId ? isLiked : post.post.isLikedByUser,
          ),
          lastUpdated: DateTime.now(),
        );

        // TODO: Update state manager with new post data
        debugPrint('CommunitySyncService: Updated like count for post $postId to $likeCount');
      }
    }
  }

  /// Handle post creation events
  void _handlePostCreatedEvent(RealTimeEvent event) {
    // Trigger a delta sync to fetch the new post
    _scheduleDeltaSync(immediate: true);
  }

  /// Handle post update events
  void _handlePostUpdatedEvent(RealTimeEvent event) {
    final postId = event.targetId;
    if (postId != null) {
      _addToSyncQueue(postId);
    }
  }

  /// Handle post deletion events
  void _handlePostDeletedEvent(RealTimeEvent event) {
    final postId = event.targetId;
    if (postId != null) {
      // TODO: Remove post from state manager
      debugPrint('CommunitySyncService: Post $postId was deleted');
    }
  }

  /// Handle follow/unfollow events
  void _handleFollowEvent(RealTimeEvent event) {
    final targetUserId = event.targetId;
    final followerId = event.userId;
    
    if (targetUserId != null && followerId != null) {
      // Update follower count if this is current user's profile
      if (targetUserId == _currentUserId) {
        _scheduleDeltaSync(immediate: true);
      }
    }
  }

  /// Handle comment events
  void _handleCommentEvent(RealTimeEvent event) {
    final postId = event.targetId;
    if (postId != null) {
      _addToSyncQueue(postId);
    }
  }

  /// Add item to sync queue
  void _addToSyncQueue(String itemId) {
    if (!_syncQueue.contains(itemId)) {
      _syncQueue.add(itemId);
      _scheduleDeltaSync();
    }
  }

  /// Schedule delta sync
  void _scheduleDeltaSync({bool immediate = false}) {
    if (_isSyncing) return;

    final delay = immediate ? Duration.zero : _deltaSyncInterval;
    
    Timer(delay, () {
      _performDeltaSync();
    });
  }

  /// Perform delta sync with server
  Future<void> _performDeltaSync() async {
    if (_isSyncing || _repository == null || _authToken == null) return;

    try {
      _isSyncing = true;
      debugPrint('CommunitySyncService: Starting delta sync');

      final lastSync = _lastDeltaSync ?? DateTime.now().subtract(const Duration(hours: 1));
      
      // Create delta sync request
      final request = DeltaSyncRequest(
        lastSyncTimestamp: lastSync,
        postIds: _syncQueue.toList(),
        userIds: [], // TODO: Add user IDs that need syncing
        includeDeleted: true,
      );

      // Perform delta sync via API
      final response = await _performDeltaSyncRequest(request);
      
      if (response != null) {
        await _processDeltaSyncResponse(response);
        _lastDeltaSync = response.serverTimestamp;
        _syncQueue.clear();
      }

      debugPrint('CommunitySyncService: Delta sync completed');
    } catch (e) {
      debugPrint('CommunitySyncService: Error in delta sync - $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Perform delta sync request to server
  Future<DeltaSyncResponse?> _performDeltaSyncRequest(DeltaSyncRequest request) async {
    if (_apiBase == null || _authToken == null) return null;

    try {
      // TODO: Implement actual delta sync API call
      // For now, return null to indicate no delta sync support
      debugPrint('CommunitySyncService: Delta sync API not yet implemented');
      return null;
      
      /*
      final response = await _apiBase!.makeRequest(
        endpoint: '/community/delta-sync',
        method: 'POST',
        data: request.toJson(),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        return DeltaSyncResponse.fromJson(response.data);
      }
      */
    } catch (e) {
      debugPrint('CommunitySyncService: Delta sync request failed - $e');
      return null;
    }
  }

  /// Process delta sync response
  Future<void> _processDeltaSyncResponse(DeltaSyncResponse response) async {
    try {
      // Update posts
      if (response.updatedPosts.isNotEmpty) {
        // TODO: Update posts in state manager
        debugPrint('CommunitySyncService: Received ${response.updatedPosts.length} updated posts');
      }

      // Remove deleted posts
      if (response.deletedPostIds.isNotEmpty) {
        // TODO: Remove deleted posts from state manager
        debugPrint('CommunitySyncService: Received ${response.deletedPostIds.length} deleted posts');
      }

      // Update profiles
      if (response.updatedProfiles.isNotEmpty) {
        // TODO: Update profiles in state manager
        debugPrint('CommunitySyncService: Received ${response.updatedProfiles.length} updated profiles');
      }

      // Update engagements
      if (response.updatedEngagements.isNotEmpty) {
        // TODO: Update engagements in state manager
        debugPrint('CommunitySyncService: Received ${response.updatedEngagements.length} updated engagements');
      }

      // Update relationships
      if (response.updatedRelationships.isNotEmpty) {
        // TODO: Update relationships in state manager
        debugPrint('CommunitySyncService: Received ${response.updatedRelationships.length} updated relationships');
      }

    } catch (e) {
      debugPrint('CommunitySyncService: Error processing delta sync response - $e');
    }
  }

  /// Force sync specific items
  Future<void> syncItems({
    List<String>? postIds,
    List<String>? userIds,
  }) async {
    if (postIds != null) {
      _syncQueue.addAll(postIds.where((id) => !_syncQueue.contains(id)));
    }
    
    if (userIds != null) {
      // TODO: Add user ID syncing
    }

    await _performDeltaSync();
  }

  /// Manual full refresh
  Future<void> performFullRefresh() async {
    try {
      debugPrint('CommunitySyncService: Starting full refresh');
      
      // Clear sync queue
      _syncQueue.clear();
      
      // Trigger full refresh in state manager
      await _stateManager.refreshPosts();
      
      // Update last sync time
      _lastDeltaSync = DateTime.now();
      
      debugPrint('CommunitySyncService: Full refresh completed');
    } catch (e) {
      debugPrint('CommunitySyncService: Error in full refresh - $e');
    }
  }

  /// Check connection status
  bool get isConnected => _isConnected;

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    return {
      'is_connected': _isConnected,
      'is_syncing': _isSyncing,
      'last_delta_sync': _lastDeltaSync?.toIso8601String(),
      'sync_queue_size': _syncQueue.length,
      'reconnect_attempts': _reconnectAttempts,
    };
  }

  /// Disconnect and cleanup
  Future<void> disconnect() async {
    try {
      _isConnected = false;
      _heartbeatTimer?.cancel();
      _reconnectTimer?.cancel();
      
      await _realTimeController?.close();
      _realTimeController = null;
      
      _syncQueue.clear();
      _isSyncing = false;
      _reconnectAttempts = 0;
      
      debugPrint('CommunitySyncService: Disconnected');
    } catch (e) {
      debugPrint('CommunitySyncService: Error during disconnect - $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await disconnect();
    debugPrint('CommunitySyncService: Disposed');
  }
}