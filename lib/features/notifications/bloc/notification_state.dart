import 'package:equatable/equatable.dart';
import '../../../domain/notifications/entities/notification_entities.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  final List<NotificationEntity> notifications;
  final List<NotificationEntity> filteredNotifications;
  final int unreadCount;
  final bool isConnected;
  final NotificationFilter currentFilter;

  const NotificationLoaded({
    required this.notifications,
    required this.filteredNotifications,
    required this.unreadCount,
    required this.isConnected,
    required this.currentFilter,
  });

  @override
  List<Object> get props => [
    notifications,
    filteredNotifications,
    unreadCount,
    isConnected,
    currentFilter,
  ];

  NotificationLoaded copyWith({
    List<NotificationEntity>? notifications,
    List<NotificationEntity>? filteredNotifications,
    int? unreadCount,
    bool? isConnected,
    NotificationFilter? currentFilter,
    bool? isLoadingMore,
    bool? hasReachedMax,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      filteredNotifications: filteredNotifications ?? this.filteredNotifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isConnected: isConnected ?? this.isConnected,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}

class NotificationError extends NotificationState {
  final String message;
  final List<NotificationEntity> notifications;
  final int unreadCount;
  final bool isConnected;
  final NotificationFilter currentFilter;

  const NotificationError({
    required this.message,
    this.notifications = const [],
    this.unreadCount = 0,
    this.isConnected = false,
    this.currentFilter = NotificationFilter.all,
  });

  @override
  List<Object> get props => [
    message,
    notifications,
    unreadCount,
    isConnected,
    currentFilter,
  ];
}

class NotificationConnecting extends NotificationState {
  final List<NotificationEntity> notifications;
  final int unreadCount;
  final NotificationFilter currentFilter;

  const NotificationConnecting({
    this.notifications = const [],
    this.unreadCount = 0,
    this.currentFilter = NotificationFilter.all,
  });

  @override
  List<Object> get props => [
    notifications,
    unreadCount,
    currentFilter,
  ];
}

class NotificationDisconnected extends NotificationState {
  final List<NotificationEntity> notifications;
  final int unreadCount;
  final NotificationFilter currentFilter;

  const NotificationDisconnected({
    this.notifications = const [],
    this.unreadCount = 0,
    this.currentFilter = NotificationFilter.all,
  });

  @override
  List<Object> get props => [
    notifications,
    unreadCount,
    currentFilter,
  ];
}