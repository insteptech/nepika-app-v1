import 'package:flutter/foundation.dart';
import '../state/community_state_models.dart';
import '../../domain/community/entities/community_entities.dart';

/// Conflict resolution strategies for community data synchronization
/// Handles conflicts between local optimistic updates and server responses
class ConflictResolver {
  static final ConflictResolver _instance = ConflictResolver._internal();
  factory ConflictResolver() => _instance;
  ConflictResolver._internal();

  /// Resolve post conflicts
  PostEntity resolvePostConflict({
    required PostEntity localPost,
    required PostEntity serverPost,
    required ConflictResolutionStrategy strategy,
  }) {
    switch (strategy) {
      case ConflictResolutionStrategy.serverWins:
        return _serverWinsPost(localPost, serverPost);
      
      case ConflictResolutionStrategy.clientWins:
        return _clientWinsPost(localPost, serverPost);
      
      case ConflictResolutionStrategy.merge:
        return _mergePost(localPost, serverPost);
      
      case ConflictResolutionStrategy.lastWriteWins:
        return _lastWriteWinsPost(localPost, serverPost);
      
      case ConflictResolutionStrategy.manual:
        return _flagForManualResolution(localPost, serverPost);
    }
  }

  /// Resolve engagement conflicts
  EngagementState resolveEngagementConflict({
    required EngagementState localEngagement,
    required EngagementState serverEngagement,
    required ConflictResolutionStrategy strategy,
  }) {
    switch (strategy) {
      case ConflictResolutionStrategy.serverWins:
        return _serverWinsEngagement(localEngagement, serverEngagement);
      
      case ConflictResolutionStrategy.clientWins:
        return _clientWinsEngagement(localEngagement, serverEngagement);
      
      case ConflictResolutionStrategy.merge:
        return _mergeEngagement(localEngagement, serverEngagement);
      
      case ConflictResolutionStrategy.lastWriteWins:
        return _lastWriteWinsEngagement(localEngagement, serverEngagement);
      
      case ConflictResolutionStrategy.manual:
        return _flagEngagementForManualResolution(localEngagement, serverEngagement);
    }
  }

  /// Resolve profile conflicts
  CommunityProfileEntity resolveProfileConflict({
    required CommunityProfileEntity localProfile,
    required CommunityProfileEntity serverProfile,
    required ConflictResolutionStrategy strategy,
  }) {
    switch (strategy) {
      case ConflictResolutionStrategy.serverWins:
        return _serverWinsProfile(localProfile, serverProfile);
      
      case ConflictResolutionStrategy.clientWins:
        return _clientWinsProfile(localProfile, serverProfile);
      
      case ConflictResolutionStrategy.merge:
        return _mergeProfile(localProfile, serverProfile);
      
      case ConflictResolutionStrategy.lastWriteWins:
        return _lastWriteWinsProfile(localProfile, serverProfile);
      
      case ConflictResolutionStrategy.manual:
        return _flagProfileForManualResolution(localProfile, serverProfile);
    }
  }

  /// Resolve social relationship conflicts
  SocialRelationshipState resolveRelationshipConflict({
    required SocialRelationshipState localRelationship,
    required SocialRelationshipState serverRelationship,
    required ConflictResolutionStrategy strategy,
  }) {
    switch (strategy) {
      case ConflictResolutionStrategy.serverWins:
        return _serverWinsRelationship(localRelationship, serverRelationship);
      
      case ConflictResolutionStrategy.clientWins:
        return _clientWinsRelationship(localRelationship, serverRelationship);
      
      case ConflictResolutionStrategy.merge:
        return _mergeRelationship(localRelationship, serverRelationship);
      
      case ConflictResolutionStrategy.lastWriteWins:
        return _lastWriteWinsRelationship(localRelationship, serverRelationship);
      
      case ConflictResolutionStrategy.manual:
        return _flagRelationshipForManualResolution(localRelationship, serverRelationship);
    }
  }

