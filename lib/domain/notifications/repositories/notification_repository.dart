import '../entities/notification_entities.dart';

abstract class NotificationRepository {
  /// Fetch all notifications without filter
  Future<NotificationResponse> getAllNotifications({
    int limit = 20,
    int offset = 0,
  });

  /// Fetch notifications filtered by type
  Future<NotificationResponse> getNotificationsByType({
    required String type,
    int limit = 20,
    int offset = 0,
  });

  /// Mark all notifications as seen
  Future<bool> markAllNotificationsAsSeen();
}

/// Response wrapper for API notifications
class NotificationResponse {
  final List<NotificationEntity> notifications;
  final int totalCount;
  final int unreadCount;
  final int limit;
  final int offset;
  final String? filterType;

  const NotificationResponse({
    required this.notifications,
    required this.totalCount,
    required this.unreadCount,
    required this.limit,
    required this.offset,
    this.filterType,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final notificationsList = (data['notifications'] as List?) ?? [];
    
    return NotificationResponse(
      notifications: notificationsList
          .map((item) => NotificationEntity.fromApiJson(item))
          .toList(),
      totalCount: (data['total_count'] as num?)?.toInt() ?? 0,
      unreadCount: (data['unread_count'] as num?)?.toInt() ?? 0,
      limit: (data['limit'] as num?)?.toInt() ?? 20,
      offset: (data['offset'] as num?)?.toInt() ?? 0,
      filterType: data['filter_type']?.toString(),
    );
  }
}