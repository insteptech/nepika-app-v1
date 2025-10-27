import 'package:equatable/equatable.dart';
import '../../../core/utils/app_logger.dart';

/// Entity representing a blocked user
class BlockedUserEntity extends Equatable {
  final String id;
  final String userId;
  final String? username;
  final String? profileImageUrl;
  final DateTime createdAt;

  const BlockedUserEntity({
    required this.id,
    required this.userId,
    this.username,
    this.profileImageUrl,
    required this.createdAt,
  });

  factory BlockedUserEntity.fromJson(Map<String, dynamic> json) {
    return BlockedUserEntity(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      username: json['username']?.toString(),
      profileImageUrl: json['profile_image_url']?.toString(),
      createdAt: _parseDateTime(json['created_at']?.toString()),
    );
  }

  /// Enhanced datetime parsing with timezone handling and debug logging
  static DateTime _parseDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      AppLogger.debug('Empty or null date string, using current time', tag: 'BlockedUserEntity');
      return DateTime.now();
    }

    try {
      // First try standard parsing
      var parsed = DateTime.tryParse(dateString);
      if (parsed != null) {
        // If parsed successfully but doesn't include timezone info,
        // assume it's UTC and convert to local time
        if (!dateString.contains('Z') && !dateString.contains('+') && !dateString.contains('-', 10)) {
          AppLogger.debug('Parsed as timezone-less, treating as UTC: $dateString -> ${parsed.toUtc().toLocal()}', tag: 'BlockedUserEntity');
          return parsed.toUtc().toLocal();
        }
        AppLogger.debug('Successfully parsed with timezone: $dateString -> $parsed', tag: 'BlockedUserEntity');
        return parsed;
      }

      AppLogger.debug('Failed to parse date string: $dateString, using current time', tag: 'BlockedUserEntity');
      return DateTime.now();
    } catch (e) {
      AppLogger.error('Exception parsing date string "$dateString", using current time', tag: 'BlockedUserEntity', error: e);
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, username, profileImageUrl, createdAt];
}

/// Response entity for blocked users list API
class BlockedUsersResponseEntity extends Equatable {
  final List<BlockedUserEntity> users;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  const BlockedUsersResponseEntity({
    required this.users,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory BlockedUsersResponseEntity.fromJson(Map<String, dynamic> json) {
    final usersData = json['users'] as List<dynamic>? ?? [];
    return BlockedUsersResponseEntity(
      users: usersData
          .map((user) => BlockedUserEntity.fromJson(user as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
      hasMore: json['has_more'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'users': users.map((user) => user.toJson()).toList(),
      'total': total,
      'page': page,
      'page_size': pageSize,
      'has_more': hasMore,
    };
  }

  @override
  List<Object?> get props => [users, total, page, pageSize, hasMore];
}

/// Entity for unblock user request
class UnblockUserEntity extends Equatable {
  final String userId;

  const UnblockUserEntity({required this.userId});

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
    };
  }

  @override
  List<Object?> get props => [userId];
}