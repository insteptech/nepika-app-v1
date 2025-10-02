import 'package:equatable/equatable.dart';
import '../../domain/community/entities/community_entities.dart';

/// Unified data models for the hybrid community state architecture
/// These models work across all three layers (RAM, DB, Server)

/// Enum for action types that can be queued for offline processing
enum CommunityActionType {
  createPost,
  updatePost,
  deletePost,
  likePost,
  unlikePost,
  createComment,
  updateComment,
  deleteComment,
  followUser,
  unfollowUser,
  blockUser,
  unblockUser,
  updateProfile,
  uploadImage,
}

/// Enum for sync status tracking
enum SyncStatus {
  pending,    // Action queued, not yet sent to server
  syncing,    // Currently being processed by server
  synced,     // Successfully synced with server
  failed,     // Failed to sync, needs retry
  conflict,   // Conflict detected, needs resolution
}

/// Action queue item for offline support and background sync
class CommunityAction extends Equatable {
  final String id;
  final CommunityActionType type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final SyncStatus status;
  final int retryCount;
  final String? userId;
  final String? targetId; // postId, userId, etc.

  const CommunityAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.timestamp,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    this.userId,
    this.targetId,
  });

  CommunityAction copyWith({
    String? id,
    CommunityActionType? type,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
    SyncStatus? status,
    int? retryCount,
    String? userId,
    String? targetId,
  }) {
    return CommunityAction(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      userId: userId ?? this.userId,
      targetId: targetId ?? this.targetId,
    );
  }

  @override
  List<Object?> get props => [id, type, payload, timestamp, status, retryCount, userId, targetId];
}

/// Enhanced post model with additional metadata for state management
class CommunityPostState extends Equatable {
  final PostEntity post;
  final DateTime lastUpdated;
  final bool isOptimistic; // True if this is an optimistic update
  final SyncStatus syncStatus;
  final Map<String, dynamic>? conflictData; // Server data when conflict occurs

  const CommunityPostState({
    required this.post,
    required this.lastUpdated,
    this.isOptimistic = false,
    this.syncStatus = SyncStatus.synced,
    this.conflictData,
  });

  CommunityPostState copyWith({
    PostEntity? post,
    DateTime? lastUpdated,
    bool? isOptimistic,
    SyncStatus? syncStatus,
    Map<String, dynamic>? conflictData,
  }) {
    return CommunityPostState(
      post: post ?? this.post,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isOptimistic: isOptimistic ?? this.isOptimistic,
      syncStatus: syncStatus ?? this.syncStatus,
      conflictData: conflictData ?? this.conflictData,
    );
  }

  @override
  List<Object?> get props => [post, lastUpdated, isOptimistic, syncStatus, conflictData];
}

/// Enhanced profile model with state management metadata
class CommunityProfileState extends Equatable {
  final CommunityProfileEntity profile;
  final DateTime lastUpdated;
  final bool isOptimistic;
  final SyncStatus syncStatus;
  final Map<String, dynamic>? conflictData;

  const CommunityProfileState({
    required this.profile,
    required this.lastUpdated,
    this.isOptimistic = false,
    this.syncStatus = SyncStatus.synced,
    this.conflictData,
  });

  CommunityProfileState copyWith({
    CommunityProfileEntity? profile,
    DateTime? lastUpdated,
    bool? isOptimistic,
    SyncStatus? syncStatus,
    Map<String, dynamic>? conflictData,
  }) {
    return CommunityProfileState(
      profile: profile ?? this.profile,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isOptimistic: isOptimistic ?? this.isOptimistic,
      syncStatus: syncStatus ?? this.syncStatus,
      conflictData: conflictData ?? this.conflictData,
    );
  }

  @override
  List<Object?> get props => [profile, lastUpdated, isOptimistic, syncStatus, conflictData];
}

/// Social relationship state (follows, blocks)
class SocialRelationshipState extends Equatable {
  final String userId;
  final String targetUserId;
  final bool isFollowing;
  final bool isBlocked;
  final DateTime lastUpdated;
  final bool isOptimistic;
  final SyncStatus syncStatus;

  const SocialRelationshipState({
    required this.userId,
    required this.targetUserId,
    required this.isFollowing,
    required this.isBlocked,
    required this.lastUpdated,
    this.isOptimistic = false,
    this.syncStatus = SyncStatus.synced,
  });

