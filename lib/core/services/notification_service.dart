import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants/api_endpoints.dart';
import '../config/constants/app_constants.dart';
import '../config/env.dart';
import '../network/secure_api_client.dart';
import '../../domain/notifications/entities/notification_entities.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  
  NotificationService._internal();

  // SSE connection
  http.Client? _httpClient;
  Stream<String>? _sseStream;
  
  // Streams for real-time updates
  final _notificationController = StreamController<NotificationEntity>.broadcast();
  final _deletedNotificationController = StreamController<DeletedNotificationEntity>.broadcast();
  final _unreadCountController = StreamController<int>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();
  
  // Notification list and unread count
  final List<NotificationEntity> _notifications = [];
  int _unreadCount = 0;
  bool _isConnected = false;
  
  // Getters for streams
  // Stream<NotificationEntity> get notificationStream => _notificationController.stream;
  Stream<DeletedNotificationEntity> get deletedNotificationStream => _deletedNotificationController.stream;
  Stream<int> get unreadCountStream => _unreadCountController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  
  // Getters for current state
  List<NotificationEntity> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isConnected => _isConnected;

  /// Connect to SSE stream
  Future<void> connect() async {
    debugPrint('🔔 NotificationService: Connect method called');
    debugPrint('🔔 NotificationService: _isConnected = $_isConnected, _httpClient != null = ${_httpClient != null}');
    
    if (_isConnected || _httpClient != null) {
      debugPrint('🔔 NotificationService: Already connected or connecting');
      return;
    }

    try {
      debugPrint('🔔 NotificationService: Retrieving access token...');
      final accessToken = await _getAccessToken();
      
      if (accessToken == null) {
        debugPrint('❌ NotificationService: No access token available');
        return;
      }
      
      debugPrint('🔔 NotificationService: ✅ Access token retrieved: ${accessToken.substring(0, 20)}...');

      final url = '${Env.baseUrl}${ApiEndpoints.notificationStream}';
      debugPrint('🔔 NotificationService: SSE URL: $url');
      debugPrint('🔔 NotificationService: Env.baseUrl: ${Env.baseUrl}');
      debugPrint('🔔 NotificationService: ApiEndpoints.notificationStream: ${ApiEndpoints.notificationStream}');

      debugPrint('🔔 NotificationService: Creating HTTP client and request...');
      _httpClient = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll({
        'Authorization': 'Bearer $accessToken',
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      });
      
      debugPrint('🔔 NotificationService: Request headers: ${request.headers}');
      debugPrint('🔔 NotificationService: Sending SSE request...');

      final response = await _httpClient!.send(request);
      debugPrint('🔔 NotificationService: Response status code: ${response.statusCode}');
      debugPrint('🔔 NotificationService: Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        debugPrint('✅ NotificationService: SSE connection successful, status: ${response.statusCode}');
        _sseStream = response.stream
            .transform(const Utf8Decoder())
            .transform(const LineSplitter())
            .where((line) => line.isNotEmpty);

        debugPrint('🔔 NotificationService: SSE stream transformed, attaching listener...');
        _sseStream!.listen(
          _handleSSELine,
          onError: _handleSSEError,
          onDone: _handleSSEDone,
        );

        debugPrint('✅ NotificationService: SSE stream listener attached');
        debugPrint('✅ NotificationService: SSE connection established');
        _handleConnectionEvent();
      } else {
        debugPrint('❌ NotificationService: SSE connection failed with status: ${response.statusCode}');
        try {
          final responseBody = await response.stream.bytesToString();
          debugPrint('❌ NotificationService: Response body: $responseBody');
        } catch (e) {
          debugPrint('❌ NotificationService: Could not read response body: $e');
        }
        throw HttpException('Failed to connect: ${response.statusCode}');
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ NotificationService: Failed to connect to SSE: $e');
      debugPrint('❌ NotificationService: Stack trace: $stackTrace');
      _handleConnectionFailure();
    }
  }

  /// Disconnect from SSE stream
  Future<void> disconnect() async {
    debugPrint('🔔 NotificationService: Disconnecting from SSE');
    
    _httpClient?.close();
    _httpClient = null;
    _sseStream = null;
    
    _isConnected = false;
    _connectionStatusController.add(false);
  }

  /// Handle incoming SSE lines
  void _handleSSELine(String line) {
    try {
      // Handle heartbeat (raw text, not JSON)
      if (line.startsWith(':')) {
        debugPrint('💓 NotificationService: Heartbeat received');
        return;
      }

      // Log all non-heartbeat lines for debugging
      debugPrint('🔔 NotificationService: SSE line received: $line');

      // Handle data lines
      if (line.startsWith('data:')) {
        final jsonString = line.substring(5).trim(); // Remove 'data:' prefix
        if (jsonString.isEmpty) {
          debugPrint('⚠️ NotificationService: Empty JSON data');
          return;
        }
        
        debugPrint('🔔 NotificationService: Parsing JSON: $jsonString');
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        final sseEvent = SSEEventEntity.fromJson(data);
        
        debugPrint('🔔 NotificationService: Received event: ${sseEvent.type}');

        switch (sseEvent.type) {
          case 'connected':
            _handleConnectionEvent();
            break;
          case 'like':
          case 'reply':
          case 'follow':
          case 'mention':
          case 'comment':
          case 'follow_request':
            _handleNotificationEvent(sseEvent);
            break;
          case 'notification_deleted':
            _handleNotificationDeletedEvent(sseEvent);
            break;
          case 'unread_count':
            // Handle explicit unread count updates
            if (sseEvent.data != null && sseEvent.data!.containsKey('count')) {
              _unreadCount = sseEvent.data!['count'] as int;
              _unreadCountController.add(_unreadCount);
              debugPrint('🔔 NotificationService: Unread count updated: $_unreadCount');
            }
            break;
          default:
            debugPrint('🔔 NotificationService: Unknown event type: ${sseEvent.type}');
            // Try to extract unread count from any event data
            if (sseEvent.data != null && sseEvent.data!.containsKey('unreadCount')) {
              _unreadCount = sseEvent.data!['unreadCount'] as int;
              _unreadCountController.add(_unreadCount);
              debugPrint('🔔 NotificationService: Extracted unread count from event: $_unreadCount');
            }
        }
      }
    } catch (e) {
      debugPrint('❌ NotificationService: Error parsing SSE line: $e');
    }
  }

  /// Handle SSE errors
  void _handleSSEError(dynamic error) {
    debugPrint('❌ NotificationService: SSE error: $error');
    _handleConnectionFailure();
    
    // Attempt to reconnect after 5 seconds
    Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        debugPrint('🔄 NotificationService: Attempting to reconnect...');
        // connect();
      }
    });
  }

  /// Handle SSE connection closed
  void _handleSSEDone() {
    debugPrint('🔔 NotificationService: SSE connection closed');
    _handleConnectionFailure();
  }

  /// Handle successful connection
  void _handleConnectionEvent() {
    debugPrint('✅ NotificationService: Connected to notification stream');
    _isConnected = true;
    _connectionStatusController.add(true);
    
    // Fetch initial unread count
    fetchUnreadCount();
  }

  /// Handle new notification events
  void _handleNotificationEvent(SSEEventEntity sseEvent) {
    final notification = sseEvent.toNotification();
    if (notification == null) {
      debugPrint('❌ NotificationService: Failed to parse notification');
      return;
    }

    // Add to notifications list
    _notifications.insert(0, notification); // Add to beginning for chronological order
    
    // Update unread count
    _unreadCount = notification.unreadCount;
    debugPrint('🔔 NotificationService: Updated unread count: $_unreadCount (from notification.unreadCount: ${notification.unreadCount})');
    
    // Emit updates
    _notificationController.add(notification);
    _unreadCountController.add(_unreadCount);
    debugPrint('🔔 NotificationService: Emitted unread count: $_unreadCount');
    
    debugPrint('🔔 NotificationService: New ${notification.type.name} notification from ${notification.actor.username}');
  }

  /// Handle notification deletion events
  void _handleNotificationDeletedEvent(SSEEventEntity sseEvent) {
    final deletedNotification = sseEvent.toDeletedNotification();
    if (deletedNotification == null) {
      debugPrint('❌ NotificationService: Failed to parse deleted notification');
      return;
    }

    // Remove matching notification from list
    _notifications.removeWhere((notification) => 
      notification.type == deletedNotification.type &&
      notification.actor.id == deletedNotification.actorId &&
      notification.postId == deletedNotification.postId
    );
    
    // Update unread count
    _unreadCount = deletedNotification.unreadCount;
    
    // Emit updates
    _deletedNotificationController.add(deletedNotification);
    _unreadCountController.add(_unreadCount);
    
    debugPrint('🔔 NotificationService: Deleted ${deletedNotification.type.name} notification from ${deletedNotification.actorId}');
  }

  /// Handle connection failure
  void _handleConnectionFailure() {
    _isConnected = false;
    _connectionStatusController.add(false);
    _httpClient?.close();
    _httpClient = null;
    _sseStream = null;
  }

  /// Fetch current unread count from API
  Future<void> fetchUnreadCount() async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('❌ NotificationService: No access token for unread count');
        return;
      }

      debugPrint('🔔 NotificationService: Fetching unread count...');
      
      final response = await SecureApiClient.instance.request(
        path: ApiEndpoints.unreadCount,
        method: 'GET',
      );
      
      if (response.statusCode == 200) {
        final unreadCountEntity = UnreadCountEntity.fromJson(response.data);
        _unreadCount = unreadCountEntity.count;
        _unreadCountController.add(_unreadCount);
        debugPrint('✅ NotificationService: Unread count updated: $_unreadCount');
      } else {
        debugPrint('❌ NotificationService: Failed to fetch unread count: ${response.statusCode}');
      }
      
    } catch (e) {
      debugPrint('❌ NotificationService: Failed to fetch unread count: $e');
    }
  }

  /// Mark all notifications as seen
  Future<bool> markAllAsSeen() async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('❌ NotificationService: No access token for mark as seen');
        return false;
      }

      debugPrint('🔔 NotificationService: Marking all notifications as seen...');
      
      final response = await SecureApiClient.instance.request(
        path: ApiEndpoints.markSeen,
        method: 'POST',
      );
      
      if (response.statusCode == 200) {
        final markAsSeenResponse = MarkAsSeenResponseEntity.fromJson(response.data);
        
        if (markAsSeenResponse.success) {
          // Reset unread count to 0
          _unreadCount = 0;
          _unreadCountController.add(0);
          
          debugPrint('✅ NotificationService: All notifications marked as seen');
          return true;
        } else {
          debugPrint('❌ NotificationService: Mark as seen failed: ${markAsSeenResponse.message}');
          return false;
        }
      } else {
        debugPrint('❌ NotificationService: Mark as seen API call failed: ${response.statusCode}');
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ NotificationService: Failed to mark notifications as seen: $e');
      return false;
    }
  }

  /// Filter notifications by type
  List<NotificationEntity> getFilteredNotifications(NotificationFilter filter) {
    return _notifications.where((notification) => 
      filter.shouldShowNotification(notification.type)
    ).toList();
  }

  /// Clear all notifications (for testing)
  void clearNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    _unreadCountController.add(0);
  }

  /// Update unread count (called after marking all as seen)
  /// This syncs the count across all NotificationBloc instances
  void setUnreadCount(int count) {
    _unreadCount = count;
    _unreadCountController.add(count);
    debugPrint('🔔 NotificationService: Unread count set to $count');
  }

  /// Add a test notification (for debugging)
  void addTestNotification() {
    final testNotification = NotificationEntity(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.like,
      message: 'Test notification',
      actor: const NotificationActorEntity(
        id: 'test_user',
        username: 'test_user',
        fullName: 'Test User',
        profileImageUrl: null,
      ),
      postId: 'test_post',
      createdAt: DateTime.now(),
      unreadCount: _unreadCount + 1,
    );
    
    _notifications.insert(0, testNotification);
    _unreadCount++;
    _notificationController.add(testNotification);
    _unreadCountController.add(_unreadCount);
    
    debugPrint('🔔 NotificationService: Added test notification');
  }

  /// Check backend connectivity
  Future<bool> testConnection() async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('❌ NotificationService: No access token for connection test');
        return false;
      }

      debugPrint('🔔 NotificationService: Testing backend connectivity...');
      
      // Test by fetching unread count
      final response = await SecureApiClient.instance.request(
        path: ApiEndpoints.unreadCount,
        method: 'GET',
      );
      
      if (response.statusCode == 200) {
        debugPrint('✅ NotificationService: Backend connection successful');
        return true;
      } else {
        debugPrint('❌ NotificationService: Backend connection failed: ${response.statusCode}');
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ NotificationService: Backend connection error: $e');
      return false;
    }
  }

  /// Get access token from storage
  Future<String?> _getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.accessTokenKey);
    } catch (e) {
      debugPrint('❌ NotificationService: Failed to get access token: $e');
      return null;
    }
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    _notificationController.close();
    _deletedNotificationController.close();
    _unreadCountController.close();
    _connectionStatusController.close();
  }
}