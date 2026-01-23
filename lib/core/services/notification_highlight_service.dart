import 'dart:async';

/// Service to manage notification highlighting when navigating from push notifications
class NotificationHighlightService {
  static final NotificationHighlightService _instance = NotificationHighlightService._internal();
  static NotificationHighlightService get instance => _instance;

  NotificationHighlightService._internal();

  // Stream controller for notification highlight events
  final _highlightController = StreamController<NotificationHighlightEvent>.broadcast();
  
  Stream<NotificationHighlightEvent> get highlightStream => _highlightController.stream;

  /// Trigger a highlight animation for a specific notification
  void highlightNotification({
    required String notificationId,
    required String notificationType,
    Duration duration = const Duration(seconds: 2),
  }) {
    _highlightController.add(
      NotificationHighlightEvent(
        notificationId: notificationId,
        notificationType: notificationType,
        duration: duration,
      ),
    );
  }

  /// Dispose the service
  void dispose() {
    _highlightController.close();
  }
}

/// Event class for notification highlighting
class NotificationHighlightEvent {
  final String notificationId;
  final String notificationType;
  final Duration duration;

  NotificationHighlightEvent({
    required this.notificationId,
    required this.notificationType,
    required this.duration,
  });
}