  /// Determine conflict resolution strategy based on conflict type
  ConflictResolutionStrategy determineStrategy({
    required ConflictType conflictType,
    required Map<String, dynamic> context,
  }) {
    switch (conflictType) {
      case ConflictType.likeCount:
        // For like counts, server always wins as it's the source of truth
        return ConflictResolutionStrategy.serverWins;
      
      case ConflictType.postContent:
        // For post content, use last write wins based on timestamp
        return ConflictResolutionStrategy.lastWriteWins;
      
      case ConflictType.userProfile:
        // For user profiles, merge compatible fields, server wins for conflicts
        return ConflictResolutionStrategy.merge;
      
      case ConflictType.followStatus:
        // For follow status, server wins as it manages relationships
        return ConflictResolutionStrategy.serverWins;
      
      case ConflictType.blockStatus:
        // For block status, server wins for security reasons
        return ConflictResolutionStrategy.serverWins;
      
      case ConflictType.commentCount:
        // For comment counts, server always wins
        return ConflictResolutionStrategy.serverWins;
      
      case ConflictType.postDeletion:
        // For deletions, server decision is final
        return ConflictResolutionStrategy.serverWins;
      
      case ConflictType.userPermissions:
        // For permissions, server always wins for security
        return ConflictResolutionStrategy.serverWins;
    }
  }

  /// Post conflict resolution methods

  PostEntity _serverWinsPost(PostEntity local, PostEntity server) {
    debugPrint('ConflictResolver: Server wins for post ${server.id}');
    return server;
  }

  PostEntity _clientWinsPost(PostEntity local, PostEntity server) {
    debugPrint('ConflictResolver: Client wins for post ${local.id}');
    return local;
  }

  PostEntity _mergePost(PostEntity local, PostEntity server) {
    debugPrint('ConflictResolver: Merging post ${local.id}');
    
    // Merge strategy: Server wins for metrics, client for content if newer
    return PostEntity(
      id: server.id,
      userId: server.userId,
      tenantId: server.tenantId,
      content: local.updatedAt != null && server.updatedAt != null && 
               local.updatedAt!.isAfter(server.updatedAt!) ? local.content : server.content,
      parentPostId: server.parentPostId,
      likeCount: server.likeCount, // Server always wins for metrics
      commentCount: server.commentCount, // Server always wins for metrics
      isEdited: server.isEdited,
      isDeleted: server.isDeleted, // Server wins for deletion status
      createdAt: server.createdAt,
      updatedAt: server.updatedAt,
      username: server.username,
      userAvatar: server.userAvatar,
      isLikedByUser: server.isLikedByUser, // Server wins for engagement
    );
  }

  PostEntity _lastWriteWinsPost(PostEntity local, PostEntity server) {
    final localTime = local.updatedAt ?? local.createdAt;
    final serverTime = server.updatedAt ?? server.createdAt;
    
    if (localTime.isAfter(serverTime)) {
      debugPrint('ConflictResolver: Local post ${local.id} is newer, keeping local');
      return local;
    } else {
      debugPrint('ConflictResolver: Server post ${server.id} is newer, keeping server');
      return server;
    }
  }

  PostEntity _flagForManualResolution(PostEntity local, PostEntity server) {
    debugPrint('ConflictResolver: Post ${local.id} flagged for manual resolution');
    
    // Return server version but mark it as needing manual resolution
    return server; // In a real app, this would include conflict metadata
  }

  /// Engagement conflict resolution methods

  EngagementState _serverWinsEngagement(EngagementState local, EngagementState server) {
    debugPrint('ConflictResolver: Server wins for engagement ${server.postId}_${server.userId}');
    return server.copyWith(syncStatus: SyncStatus.synced);
  }

  EngagementState _clientWinsEngagement(EngagementState local, EngagementState server) {
    debugPrint('ConflictResolver: Client wins for engagement ${local.postId}_${local.userId}');
    return local.copyWith(syncStatus: SyncStatus.synced);
  }

  EngagementState _mergeEngagement(EngagementState local, EngagementState server) {
    debugPrint('ConflictResolver: Merging engagement ${local.postId}_${local.userId}');
    
    // For engagements, server wins for counts, use newer timestamp for like status
    return EngagementState(
      postId: server.postId,
      userId: server.userId,
      isLiked: local.lastUpdated.isAfter(server.lastUpdated) ? local.isLiked : server.isLiked,
      likeCount: server.likeCount, // Server always wins for counts
      lastUpdated: DateTime.now(),
      syncStatus: SyncStatus.synced,
    );
  }

