import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/notifications/entities/notification_entities.dart';
import '../../../domain/notifications/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationService _notificationService;
  final NotificationRepository _notificationRepository;
  StreamSubscription? _notificationSubscription;
  late final StreamSubscription _deletedNotificationSubscription;
  late final StreamSubscription _unreadCountSubscription;
  late final StreamSubscription _connectionStatusSubscription;

  List<NotificationEntity> _notifications = [];
  int _unreadCount = 0;
  bool _isConnected = false;  
  NotificationFilter _currentFilter = NotificationFilter.all;
  bool _justMarkedAsSeen = false;  // Prevent fetch from overwriting 0 count

  NotificationBloc({
    NotificationService? notificationService,
    required NotificationRepository notificationRepository,
  }) : _notificationService = notificationService ?? NotificationService.instance,
       _notificationRepository = notificationRepository,
       super(const NotificationInitial()) {
    
    debugPrint('🔔 NotificationBloc: INITIALIZED - Ready to receive events');
    
    // Set up event handlers
    // Set up event handlers with concurrency to prevent queueing lag
    on<ConnectToNotificationStream>(_onConnectToNotificationStream);
    on<DisconnectFromNotificationStream>(_onDisconnectFromNotificationStream);
    on<NotificationReceived>(_onNotificationReceived);
    on<NotificationDeleted>(_onNotificationDeleted);
    on<ChangeNotificationFilter>(_onChangeNotificationFilter, transformer: concurrent());
    on<UnreadCountUpdated>(_onUnreadCountUpdated);
    on<FetchUnreadCount>(_onFetchUnreadCount);
    on<MarkAllNotificationsAsSeen>(_onMarkAllNotificationsAsSeen);
    on<ConnectionStatusChanged>(_onConnectionStatusChanged);
    on<ClearAllNotifications>(_onClearAllNotifications);
    
    // API fetch event handlers - also concurrent so they don't block filter changes
    on<FetchAllNotifications>(_onFetchAllNotifications, transformer: concurrent());
    on<FetchNotificationsByType>(_onFetchNotificationsByType, transformer: concurrent());
    on<RefreshNotifications>(_onRefreshNotifications, transformer: concurrent());

    // Set up stream subscriptions
    _setupStreamSubscriptions();

    // Initialize with current state from service
    _initializeFromService();
  }

  void _setupStreamSubscriptions() {
    // Listen for new notifications
    // _notificationSubscription = _notificationService.notificationStream.listen(
    //   (notification) => add(NotificationReceived(notification)),
    //   onError: (error) => debugPrint('❌ NotificationBloc: Notification stream error: $error'),
    // );

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
      debugPrint('🔔 NotificationBloc: ConnectToNotificationStream event received');
      emit(NotificationConnecting(
        notifications: _notifications,
        unreadCount: _unreadCount,
        currentFilter: _currentFilter,
      ));

      debugPrint('🔔 NotificationBloc: Calling _notificationService.connect()...');
      await _notificationService.connect();
      debugPrint('🔔 NotificationBloc: _notificationService.connect() completed');
      
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

    // Always emit loading state immediately to update the UI tab indicator
    emit(NotificationLoading(
      notifications: _notifications,
      unreadCount: _unreadCount,
      currentFilter: _currentFilter,
    ));

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
    debugPrint('🔔 NotificationBloc: UnreadCountUpdated event received with count: ${event.count}');
    _unreadCount = event.count;

    emit(NotificationLoaded(
      notifications: _notifications,
      filteredNotifications: _getFilteredNotifications(),
      unreadCount: _unreadCount,
      isConnected: _isConnected,
      currentFilter: _currentFilter,
    ));
    
    debugPrint('🔔 NotificationBloc: Emitted NotificationLoaded state with unreadCount: $_unreadCount');
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
      debugPrint('🔔 NotificationBloc: MarkAllNotificationsAsSeen event received');
      
      // Set flag to prevent filter change from triggering fetch
      _justMarkedAsSeen = true;
      
      final success = await _notificationRepository.markAllNotificationsAsSeen();
      
      if (!success) {
        debugPrint('❌ NotificationBloc: markAllNotificationsAsSeen returned false');
        _justMarkedAsSeen = false;  // Clear flag on failure
        emit(NotificationError(
          message: 'Failed to mark notifications as seen',
          notifications: _notifications,
          unreadCount: _unreadCount,
          isConnected: _isConnected,
          currentFilter: _currentFilter,
        ));
      } else {
        // Reset unread count to 0
        debugPrint('✅ NotificationBloc: Marked all notifications as seen successfully');
        _unreadCount = 0;
        // Sync to NotificationService so all Bloc instances get the update
        _notificationService.setUnreadCount(0);
        emit(NotificationLoaded(
          notifications: _notifications,
          filteredNotifications: _getFilteredNotifications(),
          unreadCount: _unreadCount,
          isConnected: _isConnected,
          currentFilter: _currentFilter,
        ));
        debugPrint('✅ NotificationBloc: Emitted NotificationLoaded with unreadCount=0');
        
        // Clear the flag after 3 seconds to allow normal filter changes
        Future.delayed(const Duration(seconds: 3), () {
          _justMarkedAsSeen = false;
          debugPrint('🔔 NotificationBloc: Cleared _justMarkedAsSeen flag');
        });
      }
    } catch (e) {
      debugPrint('❌ NotificationBloc: Failed to mark as seen: $e');
      _justMarkedAsSeen = false;  // Clear flag on error
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
      emit(NotificationLoading(
        notifications: _notifications,
        unreadCount: _unreadCount,
        currentFilter: _currentFilter,
      ));
      
      final response = await _notificationRepository.getAllNotifications(
        limit: event.limit,
        offset: event.offset,
      );
      
      // Safety check: only update if this is still the filter we want
      if (_currentFilter != NotificationFilter.all) {
        debugPrint('🔔 NotificationBloc: FetchAll completed but current filter is $_currentFilter. Ignoring output.');
        return;
      }

      _notifications = response.notifications;
      // If we just marked as seen, keep unread count at 0 to avoid race condition fakers
      _unreadCount = _justMarkedAsSeen ? 0 : response.unreadCount;
      
      emit(NotificationLoaded(
        notifications: _notifications,
        filteredNotifications: _getFilteredNotifications(),
        unreadCount: _unreadCount,
        isConnected: _isConnected,
        currentFilter: _currentFilter,
      ));
      
      // Automatically connect to SSE after first fetch
      debugPrint('🔔 NotificationBloc: Fetched notifications, now connecting to SSE stream...');
      if (!_isConnected && _notificationService.isConnected == false) {
        add(const ConnectToNotificationStream());
      }
      
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
      emit(NotificationLoading(
        notifications: _notifications,
        unreadCount: _unreadCount,
        currentFilter: _currentFilter,
      ));
      
      final response = await _notificationRepository.getNotificationsByType(
        type: event.type,
        limit: event.limit,
        offset: event.offset,
      );
      
      // Safety check: only update if this is still the filter we want
      if (_currentFilter.apiType != event.type) {
        debugPrint('🔔 NotificationBloc: FetchByType(${event.type}) completed but current filter is $_currentFilter. Ignoring output.');
        return;
      }

      _notifications = response.notifications;
      // If we just marked as seen, keep unread count at 0 to avoid race condition fakers
      _unreadCount = _justMarkedAsSeen ? 0 : response.unreadCount;
      
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
    _notificationSubscription?.cancel();
    _deletedNotificationSubscription.cancel();
    _unreadCountSubscription.cancel();
    _connectionStatusSubscription.cancel();
    return super.close();
  }
}