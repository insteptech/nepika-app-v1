import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/notifications/entities/notification_entities.dart';
import '../../../domain/notifications/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationService _notificationService;
  final NotificationRepository _notificationRepository;
  late final StreamSubscription _notificationSubscription;
  late final StreamSubscription _deletedNotificationSubscription;
  late final StreamSubscription _unreadCountSubscription;
  late final StreamSubscription _connectionStatusSubscription;

  List<NotificationEntity> _notifications = [];
  int _unreadCount = 0;
  bool _isConnected = false;
  NotificationFilter _currentFilter = NotificationFilter.all;

  NotificationBloc({
    NotificationService? notificationService,
    required NotificationRepository notificationRepository,
  }) : _notificationService = notificationService ?? NotificationService.instance,
       _notificationRepository = notificationRepository,
       super(const NotificationInitial()) {
    
    // Set up event handlers
    on<ConnectToNotificationStream>(_onConnectToNotificationStream);
    on<DisconnectFromNotificationStream>(_onDisconnectFromNotificationStream);
    on<NotificationReceived>(_onNotificationReceived);
    on<NotificationDeleted>(_onNotificationDeleted);
    on<ChangeNotificationFilter>(_onChangeNotificationFilter);
    on<UnreadCountUpdated>(_onUnreadCountUpdated);
    on<FetchUnreadCount>(_onFetchUnreadCount);
    on<MarkAllNotificationsAsSeen>(_onMarkAllNotificationsAsSeen);
    on<ConnectionStatusChanged>(_onConnectionStatusChanged);
    on<ClearAllNotifications>(_onClearAllNotifications);
    
    // API fetch event handlers
    on<FetchAllNotifications>(_onFetchAllNotifications);
    on<FetchNotificationsByType>(_onFetchNotificationsByType);
    on<RefreshNotifications>(_onRefreshNotifications);

    // Set up stream subscriptions
    _setupStreamSubscriptions();

    // Initialize with current state from service
    _initializeFromService();
  }

  void _setupStreamSubscriptions() {
    // Listen for new notifications
    _notificationSubscription = _notificationService.notificationStream.listen(
      (notification) => add(NotificationReceived(notification)),
      onError: (error) => debugPrint('❌ NotificationBloc: Notification stream error: $error'),
    );

    // Listen for deleted notifications
    _deletedNotificationSubscription = _notificationService.deletedNotificationStream.listen(
      (deletedNotification) => add(NotificationDeleted(deletedNotification)),
      onError: (error) => debugPrint('❌ NotificationBloc: Deleted notification stream error: $error'),
    );

    // Listen for unread count updates
    _unreadCountSubscription = _notificationService.unreadCountStream.listen(
      (count) => add(UnreadCountUpdated(count)),
      onError: (error) => debugPrint('❌ NotificationBloc: Unread count stream error: $error'),
    );

    // Listen for connection status changes
    _connectionStatusSubscription = _notificationService.connectionStatusStream.listen(
      (isConnected) => add(ConnectionStatusChanged(isConnected)),
      onError: (error) => debugPrint('❌ NotificationBloc: Connection status stream error: $error'),
    );
  }

  void _initializeFromService() {
    _notifications = _notificationService.notifications;
    _unreadCount = _notificationService.unreadCount;
    _isConnected = _notificationService.isConnected;
    
    // Emit initial state with current data
    if (_notifications.isNotEmpty || _unreadCount > 0) {
      emit(NotificationLoaded(
        notifications: _notifications,
        filteredNotifications: _getFilteredNotifications(),
        unreadCount: _unreadCount,
        isConnected: _isConnected,
        currentFilter: _currentFilter,
      ));
    }
  }

  Future<void> _onConnectToNotificationStream(
    ConnectToNotificationStream event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(NotificationConnecting(
        notifications: _notifications,
        unreadCount: _unreadCount,
        currentFilter: _currentFilter,
      ));

      await _notificationService.connect();
      
      // The connection status will be updated via the stream listener
    } catch (e) {
      debugPrint('❌ NotificationBloc: Failed to connect: $e');
      emit(NotificationError(
        message: 'Failed to connect to notifications: $e',
        notifications: _notifications,
        unreadCount: _unreadCount,
        isConnected: false,
        currentFilter: _currentFilter,
      ));
    }
  }

  Future<void> _onDisconnectFromNotificationStream(
    DisconnectFromNotificationStream event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationService.disconnect();
      
      emit(NotificationDisconnected(
        notifications: _notifications,
        unreadCount: _unreadCount,
        currentFilter: _currentFilter,
      ));
    } catch (e) {
      debugPrint('❌ NotificationBloc: Failed to disconnect: $e');
    }
  }

  void _onNotificationReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) {
    _notifications = [event.notification, ..._notifications];
    
    emit(NotificationLoaded(
      notifications: _notifications,
      filteredNotifications: _getFilteredNotifications(),
      unreadCount: _unreadCount,
      isConnected: _isConnected,
      currentFilter: _currentFilter,
    ));
  }

  void _onNotificationDeleted(
    NotificationDeleted event,
    Emitter<NotificationState> emit,
  ) {
    _notifications = _notifications.where((notification) =>
      !(notification.type == event.deletedNotification.type &&
        notification.actor.id == event.deletedNotification.actorId &&
        notification.postId == event.deletedNotification.postId)
    ).toList();

    emit(NotificationLoaded(
      notifications: _notifications,
      filteredNotifications: _getFilteredNotifications(),
      unreadCount: _unreadCount,
      isConnected: _isConnected,
      currentFilter: _currentFilter,
    ));
  }

  void _onChangeNotificationFilter(
    ChangeNotificationFilter event,
    Emitter<NotificationState> emit,
  ) {
    _currentFilter = event.filter;

    // Fetch notifications based on new filter
    if (_currentFilter == NotificationFilter.all) {
      add(const FetchAllNotifications(limit: 20, offset: 0));
    } else {
      add(FetchNotificationsByType(
        type: _currentFilter.apiType,
        limit: 20,
        offset: 0,
      ));
    }
  }

  void _onUnreadCountUpdated(
    UnreadCountUpdated event,
    Emitter<NotificationState> emit,
  ) {
    _unreadCount = event.count;

    emit(NotificationLoaded(
      notifications: _notifications,
      filteredNotifications: _getFilteredNotifications(),
      unreadCount: _unreadCount,
      isConnected: _isConnected,
      currentFilter: _currentFilter,
    ));
  }

  Future<void> _onFetchUnreadCount(
    FetchUnreadCount event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationService.fetchUnreadCount();
    } catch (e) {
      debugPrint('❌ NotificationBloc: Failed to fetch unread count: $e');
    }
  }

  Future<void> _onMarkAllNotificationsAsSeen(
    MarkAllNotificationsAsSeen event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final success = await _notificationRepository.markAllNotificationsAsSeen();
      if (!success) {
        emit(NotificationError(
          message: 'Failed to mark notifications as seen',
          notifications: _notifications,
          unreadCount: _unreadCount,
          isConnected: _isConnected,
          currentFilter: _currentFilter,
        ));
      } else {
        // Reset unread count to 0
        _unreadCount = 0;
        emit(NotificationLoaded(
          notifications: _notifications,
          filteredNotifications: _getFilteredNotifications(),
          unreadCount: _unreadCount,
          isConnected: _isConnected,
          currentFilter: _currentFilter,
        ));
      }
    } catch (e) {
      debugPrint('❌ NotificationBloc: Failed to mark as seen: $e');
      emit(NotificationError(
        message: 'Failed to mark notifications as seen: $e',
        notifications: _notifications,
        unreadCount: _unreadCount,
        isConnected: _isConnected,
        currentFilter: _currentFilter,
      ));
    }
  }

  void _onConnectionStatusChanged(
    ConnectionStatusChanged event,
    Emitter<NotificationState> emit,
  ) {
    _isConnected = event.isConnected;

    if (_isConnected) {
      emit(NotificationLoaded(
        notifications: _notifications,
        filteredNotifications: _getFilteredNotifications(),
        unreadCount: _unreadCount,
        isConnected: _isConnected,
        currentFilter: _currentFilter,
      ));
    } else {
      emit(NotificationDisconnected(
        notifications: _notifications,
        unreadCount: _unreadCount,
        currentFilter: _currentFilter,
      ));
    }
  }

  void _onClearAllNotifications(
    ClearAllNotifications event,
    Emitter<NotificationState> emit,
  ) {
    _notificationService.clearNotifications();
    _notifications = [];
    _unreadCount = 0;

    emit(NotificationLoaded(
      notifications: _notifications,
      filteredNotifications: [],
      unreadCount: _unreadCount,
      isConnected: _isConnected,
      currentFilter: _currentFilter,
    ));
  }

  List<NotificationEntity> _getFilteredNotifications() {
    return _notifications.where((notification) =>
      _currentFilter.shouldShowNotification(notification.type)
    ).toList();
  }

  // API fetch event handlers
  Future<void> _onFetchAllNotifications(
    FetchAllNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(NotificationLoading());
      
      final response = await _notificationRepository.getAllNotifications(
        limit: event.limit,
        offset: event.offset,
      );
      
      _notifications = response.notifications;
      _unreadCount = response.unreadCount;
      
      emit(NotificationLoaded(
        notifications: _notifications,
        filteredNotifications: _getFilteredNotifications(),
        unreadCount: _unreadCount,
        isConnected: _isConnected,
        currentFilter: _currentFilter,
      ));
    } catch (e) {
      debugPrint('❌ NotificationBloc: Failed to fetch notifications: $e');
      emit(NotificationError(
        message: 'Failed to load notifications: $e',
        notifications: _notifications,
        unreadCount: _unreadCount,
        isConnected: _isConnected,
        currentFilter: _currentFilter,
      ));
    }
  }

  Future<void> _onFetchNotificationsByType(
    FetchNotificationsByType event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(NotificationLoading());
      
      final response = await _notificationRepository.getNotificationsByType(
        type: event.type,
        limit: event.limit,
        offset: event.offset,
      );
      
      _notifications = response.notifications;
      _unreadCount = response.unreadCount;
      
      emit(NotificationLoaded(
        notifications: _notifications,
        filteredNotifications: _notifications, // Already filtered by API
        unreadCount: _unreadCount,
        isConnected: _isConnected,
        currentFilter: _currentFilter,
      ));
    } catch (e) {
      debugPrint('❌ NotificationBloc: Failed to fetch notifications by type: $e');
      emit(NotificationError(
        message: 'Failed to load notifications: $e',
        notifications: _notifications,
        unreadCount: _unreadCount,
        isConnected: _isConnected,
        currentFilter: _currentFilter,
      ));
    }
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      // Use current filter to determine which API to call
      if (_currentFilter == NotificationFilter.all) {
        add(const FetchAllNotifications(limit: 20, offset: 0));
      } else {
        add(FetchNotificationsByType(
          type: _currentFilter.apiType,
          limit: 20,
          offset: 0,
        ));
      }
    } catch (e) {
      debugPrint('❌ NotificationBloc: Failed to refresh notifications: $e');
    }
  }

  @override
  Future<void> close() {
    _notificationSubscription.cancel();
    _deletedNotificationSubscription.cancel();
    _unreadCountSubscription.cancel();
    _connectionStatusSubscription.cancel();
    return super.close();
  }
}