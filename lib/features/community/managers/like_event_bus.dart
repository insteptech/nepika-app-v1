import 'dart:async';
import 'package:flutter/material.dart';

/// High-performance event bus for real-time like synchronization across screens
/// Provides instant communication between all community UI components
class LikeEventBus {
  static final LikeEventBus _instance = LikeEventBus._internal();
  factory LikeEventBus() => _instance;
  LikeEventBus._internal();

  /// Main event stream for like state changes
  final StreamController<LikeEvent> _eventController = StreamController<LikeEvent>.broadcast();
  
  /// Filtered streams for specific event types
  final StreamController<LikeToggleEvent> _likeToggleController = StreamController<LikeToggleEvent>.broadcast();
  final StreamController<LikeSyncEvent> _likeSyncController = StreamController<LikeSyncEvent>.broadcast();
  final StreamController<LikeErrorEvent> _likeErrorController = StreamController<LikeErrorEvent>.broadcast();
  
  /// Active listeners tracking for debugging
  final Map<String, int> _listenerCounts = {};
  
  /// Event history for debugging (last 100 events)
  final List<LikeEvent> _eventHistory = [];
  static const int _maxHistorySize = 100;

  /// Main event stream - broadcasts all like-related events
  Stream<LikeEvent> get eventStream => _eventController.stream;
  
  /// Filtered stream for like toggle events only
  Stream<LikeToggleEvent> get likeToggleStream => _likeToggleController.stream;
  
  /// Filtered stream for sync events only  
  Stream<LikeSyncEvent> get likeSyncStream => _likeSyncController.stream;
  
  /// Filtered stream for error events only
  Stream<LikeErrorEvent> get likeErrorStream => _likeErrorController.stream;

  /// Emit a like toggle event (user tapped like button)
  void emitLikeToggle({
    required String postId,
    required bool newLikeStatus,
    required int newLikeCount,
    required String source,
    bool isOptimistic = true,
  }) {
    final event = LikeToggleEvent(
      postId: postId,
      newLikeStatus: newLikeStatus,
      newLikeCount: newLikeCount,
      source: source,
      isOptimistic: isOptimistic,
      timestamp: DateTime.now(),
    );

    _broadcastEvent(event);
    debugPrint('LikeEventBus: Emitted like toggle - Post: $postId, Liked: $newLikeStatus, Count: $newLikeCount, Source: $source');
  }

  /// Emit a sync event (server confirmation/update)
  void emitLikeSync({
    required String postId,
    required bool serverLikeStatus,
    required int serverLikeCount,
    required String source,
    bool hasConflict = false,
  }) {
    final event = LikeSyncEvent(
      postId: postId,
      serverLikeStatus: serverLikeStatus,
      serverLikeCount: serverLikeCount,
      source: source,
      hasConflict: hasConflict,
      timestamp: DateTime.now(),
    );

    _broadcastEvent(event);
    debugPrint('LikeEventBus: Emitted like sync - Post: $postId, Server Status: $serverLikeStatus, Count: $serverLikeCount, Conflict: $hasConflict');
  }

  /// Emit an error event
  void emitLikeError({
    required String postId,
    required String error,
    required String source,
    bool shouldRevert = true,
    Map<String, dynamic>? revertData,
  }) {
    final event = LikeErrorEvent(
      postId: postId,
      error: error,
      source: source,
      shouldRevert: shouldRevert,
      revertData: revertData,
      timestamp: DateTime.now(),
    );

    _broadcastEvent(event);
    debugPrint('LikeEventBus: Emitted like error - Post: $postId, Error: $error, ShouldRevert: $shouldRevert');
  }

  /// Emit bulk update event (for feed refreshes)
  void emitBulkLikeUpdate({
    required Map<String, LikeBulkData> updates,
    required String source,
  }) {
    final event = LikeBulkUpdateEvent(
      updates: updates,
      source: source,
      timestamp: DateTime.now(),
    );

    _broadcastEvent(event);
    debugPrint('LikeEventBus: Emitted bulk update - ${updates.length} posts, Source: $source');
  }

  /// Internal method to broadcast events to all streams
  void _broadcastEvent(LikeEvent event) {
    // Add to main stream
    _eventController.add(event);
    
    // Add to specific streams based on event type
    if (event is LikeToggleEvent) {
      _likeToggleController.add(event);
    } else if (event is LikeSyncEvent) {
      _likeSyncController.add(event);
    } else if (event is LikeErrorEvent) {
      _likeErrorController.add(event);
    }

    // Add to history for debugging
    _addToHistory(event);
  }

  /// Add event to history with size limit
  void _addToHistory(LikeEvent event) {
    _eventHistory.add(event);
    if (_eventHistory.length > _maxHistorySize) {
      _eventHistory.removeAt(0);
    }
  }

