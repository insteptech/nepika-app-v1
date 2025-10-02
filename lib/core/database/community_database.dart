import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/community_state_models.dart';
import '../../domain/community/entities/community_entities.dart';

/// L2 Database Layer - SharedPreferences-based structured storage
/// This provides persistent storage with organized keys and JSON serialization
/// TODO: Upgrade to SQLite/Hive when dependencies are added to pubspec.yaml
class CommunityDatabase {
  static final CommunityDatabase _instance = CommunityDatabase._internal();
  factory CommunityDatabase() => _instance;
  CommunityDatabase._internal();

  SharedPreferences? _prefs;
  final Completer<SharedPreferences> _prefsCompleter = Completer<SharedPreferences>();

  /// Database keys for organized storage
  static const String _postsKey = 'community_posts_v2';
  static const String _profilesKey = 'community_profiles_v2';
  static const String _engagementsKey = 'community_engagements_v2';
  static const String _relationshipsKey = 'community_relationships_v2';
  static const String _commentsKey = 'community_comments_v2';
  static const String _actionsKey = 'community_actions_v2';
  static const String _feedOrderKey = 'community_feed_order_v2';
  static const String _syncMetadataKey = 'community_sync_metadata_v2';

  /// Initialize the database
  Future<void> initialize() async {
    if (_prefs != null) return;

    try {
      _prefs = await SharedPreferences.getInstance();

      if (!_prefsCompleter.isCompleted) {
        _prefsCompleter.complete(_prefs!);
      }

      debugPrint('CommunityDatabase: Initialized successfully with SharedPreferences');
    } catch (e) {
      debugPrint('CommunityDatabase: Failed to initialize - $e');
      rethrow;
    }
  }

  /// Get SharedPreferences instance
  Future<SharedPreferences> get database async {
    if (_prefs != null) return _prefs!;
    if (_prefsCompleter.isCompleted) return _prefsCompleter.future;
    await initialize();
    return _prefs!;
  }

  /// Save posts to database
  Future<void> savePosts(List<CommunityPostState> posts) async {
    final prefs = await database;
    final Map<String, dynamic> postsMap = {};

    for (final postState in posts) {
      postsMap[postState.post.id] = {
        'post': postState.post.toJson(),
        'last_updated': postState.lastUpdated.toIso8601String(),
        'is_optimistic': postState.isOptimistic,
        'sync_status': postState.syncStatus.name,
        'conflict_data': postState.conflictData,
      };
    }

    await prefs.setString(_postsKey, jsonEncode(postsMap));
    debugPrint('CommunityDatabase: Saved ${posts.length} posts');
  }

  /// Load posts from database
  Future<List<CommunityPostState>> loadPosts({int? limit, int? offset}) async {
    final prefs = await database;
    final String? postsJson = prefs.getString(_postsKey);
    
    if (postsJson == null) return [];

    try {
      final Map<String, dynamic> postsMap = jsonDecode(postsJson);
      final List<CommunityPostState> posts = [];

      for (final entry in postsMap.entries) {
        final data = entry.value as Map<String, dynamic>;
        final post = PostEntity.fromJson(data['post']);
        final postState = CommunityPostState(
          post: post,
          lastUpdated: DateTime.parse(data['last_updated']),
          isOptimistic: data['is_optimistic'] ?? false,
          syncStatus: SyncStatus.values.byName(data['sync_status'] ?? 'synced'),
          conflictData: data['conflict_data'],
        );
        posts.add(postState);
      }

      // Sort by creation date (newest first)
      posts.sort((a, b) => b.post.createdAt.compareTo(a.post.createdAt));

      // Apply pagination
      if (offset != null && limit != null) {
        final startIndex = offset;
        final endIndex = (startIndex + limit).clamp(0, posts.length);
        return posts.sublist(startIndex, endIndex);
      } else if (limit != null) {
        return posts.take(limit).toList();
      }

      return posts;
    } catch (e) {
      debugPrint('CommunityDatabase: Error loading posts - $e');
      return [];
    }
  }

  /// Save profiles to database
  Future<void> saveProfiles(List<CommunityProfileState> profiles) async {
    final prefs = await database;
    final Map<String, dynamic> profilesMap = {};

    for (final profileState in profiles) {
      profilesMap[profileState.profile.userId] = {
        'profile': profileState.profile.toJson(),
        'last_updated': profileState.lastUpdated.toIso8601String(),
        'is_optimistic': profileState.isOptimistic,
        'sync_status': profileState.syncStatus.name,
        'conflict_data': profileState.conflictData,
      };
    }

    await prefs.setString(_profilesKey, jsonEncode(profilesMap));
    debugPrint('CommunityDatabase: Saved ${profiles.length} profiles');
  }

