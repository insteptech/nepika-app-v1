import 'package:equatable/equatable.dart';
import '../../../domain/notifications/entities/notification_entities.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

// Connection Events
class ConnectToNotificationStream extends NotificationEvent {
  const ConnectToNotificationStream();
}

class DisconnectFromNotificationStream extends NotificationEvent {
  const DisconnectFromNotificationStream();
}

// Notification Events
class NotificationReceived extends NotificationEvent {
  final NotificationEntity notification;

  const NotificationReceived(this.notification);

  @override
  List<Object> get props => [notification];
}

class NotificationDeleted extends NotificationEvent {
  final DeletedNotificationEntity deletedNotification;

  const NotificationDeleted(this.deletedNotification);

  @override
  List<Object> get props => [deletedNotification];
}

// Filter Events
class ChangeNotificationFilter extends NotificationEvent {
  final NotificationFilter filter;

  const ChangeNotificationFilter(this.filter);

  @override
  List<Object> get props => [filter];
}

// Unread Count Events
class UnreadCountUpdated extends NotificationEvent {
  final int count;

  const UnreadCountUpdated(this.count);

  @override
  List<Object> get props => [count];
}

class FetchUnreadCount extends NotificationEvent {
  const FetchUnreadCount();
}

class MarkAllNotificationsAsSeen extends NotificationEvent {
  const MarkAllNotificationsAsSeen();
}

// Connection Status Events
class ConnectionStatusChanged extends NotificationEvent {
  final bool isConnected;

  const ConnectionStatusChanged(this.isConnected);

  @override
  List<Object> get props => [isConnected];
}

// Clear Events
class ClearAllNotifications extends NotificationEvent {
  const ClearAllNotifications();
}

// API Fetch Events
class FetchAllNotifications extends NotificationEvent {
  final int limit;
  final int offset;

  const FetchAllNotifications({
    this.limit = 20,
    this.offset = 0,
  });

  @override
  List<Object> get props => [limit, offset];
}

class FetchNotificationsByType extends NotificationEvent {
  final String type;
  final int limit;
  final int offset;

  const FetchNotificationsByType({
    required this.type,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  List<Object> get props => [type, limit, offset];
}

class RefreshNotifications extends NotificationEvent {
  const RefreshNotifications();
}

class LoadMoreNotifications extends NotificationEvent {
  const LoadMoreNotifications();
}