  SocialRelationshipState copyWith({
    String? userId,
    String? targetUserId,
    bool? isFollowing,
    bool? isBlocked,
    DateTime? lastUpdated,
    bool? isOptimistic,
    SyncStatus? syncStatus,
  }) {
    return SocialRelationshipState(
      userId: userId ?? this.userId,
      targetUserId: targetUserId ?? this.targetUserId,
      isFollowing: isFollowing ?? this.isFollowing,
      isBlocked: isBlocked ?? this.isBlocked,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isOptimistic: isOptimistic ?? this.isOptimistic,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [userId, targetUserId, isFollowing, isBlocked, lastUpdated, isOptimistic, syncStatus];
}

/// Engagement state for likes and reactions
class EngagementState extends Equatable {
  final String postId;
  final String userId;
  final bool isLiked;
  final int likeCount;
  final DateTime lastUpdated;
  final bool isOptimistic;
  final SyncStatus syncStatus;

  const EngagementState({
    required this.postId,
    required this.userId,
    required this.isLiked,
    required this.likeCount,
    required this.lastUpdated,
    this.isOptimistic = false,
    this.syncStatus = SyncStatus.synced,
  });

  EngagementState copyWith({
    String? postId,
    String? userId,
    bool? isLiked,
    int? likeCount,
    DateTime? lastUpdated,
    bool? isOptimistic,
    SyncStatus? syncStatus,
  }) {
    return EngagementState(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isOptimistic: isOptimistic ?? this.isOptimistic,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [postId, userId, isLiked, likeCount, lastUpdated, isOptimistic, syncStatus];
}

/// Comment state with threading support
class CommentState extends Equatable {
  final PostEntity comment;
  final String parentPostId;
  final DateTime lastUpdated;
  final bool isOptimistic;
  final SyncStatus syncStatus;
  final List<String> replyIds; // For nested comments

  const CommentState({
    required this.comment,
    required this.parentPostId,
    required this.lastUpdated,
    this.isOptimistic = false,
    this.syncStatus = SyncStatus.synced,
    this.replyIds = const [],
  });

  CommentState copyWith({
    PostEntity? comment,
    String? parentPostId,
    DateTime? lastUpdated,
    bool? isOptimistic,
    SyncStatus? syncStatus,
    List<String>? replyIds,
  }) {
    return CommentState(
      comment: comment ?? this.comment,
      parentPostId: parentPostId ?? this.parentPostId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isOptimistic: isOptimistic ?? this.isOptimistic,
      syncStatus: syncStatus ?? this.syncStatus,
      replyIds: replyIds ?? this.replyIds,
    );
  }

  @override
  List<Object?> get props => [comment, parentPostId, lastUpdated, isOptimistic, syncStatus, replyIds];
}

/// Pagination metadata
class PaginationState extends Equatable {
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final bool hasMore;
  final DateTime lastFetch;
  final bool isLoading;

  const PaginationState({
    this.currentPage = 1,
    this.pageSize = 20,
    this.totalItems = 0,
    this.hasMore = true,
    required this.lastFetch,
    this.isLoading = false,
  });

  PaginationState copyWith({
    int? currentPage,
    int? pageSize,
    int? totalItems,
    bool? hasMore,
    DateTime? lastFetch,
    bool? isLoading,
  }) {
    return PaginationState(
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalItems: totalItems ?? this.totalItems,
      hasMore: hasMore ?? this.hasMore,
      lastFetch: lastFetch ?? this.lastFetch,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [currentPage, pageSize, totalItems, hasMore, lastFetch, isLoading];
}

/// Global community state container
class CommunityGlobalState extends Equatable {
  final Map<String, CommunityPostState> posts;
  final Map<String, CommunityProfileState> profiles;
  final Map<String, EngagementState> engagements;
  final Map<String, SocialRelationshipState> relationships;
  final Map<String, CommentState> comments;
  final Map<String, List<String>> postComments; // postId -> commentIds
  final Map<String, List<String>> userPosts; // userId -> postIds
  final List<String> feedPostIds; // Ordered list of post IDs for feed
  final PaginationState feedPagination;
  final DateTime lastGlobalSync;
  final List<CommunityAction> pendingActions;

  const CommunityGlobalState({
    this.posts = const {},
    this.profiles = const {},
    this.engagements = const {},
    this.relationships = const {},
    this.comments = const {},
    this.postComments = const {},
    this.userPosts = const {},
    this.feedPostIds = const [],
    required this.feedPagination,
    required this.lastGlobalSync,
    this.pendingActions = const [],
  });

  CommunityGlobalState copyWith({
    Map<String, CommunityPostState>? posts,
    Map<String, CommunityProfileState>? profiles,
    Map<String, EngagementState>? engagements,
    Map<String, SocialRelationshipState>? relationships,
    Map<String, CommentState>? comments,
    Map<String, List<String>>? postComments,
    Map<String, List<String>>? userPosts,
    List<String>? feedPostIds,
    PaginationState? feedPagination,
    DateTime? lastGlobalSync,
    List<CommunityAction>? pendingActions,
  }) {
    return CommunityGlobalState(
      posts: posts ?? this.posts,
      profiles: profiles ?? this.profiles,
      engagements: engagements ?? this.engagements,
      relationships: relationships ?? this.relationships,
      comments: comments ?? this.comments,
      postComments: postComments ?? this.postComments,
      userPosts: userPosts ?? this.userPosts,
      feedPostIds: feedPostIds ?? this.feedPostIds,
      feedPagination: feedPagination ?? this.feedPagination,
      lastGlobalSync: lastGlobalSync ?? this.lastGlobalSync,
      pendingActions: pendingActions ?? this.pendingActions,
    );
  }

  @override
  List<Object?> get props => [
    posts, profiles, engagements, relationships, comments,
    postComments, userPosts, feedPostIds, feedPagination,
    lastGlobalSync, pendingActions
  ];
}

/// Delta sync request model
class DeltaSyncRequest extends Equatable {
  final DateTime lastSyncTimestamp;
  final List<String> postIds;
  final List<String> userIds;
  final bool includeDeleted;

  const DeltaSyncRequest({
    required this.lastSyncTimestamp,
    this.postIds = const [],
    this.userIds = const [],
    this.includeDeleted = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'last_sync_timestamp': lastSyncTimestamp.toIso8601String(),
      'post_ids': postIds,
      'user_ids': userIds,
      'include_deleted': includeDeleted,
    };
  }

  @override
  List<Object?> get props => [lastSyncTimestamp, postIds, userIds, includeDeleted];
}

/// Delta sync response model
class DeltaSyncResponse extends Equatable {
  final List<PostEntity> updatedPosts;
  final List<String> deletedPostIds;
  final List<CommunityProfileEntity> updatedProfiles;
  final List<String> deletedUserIds;
  final Map<String, EngagementState> updatedEngagements;
  final Map<String, SocialRelationshipState> updatedRelationships;
  final DateTime serverTimestamp;
  final bool hasMoreChanges;

  const DeltaSyncResponse({
    this.updatedPosts = const [],
    this.deletedPostIds = const [],
    this.updatedProfiles = const [],
    this.deletedUserIds = const [],
    this.updatedEngagements = const {},
    this.updatedRelationships = const {},
    required this.serverTimestamp,
    this.hasMoreChanges = false,
  });

  factory DeltaSyncResponse.fromJson(Map<String, dynamic> json) {
    return DeltaSyncResponse(
      updatedPosts: (json['updated_posts'] as List<dynamic>?)
          ?.map((post) => PostEntity.fromJson(post as Map<String, dynamic>))
          .toList() ?? [],
      deletedPostIds: List<String>.from(json['deleted_post_ids'] ?? []),
      updatedProfiles: (json['updated_profiles'] as List<dynamic>?)
          ?.map((profile) => CommunityProfileEntity.fromJson(profile as Map<String, dynamic>))
          .toList() ?? [],
      deletedUserIds: List<String>.from(json['deleted_user_ids'] ?? []),
      serverTimestamp: DateTime.parse(json['server_timestamp']),
      hasMoreChanges: json['has_more_changes'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
    updatedPosts, deletedPostIds, updatedProfiles, deletedUserIds,
    updatedEngagements, updatedRelationships, serverTimestamp, hasMoreChanges
  ];
}

/// Real-time event model for WebSocket/SSE updates
class RealTimeEvent extends Equatable {
  final String eventType;
  final String? userId;
  final String? targetId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const RealTimeEvent({
    required this.eventType,
    this.userId,
    this.targetId,
    required this.data,
    required this.timestamp,
  });

  factory RealTimeEvent.fromJson(Map<String, dynamic> json) {
    return RealTimeEvent(
      eventType: json['event_type'],
      userId: json['user_id'],
      targetId: json['target_id'],
      data: json['data'] ?? {},
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  List<Object?> get props => [eventType, userId, targetId, data, timestamp];
}