  EngagementState _lastWriteWinsEngagement(EngagementState local, EngagementState server) {
    if (local.lastUpdated.isAfter(server.lastUpdated)) {
      debugPrint('ConflictResolver: Local engagement is newer');
      return local.copyWith(syncStatus: SyncStatus.synced);
    } else {
      debugPrint('ConflictResolver: Server engagement is newer');
      return server.copyWith(syncStatus: SyncStatus.synced);
    }
  }

  EngagementState _flagEngagementForManualResolution(EngagementState local, EngagementState server) {
    debugPrint('ConflictResolver: Engagement flagged for manual resolution');
    return server.copyWith(
      syncStatus: SyncStatus.conflict,
    );
  }

  /// Profile conflict resolution methods

  CommunityProfileEntity _serverWinsProfile(CommunityProfileEntity local, CommunityProfileEntity server) {
    debugPrint('ConflictResolver: Server wins for profile ${server.userId}');
    return server;
  }

  CommunityProfileEntity _clientWinsProfile(CommunityProfileEntity local, CommunityProfileEntity server) {
    debugPrint('ConflictResolver: Client wins for profile ${local.userId}');
    return local;
  }

  CommunityProfileEntity _mergeProfile(CommunityProfileEntity local, CommunityProfileEntity server) {
    debugPrint('ConflictResolver: Merging profile ${local.userId}');
    
    // Merge strategy: Server wins for metrics and permissions, client for user-editable fields if newer
    final localNewer = local.updatedAt != null && server.updatedAt != null && 
                      local.updatedAt!.isAfter(server.updatedAt!);
    
    return CommunityProfileEntity(
      id: server.id,
      userId: server.userId,
      tenantId: server.tenantId,
      username: localNewer ? local.username : server.username,
      bio: localNewer ? local.bio : server.bio,
      profileImageUrl: localNewer ? local.profileImageUrl : server.profileImageUrl,
      bannerImageUrl: localNewer ? local.bannerImageUrl : server.bannerImageUrl,
      isPrivate: server.isPrivate, // Server wins for privacy settings
      isVerified: server.isVerified, // Server wins for verification
      followersCount: server.followersCount, // Server wins for metrics
      followingCount: server.followingCount, // Server wins for metrics
      postsCount: server.postsCount, // Server wins for metrics
      settings: server.settings, // Server wins for settings
      isSelf: server.isSelf, // Server wins for relationship info
      isFollowing: server.isFollowing, // Server wins for relationship info
      createdAt: server.createdAt,
      updatedAt: server.updatedAt,
    );
  }

  CommunityProfileEntity _lastWriteWinsProfile(CommunityProfileEntity local, CommunityProfileEntity server) {
    final localTime = local.updatedAt ?? local.createdAt;
    final serverTime = server.updatedAt ?? server.createdAt;
    
    if (localTime.isAfter(serverTime)) {
      debugPrint('ConflictResolver: Local profile is newer');
      return local;
    } else {
      debugPrint('ConflictResolver: Server profile is newer');
      return server;
    }
  }

  CommunityProfileEntity _flagProfileForManualResolution(CommunityProfileEntity local, CommunityProfileEntity server) {
    debugPrint('ConflictResolver: Profile ${local.userId} flagged for manual resolution');
    return server; // In a real app, this would include conflict metadata
  }

  /// Relationship conflict resolution methods

  SocialRelationshipState _serverWinsRelationship(SocialRelationshipState local, SocialRelationshipState server) {
    debugPrint('ConflictResolver: Server wins for relationship ${server.userId}_${server.targetUserId}');
    return server.copyWith(syncStatus: SyncStatus.synced);
  }

  SocialRelationshipState _clientWinsRelationship(SocialRelationshipState local, SocialRelationshipState server) {
    debugPrint('ConflictResolver: Client wins for relationship ${local.userId}_${local.targetUserId}');
    return local.copyWith(syncStatus: SyncStatus.synced);
  }