  /// Register a listener (for tracking/debugging)
  StreamSubscription<T> listen<T extends LikeEvent>(
    Stream<T> stream,
    void Function(T) onData, {
    required String listenerId,
    Function(Object)? onError,
  }) {
    // Track listener
    _listenerCounts[listenerId] = (_listenerCounts[listenerId] ?? 0) + 1;
    
    debugPrint('LikeEventBus: Registered listener $listenerId (count: ${_listenerCounts[listenerId]})');
    
    return stream.listen(
      onData,
      onError: onError,
      onDone: () {
        // Cleanup listener tracking
        final currentCount = _listenerCounts[listenerId] ?? 0;
        if (currentCount <= 1) {
          _listenerCounts.remove(listenerId);
        } else {
          _listenerCounts[listenerId] = currentCount - 1;
        }
        debugPrint('LikeEventBus: Unregistered listener $listenerId');
      },
    );
  }

  /// Convenience method for listening to all like events for a specific post
  StreamSubscription<LikeEvent> listenToPost(
    String postId,
    void Function(LikeEvent) onData, {
    required String listenerId,
  }) {
    return listen(
      eventStream.where((event) => event.postId == postId),
      onData,
      listenerId: '${listenerId}_post_$postId',
    );
  }

  /// Convenience method for listening to like toggles for a specific post
  StreamSubscription<LikeToggleEvent> listenToPostToggle(
    String postId,
    void Function(LikeToggleEvent) onData, {
    required String listenerId,
  }) {
    return listen(
      likeToggleStream.where((event) => event.postId == postId),
      onData,
      listenerId: '${listenerId}_toggle_$postId',
    );
  }

  /// Get recent events for debugging
  List<LikeEvent> getRecentEvents({int? limit}) {
    final eventLimit = limit ?? _eventHistory.length;
    return _eventHistory.length > eventLimit 
        ? _eventHistory.sublist(_eventHistory.length - eventLimit)
        : List.from(_eventHistory);
  }

  /// Get listener statistics for debugging
  Map<String, int> getListenerStats() {
    return Map.from(_listenerCounts);
  }

  /// Clear event history
  void clearHistory() {
    _eventHistory.clear();
    debugPrint('LikeEventBus: Cleared event history');
  }

  /// Dispose all resources
  void dispose() {
    _eventController.close();
    _likeToggleController.close();
    _likeSyncController.close();
    _likeErrorController.close();
    _eventHistory.clear();
    _listenerCounts.clear();
    debugPrint('LikeEventBus: Disposed');
  }
}

/// Base class for all like-related events
abstract class LikeEvent {
  final String postId;
  final DateTime timestamp;

  const LikeEvent({
    required this.postId,
    required this.timestamp,
  });

  @override
  String toString() {
    return '$runtimeType(postId: $postId, timestamp: $timestamp)';
  }
}

/// Event emitted when user toggles like status
class LikeToggleEvent extends LikeEvent {
  final bool newLikeStatus;
  final int newLikeCount;
  final String source;
  final bool isOptimistic;

  const LikeToggleEvent({
    required super.postId,
    required this.newLikeStatus,
    required this.newLikeCount,
    required this.source,
    required this.isOptimistic,
    required super.timestamp,
  });

  @override
  String toString() {
    return 'LikeToggleEvent(postId: $postId, liked: $newLikeStatus, count: $newLikeCount, source: $source, optimistic: $isOptimistic)';
  }
}

/// Event emitted when server response is received
class LikeSyncEvent extends LikeEvent {
  final bool serverLikeStatus;
  final int serverLikeCount;
  final String source;
  final bool hasConflict;

  const LikeSyncEvent({
    required super.postId,
    required this.serverLikeStatus,
    required this.serverLikeCount,
    required this.source,
    required this.hasConflict,
    required super.timestamp,
  });

  @override
  String toString() {
    return 'LikeSyncEvent(postId: $postId, serverLiked: $serverLikeStatus, serverCount: $serverLikeCount, conflict: $hasConflict)';
  }
}

/// Event emitted when like operation fails
class LikeErrorEvent extends LikeEvent {
  final String error;
  final String source;
  final bool shouldRevert;
  final Map<String, dynamic>? revertData;

  const LikeErrorEvent({
    required super.postId,
    required this.error,
    required this.source,
    required this.shouldRevert,
    this.revertData,
    required super.timestamp,
  });

  @override
  String toString() {
    return 'LikeErrorEvent(postId: $postId, error: $error, shouldRevert: $shouldRevert)';
  }
}

/// Event emitted for bulk updates (feed refreshes)
class LikeBulkUpdateEvent extends LikeEvent {
  final Map<String, LikeBulkData> updates;
  final String source;

  const LikeBulkUpdateEvent({
    required this.updates,
    required this.source,
    required super.timestamp,
  }) : super(postId: 'BULK_UPDATE');

  @override
  String toString() {
    return 'LikeBulkUpdateEvent(updates: ${updates.length} posts, source: $source)';
  }
}

/// Data structure for bulk like updates
class LikeBulkData {
  final bool isLiked;
  final int likeCount;
  final DateTime? lastUpdated;

  const LikeBulkData({
    required this.isLiked,
    required this.likeCount,
    this.lastUpdated,
  });

  @override
  String toString() {
    return 'LikeBulkData(liked: $isLiked, count: $likeCount)';
  }
}