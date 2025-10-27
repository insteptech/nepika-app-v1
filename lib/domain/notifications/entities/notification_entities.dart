import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

// Notification Types
enum NotificationType {
  like,
  reply,
  follow,
  mention,
  followRequest,
  followRequestAccepted,
  notificationDeleted;

  static NotificationType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'like':
        return NotificationType.like;
      case 'reply':
        return NotificationType.reply;
      case 'follow':
        return NotificationType.follow;
      case 'mention':
        return NotificationType.mention;
      case 'follow_request':
        return NotificationType.followRequest;
      case 'follow_request_accepted':
        return NotificationType.followRequestAccepted;
      case 'notification_deleted':
        return NotificationType.notificationDeleted;
      default:
        throw ArgumentError('Unknown notification type: $type');
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.like:
        return 'Liked';
      case NotificationType.reply:
        return 'Replied';
      case NotificationType.follow:
        return 'Followed you';
      case NotificationType.mention:
        return 'Mentioned you';
      case NotificationType.followRequest:
        return 'Requested to follow you';
      case NotificationType.followRequestAccepted:
        return 'Accepted your follow request';
      case NotificationType.notificationDeleted:
        return 'Deleted';
    }
  }

  String get iconPath {
    switch (this) {
      case NotificationType.like:
        return 'assets/icons/heart_filled.svg';
      case NotificationType.reply:
        return 'assets/icons/message.svg';
      case NotificationType.follow:
        return 'assets/icons/user_plus.svg';
      case NotificationType.mention:
        return 'assets/icons/at_symbol.svg';
      case NotificationType.followRequest:
        return 'assets/icons/user_plus.svg';
      case NotificationType.followRequestAccepted:
        return 'assets/icons/user_check.svg';
      case NotificationType.notificationDeleted:
        return '';
    }
  }
}

// Post Entity (simplified for notifications)
class NotificationPostEntity extends Equatable {
  final String id;
  final String content;

  const NotificationPostEntity({
    required this.id,
    required this.content,
  });

  factory NotificationPostEntity.fromApiJson(Map<String, dynamic> json) {
    return NotificationPostEntity(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
    };
  }

  @override
  List<Object?> get props => [id, content];
}

// Actor Entity (User who triggered the notification)
class NotificationActorEntity extends Equatable {
  final String id;
  final String username;
  final String fullName;
  final String? profileImageUrl;

  const NotificationActorEntity({
    required this.id,
    required this.username,
    required this.fullName,
    this.profileImageUrl,
  });

  factory NotificationActorEntity.fromJson(Map<String, dynamic> json) {
    return NotificationActorEntity(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      profileImageUrl: json['profile_image_url']?.toString(),
    );
  }

  factory NotificationActorEntity.fromApiJson(Map<String, dynamic> json) {
    return NotificationActorEntity(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      profileImageUrl: json['profile_picture_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'profile_image_url': profileImageUrl,
    };
  }

  @override
  List<Object?> get props => [id, username, fullName, profileImageUrl];
}

// Main Notification Entity
class NotificationEntity extends Equatable {
  final String id;
  final NotificationType type;
  final String message;
  final NotificationActorEntity actor;
  final String? postId;
  final NotificationPostEntity? post;
  final DateTime createdAt;
  final int unreadCount;
  final bool isRead;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.message,
    required this.actor,
    this.postId,
    this.post,
    required this.createdAt,
    required this.unreadCount,
    this.isRead = false,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json['notification_id']?.toString() ?? '',
      type: NotificationType.fromString(json['type']?.toString() ?? ''),
      message: json['message']?.toString() ?? '',
      actor: NotificationActorEntity.fromJson(json['actor'] ?? {}),
      postId: json['post_id']?.toString(),
      post: json['post'] != null ? NotificationPostEntity.fromApiJson(json['post']) : null,
      createdAt: _parseDateTime(json['created_at']?.toString()),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      isRead: json['is_read'] == true,
    );
  }

  factory NotificationEntity.fromApiJson(Map<String, dynamic> json) {
    final postData = json['post'];
    return NotificationEntity(
      id: json['id']?.toString() ?? '',
      type: NotificationType.fromString(json['type']?.toString() ?? ''),
      message: _generateMessage(json),
      actor: NotificationActorEntity.fromApiJson(json['actor'] ?? {}),
      postId: postData?['id']?.toString(),
      post: postData != null ? NotificationPostEntity.fromApiJson(postData) : null,
      createdAt: _parseDateTime(json['created_at']?.toString()),
      unreadCount: 0, // API doesn't include individual notification unread count
      isRead: json['is_read'] == true,
    );
  }

  static DateTime _parseDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return DateTime.now();
    }
    
    try {
      // Try parsing the string as is
      final parsed = DateTime.tryParse(dateTimeString);
      if (parsed != null) {
        // If the parsed datetime doesn't have timezone info, treat it as UTC
        // then convert to local time
        if (!dateTimeString.contains('Z') && !dateTimeString.contains('+') && !dateTimeString.contains('-', 19)) {
          return DateTime.parse('${dateTimeString}Z').toLocal();
        }
        return parsed.toLocal();
      }
      
      // If parsing failed, log and return current time
      debugPrint('Failed to parse notification datetime: $dateTimeString');
      return DateTime.now();
    } catch (e) {
      debugPrint('Error parsing notification datetime: $dateTimeString, error: $e');
      return DateTime.now();
    }
  }

  static String _generateMessage(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? '';
    final actorName = json['actor']?['full_name']?.toString() ?? 'Someone';
    
    switch (type.toLowerCase()) {
      case 'like':
        return '$actorName liked your post';
      case 'reply':
        return '$actorName replied to your post';
      case 'follow':
        return '$actorName started following you';
      case 'mention':
        return '$actorName mentioned you in a post';
      case 'follow_request':
        return '$actorName requested to follow you';
      case 'follow_request_accepted':
        return '$actorName accepted your follow request';
      default:
        return '$actorName sent you a notification';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': id,
      'type': type.name,
      'message': message,
      'actor': actor.toJson(),
      'post_id': postId,
      'post': post?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'unread_count': unreadCount,
      'is_read': isRead,
    };
  }

  @override
  List<Object?> get props => [id, type, message, actor, postId, post, createdAt, unreadCount, isRead];
}