  /// Load profiles from database
  Future<List<CommunityProfileState>> loadProfiles({List<String>? userIds}) async {
    final prefs = await database;
    final String? profilesJson = prefs.getString(_profilesKey);
    
    if (profilesJson == null) return [];

    try {
      final Map<String, dynamic> profilesMap = jsonDecode(profilesJson);
      final List<CommunityProfileState> profiles = [];

      for (final entry in profilesMap.entries) {
        if (userIds != null && !userIds.contains(entry.key)) continue;

        final data = entry.value as Map<String, dynamic>;
        final profile = CommunityProfileEntity.fromJson(data['profile']);
        final profileState = CommunityProfileState(
          profile: profile,
          lastUpdated: DateTime.parse(data['last_updated']),
          isOptimistic: data['is_optimistic'] ?? false,
          syncStatus: SyncStatus.values.byName(data['sync_status'] ?? 'synced'),
          conflictData: data['conflict_data'],
        );
        profiles.add(profileState);
      }

      return profiles;
    } catch (e) {
      debugPrint('CommunityDatabase: Error loading profiles - $e');
      return [];
    }
  }

  /// Save engagements to database
  Future<void> saveEngagements(List<EngagementState> engagements) async {
    final prefs = await database;
    final Map<String, dynamic> engagementsMap = {};

    for (final engagement in engagements) {
      final key = '${engagement.postId}_${engagement.userId}';
      engagementsMap[key] = {
        'post_id': engagement.postId,
        'user_id': engagement.userId,
        'is_liked': engagement.isLiked,
        'like_count': engagement.likeCount,
        'last_updated': engagement.lastUpdated.toIso8601String(),
        'is_optimistic': engagement.isOptimistic,
        'sync_status': engagement.syncStatus.name,
      };
    }

    await prefs.setString(_engagementsKey, jsonEncode(engagementsMap));
    debugPrint('CommunityDatabase: Saved ${engagements.length} engagements');
  }

  /// Load engagements from database
  Future<List<EngagementState>> loadEngagements({String? postId, String? userId}) async {
    final prefs = await database;
    final String? engagementsJson = prefs.getString(_engagementsKey);
    
    if (engagementsJson == null) return [];

    try {
      final Map<String, dynamic> engagementsMap = jsonDecode(engagementsJson);
      final List<EngagementState> engagements = [];

      for (final entry in engagementsMap.entries) {
        final data = entry.value as Map<String, dynamic>;
        
        // Filter by postId or userId if specified
        if (postId != null && data['post_id'] != postId) continue;
        if (userId != null && data['user_id'] != userId) continue;

        final engagement = EngagementState(
          postId: data['post_id'],
          userId: data['user_id'],
          isLiked: data['is_liked'],
          likeCount: data['like_count'],
          lastUpdated: DateTime.parse(data['last_updated']),
          isOptimistic: data['is_optimistic'] ?? false,
          syncStatus: SyncStatus.values.byName(data['sync_status'] ?? 'synced'),
        );
        engagements.add(engagement);
      }

      return engagements;
    } catch (e) {
      debugPrint('CommunityDatabase: Error loading engagements - $e');
      return [];
    }
  }

  /// Save social relationships to database
  Future<void> saveSocialRelationships(List<SocialRelationshipState> relationships) async {
    final prefs = await database;
    final Map<String, dynamic> relationshipsMap = {};

    for (final relationship in relationships) {
      final key = '${relationship.userId}_${relationship.targetUserId}';
      relationshipsMap[key] = {
        'user_id': relationship.userId,
        'target_user_id': relationship.targetUserId,
        'is_following': relationship.isFollowing,
        'is_blocked': relationship.isBlocked,
        'last_updated': relationship.lastUpdated.toIso8601String(),
        'is_optimistic': relationship.isOptimistic,
        'sync_status': relationship.syncStatus.name,
      };
    }

    await prefs.setString(_relationshipsKey, jsonEncode(relationshipsMap));
    debugPrint('CommunityDatabase: Saved ${relationships.length} relationships');
  }

  /// Load social relationships from database
  Future<List<SocialRelationshipState>> loadSocialRelationships({String? userId, String? targetUserId}) async {
    final prefs = await database;
    final String? relationshipsJson = prefs.getString(_relationshipsKey);
    
    if (relationshipsJson == null) return [];

    try {
      final Map<String, dynamic> relationshipsMap = jsonDecode(relationshipsJson);
      final List<SocialRelationshipState> relationships = [];

      for (final entry in relationshipsMap.entries) {
        final data = entry.value as Map<String, dynamic>;
        
        // Filter by userId or targetUserId if specified
        if (userId != null && data['user_id'] != userId) continue;
        if (targetUserId != null && data['target_user_id'] != targetUserId) continue;

        final relationship = SocialRelationshipState(
          userId: data['user_id'],
          targetUserId: data['target_user_id'],
          isFollowing: data['is_following'],
          isBlocked: data['is_blocked'],
          lastUpdated: DateTime.parse(data['last_updated']),
          isOptimistic: data['is_optimistic'] ?? false,
          syncStatus: SyncStatus.values.byName(data['sync_status'] ?? 'synced'),
        );
        relationships.add(relationship);
      }

      return relationships;
    } catch (e) {
      debugPrint('CommunityDatabase: Error loading relationships - $e');
      return [];
    }
  }

