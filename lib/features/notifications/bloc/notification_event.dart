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