// Deleted Notification Entity
class DeletedNotificationEntity extends Equatable {
  final NotificationType type;
  final String actorId;
  final String? postId;
  final int unreadCount;

  const DeletedNotificationEntity({
    required this.type,
    required this.actorId,
    this.postId,
    required this.unreadCount,
  });

  factory DeletedNotificationEntity.fromJson(Map<String, dynamic> json) {
    final deletedData = json['deleted_notification'] ?? json;
    return DeletedNotificationEntity(
      type: NotificationType.fromString(deletedData['type']?.toString() ?? ''),
      actorId: deletedData['actor_id']?.toString() ?? '',
      postId: deletedData['post_id']?.toString(),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'actor_id': actorId,
      'post_id': postId,
      'unread_count': unreadCount,
    };
  }

  @override
  List<Object?> get props => [type, actorId, postId, unreadCount];
}

// SSE Event Entity (Wrapper for all SSE events)
class SSEEventEntity extends Equatable {
  final String type;
  final Map<String, dynamic> data;

  const SSEEventEntity({
    required this.type,
    required this.data,
  });

  factory SSEEventEntity.fromJson(Map<String, dynamic> json) {
    return SSEEventEntity(
      type: json['type']?.toString() ?? '',
      data: json,
    );
  }

  bool get isNotification => [
    'like',
    'reply', 
    'follow',
    'mention'
  ].contains(type);

  bool get isNotificationDeleted => type == 'notification_deleted';
  bool get isConnected => type == 'connected';
  bool get isHeartbeat => type == 'heartbeat';

  NotificationEntity? toNotification() {
    if (!isNotification) return null;
    try {
      return NotificationEntity.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  DeletedNotificationEntity? toDeletedNotification() {
    if (!isNotificationDeleted) return null;
    try {
      return DeletedNotificationEntity.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => [type, data];
}

// Unread Count Entity
class UnreadCountEntity extends Equatable {
  final int count;

  const UnreadCountEntity({required this.count});

  factory UnreadCountEntity.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return UnreadCountEntity(
      count: (data['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'unread_count': count,
      }
    };
  }

  @override
  List<Object?> get props => [count];
}

// Mark as Seen Response Entity
class MarkAsSeenResponseEntity extends Equatable {
  final bool success;
  final String message;

  const MarkAsSeenResponseEntity({
    required this.success,
    required this.message,
  });

  factory MarkAsSeenResponseEntity.fromJson(Map<String, dynamic> json) {
    return MarkAsSeenResponseEntity(
      success: json['status'] == 'success' || json['success'] == true,
      message: json['message']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }

  @override
  List<Object?> get props => [success, message];
}

// Notification Filter Types
enum NotificationFilter {
  all,
  likes,
  replies,
  mentions,
  follows;

  String get displayName {
    switch (this) {
      case NotificationFilter.all:
        return 'All';
      case NotificationFilter.likes:
        return 'Likes';
      case NotificationFilter.replies:
        return 'Replies';
      case NotificationFilter.mentions:
        return 'Mentions';
      case NotificationFilter.follows:
        return 'Follows';
    }
  }

  String get apiType {
    switch (this) {
      case NotificationFilter.all:
        return '';
      case NotificationFilter.likes:
        return 'like';
      case NotificationFilter.replies:
        return 'reply';
      case NotificationFilter.mentions:
        return 'mention';
      case NotificationFilter.follows:
        return 'follow';
    }
  }

  bool shouldShowNotification(NotificationType type) {
    switch (this) {
      case NotificationFilter.all:
        return true;
      case NotificationFilter.likes:
        return type == NotificationType.like;
      case NotificationFilter.replies:
        return type == NotificationType.reply;
      case NotificationFilter.mentions:
        return type == NotificationType.mention;
      case NotificationFilter.follows:
        return type == NotificationType.follow || 
               type == NotificationType.followRequest ||
               type == NotificationType.followRequestAccepted;
    }
  }
}