  /// Save action queue for offline support
  Future<void> saveActions(List<CommunityAction> actions) async {
    final prefs = await database;
    final Map<String, dynamic> actionsMap = {};

    for (final action in actions) {
      actionsMap[action.id] = {
        'id': action.id,
        'action_type': action.type.name,
        'payload': action.payload,
        'timestamp': action.timestamp.toIso8601String(),
        'status': action.status.name,
        'retry_count': action.retryCount,
        'user_id': action.userId,
        'target_id': action.targetId,
      };
    }

    await prefs.setString(_actionsKey, jsonEncode(actionsMap));
    debugPrint('CommunityDatabase: Saved ${actions.length} actions');
  }

  /// Load pending actions from database
  Future<List<CommunityAction>> loadPendingActions() async {
    final prefs = await database;
    final String? actionsJson = prefs.getString(_actionsKey);
    
    if (actionsJson == null) return [];

    try {
      final Map<String, dynamic> actionsMap = jsonDecode(actionsJson);
      final List<CommunityAction> actions = [];

      for (final entry in actionsMap.entries) {
        final data = entry.value as Map<String, dynamic>;
        final status = SyncStatus.values.byName(data['status'] ?? 'pending');
        
        // Only load pending or failed actions
        if (status == SyncStatus.pending || status == SyncStatus.failed) {
          final action = CommunityAction(
            id: data['id'],
            type: CommunityActionType.values.byName(data['action_type']),
            payload: data['payload'],
            timestamp: DateTime.parse(data['timestamp']),
            status: status,
            retryCount: data['retry_count'] ?? 0,
            userId: data['user_id'],
            targetId: data['target_id'],
          );
          actions.add(action);
        }
      }

      // Sort by timestamp (oldest first)
      actions.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return actions;
    } catch (e) {
      debugPrint('CommunityDatabase: Error loading actions - $e');
      return [];
    }
  }

  /// Update action status
  Future<void> updateActionStatus(String actionId, SyncStatus status, {int? retryCount}) async {
    final prefs = await database;
    final String? actionsJson = prefs.getString(_actionsKey);
    
    if (actionsJson == null) return;

    try {
      final Map<String, dynamic> actionsMap = jsonDecode(actionsJson);
      
      if (actionsMap.containsKey(actionId)) {
        actionsMap[actionId]['status'] = status.name;
        if (retryCount != null) {
          actionsMap[actionId]['retry_count'] = retryCount;
        }
        
        await prefs.setString(_actionsKey, jsonEncode(actionsMap));
        debugPrint('CommunityDatabase: Updated action $actionId status to ${status.name}');
      }
    } catch (e) {
      debugPrint('CommunityDatabase: Error updating action status - $e');
    }
  }

  /// Save feed order
  Future<void> saveFeedOrder(List<String> postIds) async {
    final prefs = await database;
    final feedData = {
      'post_ids': postIds,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_feedOrderKey, jsonEncode(feedData));
    debugPrint('CommunityDatabase: Saved feed order with ${postIds.length} posts');
  }

  /// Load feed order
  Future<List<String>> loadFeedOrder() async {
    final prefs = await database;
    final String? feedJson = prefs.getString(_feedOrderKey);
    
    if (feedJson == null) return [];

    try {
      final Map<String, dynamic> feedData = jsonDecode(feedJson);
      return List<String>.from(feedData['post_ids'] ?? []);
    } catch (e) {
      debugPrint('CommunityDatabase: Error loading feed order - $e');
      return [];
    }
  }

  /// Save sync metadata
  Future<void> saveSyncMetadata(String key, String value) async {
    final prefs = await database;
    final String? metadataJson = prefs.getString(_syncMetadataKey);
    
    Map<String, dynamic> metadata = {};
    if (metadataJson != null) {
      try {
        metadata = jsonDecode(metadataJson);
      } catch (e) {
        debugPrint('CommunityDatabase: Error parsing sync metadata - $e');
      }
    }
    
    metadata[key] = {
      'value': value,
      'last_updated': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_syncMetadataKey, jsonEncode(metadata));
    debugPrint('CommunityDatabase: Saved sync metadata for key: $key');
  }