  SocialRelationshipState _mergeRelationship(SocialRelationshipState local, SocialRelationshipState server) {
    debugPrint('ConflictResolver: Merging relationship ${local.userId}_${local.targetUserId}');
    
    // For relationships, use the newer state
    if (local.lastUpdated.isAfter(server.lastUpdated)) {
      return local.copyWith(syncStatus: SyncStatus.synced);
    } else {
      return server.copyWith(syncStatus: SyncStatus.synced);
    }
  }

  SocialRelationshipState _lastWriteWinsRelationship(SocialRelationshipState local, SocialRelationshipState server) {
    if (local.lastUpdated.isAfter(server.lastUpdated)) {
      debugPrint('ConflictResolver: Local relationship is newer');
      return local.copyWith(syncStatus: SyncStatus.synced);
    } else {
      debugPrint('ConflictResolver: Server relationship is newer');
      return server.copyWith(syncStatus: SyncStatus.synced);
    }
  }

  SocialRelationshipState _flagRelationshipForManualResolution(SocialRelationshipState local, SocialRelationshipState server) {
    debugPrint('ConflictResolver: Relationship flagged for manual resolution');
    return server.copyWith(
      syncStatus: SyncStatus.conflict,
    );
  }

  /// Utility methods

  /// Detect if there's a conflict between local and server data
  bool hasConflict<T>({
    required T local,
    required T server,
    required ConflictDetector<T> detector,
  }) {
    return detector(local, server);
  }

  /// Get list of conflicted fields
  List<String> getConflictedFields({
    required Map<String, dynamic> local,
    required Map<String, dynamic> server,
    List<String> ignoredFields = const [],
  }) {
    final conflicts = <String>[];
    
    for (final key in local.keys) {
      if (ignoredFields.contains(key)) continue;
      if (server.containsKey(key) && local[key] != server[key]) {
        conflicts.add(key);
      }
    }
    
    return conflicts;
  }

  /// Create conflict metadata for UI
  Map<String, dynamic> createConflictMetadata({
    required String entityType,
    required String entityId,
    required List<String> conflictedFields,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
  }) {
    return {
      'entity_type': entityType,
      'entity_id': entityId,
      'conflicted_fields': conflictedFields,
      'local_data': localData,
      'server_data': serverData,
      'detected_at': DateTime.now().toIso8601String(),
      'resolution_status': 'pending',
    };
  }
}

/// Conflict resolution strategies
enum ConflictResolutionStrategy {
  serverWins,     // Server data always takes precedence
  clientWins,     // Client data always takes precedence
  merge,          // Intelligently merge both datasets
  lastWriteWins,  // Most recent timestamp wins
  manual,         // Flag for manual user resolution
}

/// Types of conflicts that can occur
enum ConflictType {
  likeCount,
  postContent,
  userProfile,
  followStatus,
  blockStatus,
  commentCount,
  postDeletion,
  userPermissions,
}

/// Conflict detector function type
typedef ConflictDetector<T> = bool Function(T local, T server);

/// Predefined conflict detectors

/// Post conflict detector
bool postConflictDetector(PostEntity local, PostEntity server) {
  return local.content != server.content ||
         local.likeCount != server.likeCount ||
         local.commentCount != server.commentCount ||
         local.isLikedByUser != server.isLikedByUser ||
         local.isDeleted != server.isDeleted;
}

/// Engagement conflict detector
bool engagementConflictDetector(EngagementState local, EngagementState server) {
  return local.isLiked != server.isLiked ||
         local.likeCount != server.likeCount;
}

/// Profile conflict detector
bool profileConflictDetector(CommunityProfileEntity local, CommunityProfileEntity server) {
  return local.username != server.username ||
         local.bio != server.bio ||
         local.profileImageUrl != server.profileImageUrl ||
         local.followersCount != server.followersCount ||
         local.followingCount != server.followingCount ||
         local.isFollowing != server.isFollowing;
}

/// Relationship conflict detector
bool relationshipConflictDetector(SocialRelationshipState local, SocialRelationshipState server) {
  return local.isFollowing != server.isFollowing ||
         local.isBlocked != server.isBlocked;
}