  /// Load sync metadata
  Future<String?> loadSyncMetadata(String key) async {
    final prefs = await database;
    final String? metadataJson = prefs.getString(_syncMetadataKey);
    
    if (metadataJson == null) return null;

    try {
      final Map<String, dynamic> metadata = jsonDecode(metadataJson);
      final keyData = metadata[key] as Map<String, dynamic>?;
      return keyData?['value'] as String?;
    } catch (e) {
      debugPrint('CommunityDatabase: Error loading sync metadata - $e');
      return null;
    }
  }

  /// Clear all data (for logout)
  Future<void> clearAllData() async {
    final prefs = await database;
    
    await Future.wait([
      prefs.remove(_postsKey),
      prefs.remove(_profilesKey),
      prefs.remove(_engagementsKey),
      prefs.remove(_relationshipsKey),
      prefs.remove(_commentsKey),
      prefs.remove(_actionsKey),
      prefs.remove(_feedOrderKey),
      prefs.remove(_syncMetadataKey),
    ]);
    
    debugPrint('CommunityDatabase: All data cleared');
  }

  /// Delete post and related data
  Future<void> deletePost(String postId) async {
    final prefs = await database;
    
    // Remove from posts
    final String? postsJson = prefs.getString(_postsKey);
    if (postsJson != null) {
      try {
        final Map<String, dynamic> postsMap = jsonDecode(postsJson);
        postsMap.remove(postId);
        await prefs.setString(_postsKey, jsonEncode(postsMap));
      } catch (e) {
        debugPrint('CommunityDatabase: Error removing post - $e');
      }
    }
    
    // Remove related engagements
    final String? engagementsJson = prefs.getString(_engagementsKey);
    if (engagementsJson != null) {
      try {
        final Map<String, dynamic> engagementsMap = jsonDecode(engagementsJson);
        final keysToRemove = <String>[];
        
        for (final entry in engagementsMap.entries) {
          final data = entry.value as Map<String, dynamic>;
          if (data['post_id'] == postId) {
            keysToRemove.add(entry.key);
          }
        }
        
        for (final key in keysToRemove) {
          engagementsMap.remove(key);
        }
        
        await prefs.setString(_engagementsKey, jsonEncode(engagementsMap));
      } catch (e) {
        debugPrint('CommunityDatabase: Error removing engagements - $e');
      }
    }
    
    // Remove from feed order
    final String? feedJson = prefs.getString(_feedOrderKey);
    if (feedJson != null) {
      try {
        final Map<String, dynamic> feedData = jsonDecode(feedJson);
        final List<String> postIds = List<String>.from(feedData['post_ids'] ?? []);
        postIds.remove(postId);
        feedData['post_ids'] = postIds;
        feedData['updated_at'] = DateTime.now().toIso8601String();
        await prefs.setString(_feedOrderKey, jsonEncode(feedData));
      } catch (e) {
        debugPrint('CommunityDatabase: Error updating feed order - $e');
      }
    }
    
    debugPrint('CommunityDatabase: Deleted post $postId and related data');
  }

  /// Get database statistics
  Future<Map<String, int>> getStatistics() async {
    final prefs = await database;
    final stats = <String, int>{};
    
    try {
      // Count posts
      final String? postsJson = prefs.getString(_postsKey);
      if (postsJson != null) {
        final Map<String, dynamic> postsMap = jsonDecode(postsJson);
        stats['posts'] = postsMap.length;
      }
      
      // Count profiles
      final String? profilesJson = prefs.getString(_profilesKey);
      if (profilesJson != null) {
        final Map<String, dynamic> profilesMap = jsonDecode(profilesJson);
        stats['profiles'] = profilesMap.length;
      }
      
      // Count engagements
      final String? engagementsJson = prefs.getString(_engagementsKey);
      if (engagementsJson != null) {
        final Map<String, dynamic> engagementsMap = jsonDecode(engagementsJson);
        stats['engagements'] = engagementsMap.length;
      }
      
      // Count relationships
      final String? relationshipsJson = prefs.getString(_relationshipsKey);
      if (relationshipsJson != null) {
        final Map<String, dynamic> relationshipsMap = jsonDecode(relationshipsJson);
        stats['relationships'] = relationshipsMap.length;
      }
      
      // Count pending actions
      final pendingActions = await loadPendingActions();
      stats['pending_actions'] = pendingActions.length;
      
    } catch (e) {
      debugPrint('CommunityDatabase: Error getting statistics - $e');
    }
    
    return stats;
  }

  /// Close database connection (no-op for SharedPreferences)
  Future<void> close() async {
    // SharedPreferences doesn't need explicit closing
    debugPrint('CommunityDatabase: Connection closed');
  }
}