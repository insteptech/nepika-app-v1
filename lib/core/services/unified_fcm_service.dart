import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_logger.dart';
import '../api_base.dart';
import '../../firebase_options.dart';
import '../services/navigation_service.dart';

/// Unified FCM Service
/// Handles all Firebase Cloud Messaging functionality including:
/// - Firebase initialization
/// - Token management with validation
/// - Notification handling (foreground, background, terminated)
/// - Permission management
/// - Local notification display
/// - Proper error handling and logging
/// - Memory leak prevention
class UnifiedFcmService {
  static final UnifiedFcmService _instance = UnifiedFcmService._internal();
  static UnifiedFcmService get instance => _instance;

  UnifiedFcmService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  // Service state
  bool _isInitialized = false;
  bool _permissionsGranted = false;
  String? _currentToken;
  
  // Stream subscriptions for proper disposal
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  StreamSubscription<String>? _onTokenRefreshSubscription;
  
  // Token refresh debouncing
  Timer? _tokenRefreshDebounceTimer;
  static const Duration _tokenRefreshDebounceDelay = Duration(seconds: 5);
  
  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  
  // Notification ID management
  static const int _maxNotificationId = 2147483647; // Max int32 value
  int _lastNotificationId = 0;

  /// Public getters
  bool get isInitialized => _isInitialized;
  bool get permissionsGranted => _permissionsGranted;
  String? get currentToken => _currentToken;

  /// Initialize the complete FCM service
  /// This should be called once during app startup
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.warning('FCM service already initialized', tag: 'FCM');
      return;
    }

    try {
      AppLogger.info('Initializing unified FCM service...', tag: 'FCM');

      // 1. Initialize Firebase
      await _initializeFirebase();
      
      // 2. Request permissions
      await _requestPermissions();
      
      // 3. Initialize local notifications
      await _initializeLocalNotifications();
      
      // 4. Set up message handlers
      await _setupMessageHandlers();
      
      // 5. Initialize token management
      await _initializeTokenManagement();
      
      _isInitialized = true;
      AppLogger.success('FCM service initialized successfully', tag: 'FCM');
      
    } catch (e, stackTrace) {
      AppLogger.error(
        'FCM service initialization failed',
        tag: 'FCM',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Initialize Firebase with proper configuration
  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Enable auto-initialization
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      
      AppLogger.success('Firebase initialized with proper configuration', tag: 'FCM');
    } catch (e) {
      AppLogger.error('Firebase initialization failed', tag: 'FCM', error: e);
      rethrow;
    }
  }

  /// Request all necessary permissions
  Future<void> _requestPermissions() async {
    try {
      // Request FCM permissions
      final NotificationSettings fcmSettings = 
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        announcement: false,
      );

      // Request system notification permission (Android 13+)
      if (Platform.isAndroid) {
        final PermissionStatus status = await Permission.notification.request();
        _permissionsGranted = status.isGranted && 
            fcmSettings.authorizationStatus == AuthorizationStatus.authorized;
      } else {
        _permissionsGranted = fcmSettings.authorizationStatus == AuthorizationStatus.authorized ||
            fcmSettings.authorizationStatus == AuthorizationStatus.provisional;
      }

      AppLogger.info(
        'Notification permissions: FCM=${fcmSettings.authorizationStatus}, '
        'System=$_permissionsGranted',
        tag: 'FCM',
      );
    } catch (e) {
      AppLogger.error('Permission request failed', tag: 'FCM', error: e);
      _permissionsGranted = false;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false, // Already requested via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _createAndroidNotificationChannel();
    }

    AppLogger.success('Local notifications initialized', tag: 'FCM');
  }

  /// Create Android notification channel
  Future<void> _createAndroidNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'nepika_notifications',
      'Nepika Notifications',
      description: 'App notifications and reminders',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  /// Set up message handlers for different app states
  Future<void> _setupMessageHandlers() async {
    // Foreground messages
    _onMessageSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
      onError: (error) => AppLogger.error(
        'Foreground message handler error',
        tag: 'FCM',
        error: error,
      ),
    );

    // Background tap messages
    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleBackgroundTap,
      onError: (error) => AppLogger.error(
        'Background tap handler error',
        tag: 'FCM',
        error: error,
      ),
    );

    // Check for terminated app launch
    final RemoteMessage? initialMessage = 
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      AppLogger.info('App launched via notification', tag: 'FCM');
      _handleNotificationNavigation(initialMessage.data);
    }

    AppLogger.success('Message handlers configured', tag: 'FCM');
  }

  /// Initialize token management with refresh handling
  Future<void> _initializeTokenManagement() async {
    try {
      // Get initial token
      await _refreshToken();

      // Listen for token refresh
      _onTokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
        _handleTokenRefresh,
        onError: (error) => AppLogger.error(
          'Token refresh listener error',
          tag: 'FCM',
          error: error,
        ),
      );

      AppLogger.success('Token management initialized', tag: 'FCM');
    } catch (e) {
      AppLogger.error('Token management initialization failed', tag: 'FCM', error: e);
    }
  }

  /// Handle token refresh with debouncing
  void _handleTokenRefresh(String newToken) {
    AppLogger.info('FCM token refresh detected', tag: 'FCM');
    
    // Cancel previous debounce timer
    _tokenRefreshDebounceTimer?.cancel();
    
    // Start new debounce timer
    _tokenRefreshDebounceTimer = Timer(_tokenRefreshDebounceDelay, () {
      _refreshToken();
    });
  }

  /// Refresh and validate FCM token
  Future<void> _refreshToken() async {
    try {
      final String? token = await _getTokenWithRetry();
      
      if (token != null && _validateFcmToken(token)) {
        final bool tokenChanged = _currentToken != token;
        _currentToken = token;
        
        if (tokenChanged) {
          AppLogger.info(
            'FCM token updated: ${token.substring(0, 20)}...',
            tag: 'FCM',
          );
          
          // Save to backend (implement based on your API)
          await _saveTokenToBackend(token);
        }
      } else {
        AppLogger.warning('Invalid or null FCM token received', tag: 'FCM');
      }
    } catch (e) {
      AppLogger.error('Token refresh failed', tag: 'FCM', error: e);
    }
  }

  /// Get FCM token with retry logic
  Future<String?> _getTokenWithRetry() async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final String? token = await FirebaseMessaging.instance.getToken();
        
        if (token != null && token.isNotEmpty) {
          return token;
        }
        
        if (attempt < _maxRetries) {
          final Duration delay = _baseRetryDelay * attempt;
          AppLogger.info(
            'Token retrieval attempt $attempt failed, retrying in ${delay.inSeconds}s',
            tag: 'FCM',
          );
          await Future.delayed(delay);
        }
      } catch (e) {
        AppLogger.error(
          'Token retrieval attempt $attempt failed',
          tag: 'FCM',
          error: e,
        );
        
        if (attempt == _maxRetries) rethrow;
        await Future.delayed(_baseRetryDelay * attempt);
      }
    }
    
    return null;
  }

  /// Validate FCM token format
  bool _validateFcmToken(String token) {
    if (token.isEmpty) return false;
    
    // FCM tokens are typically base64url encoded and quite long
    if (token.length < 140) return false; // Minimum realistic length
    
    // Should not contain whitespace or special characters except - and _
    final RegExp validTokenPattern = RegExp(r'^[A-Za-z0-9_-]+$');
    if (!validTokenPattern.hasMatch(token)) return false;
    
    // Should not be a fallback token
    if (token.startsWith('fcm-fallback-') || token.startsWith('fcm-error-')) {
      return false;
    }
    
    return true;
  }

  /// Save token to backend
  Future<void> _saveTokenToBackend(String token) async {
    try {
      final apiBase = ApiBase();
      final response = await apiBase.request(
        path: '/auth/users/save-fcm-token',
        method: 'POST',
        body: {'fcm_token': token},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        AppLogger.success('FCM token saved to backend', tag: 'FCM');
      } else {
        throw Exception('Backend rejected token: ${response.data['message']}');
      }
    } catch (e) {
      AppLogger.error('Failed to save token to backend', tag: 'FCM', error: e);
      // Don't rethrow - token saving failure shouldn't break the app
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info(
      'Foreground message received: ${message.notification?.title}',
      tag: 'FCM',
    );
    
    // Show local notification in foreground
    _showLocalNotification(message);
  }

  /// Handle background tap
  void _handleBackgroundTap(RemoteMessage message) {
    AppLogger.info('Background notification tapped', tag: 'FCM');
    _handleNotificationNavigation(message.data);
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    AppLogger.info('Local notification tapped', tag: 'FCM');
    
    if (response.payload != null) {
      try {
        // Parse payload as notification data
        // You can implement custom payload parsing here
        _handleNotificationNavigation({'screen': response.payload});
      } catch (e) {
        AppLogger.error('Failed to parse notification payload', tag: 'FCM', error: e);
      }
    }
  }

  /// Handle notification navigation
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    try {
      final String? screen = data['screen'];
      final String? userId = data['user_id'];
      final String? postId = data['post_id'];
      
      // Navigate based on notification data
      switch (screen) {
        case 'dashboard':
          NavigationService.navigateTo('/dashboard');
          break;
        case 'community':
          NavigationService.navigateTo('/community');
          break;
        case 'user_profile':
          if (userId != null) {
            NavigationService.navigateTo('/community/user/$userId');
          }
          break;
        case 'post_detail':
          if (postId != null) {
            NavigationService.navigateTo('/community/post/$postId');
          }
          break;
        case 'notifications':
          NavigationService.navigateTo('/notifications');
          break;
        default:
          // Default to dashboard
          NavigationService.navigateTo('/dashboard');
      }
    } catch (e) {
      AppLogger.error('Navigation handling failed', tag: 'FCM', error: e);
      // Fallback to dashboard
      NavigationService.navigateTo('/dashboard');
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final data = message.data;

      String title = notification?.title ?? 
                    data['title'] ?? 
                    'Nepika';
      String body = notification?.body ?? 
                   data['body'] ?? 
                   'You have a new notification';

      final int notificationId = _generateNotificationId();

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'nepika_notifications',
        'Nepika Notifications',
        channelDescription: 'App notifications and reminders',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      await _localNotifications.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: data['screen'], // Pass screen for navigation
      );

      AppLogger.success('Local notification displayed', tag: 'FCM');
    } catch (e) {
      AppLogger.error('Failed to show local notification', tag: 'FCM', error: e);
    }
  }

  /// Generate unique notification ID to prevent collisions
  int _generateNotificationId() {
    _lastNotificationId = (_lastNotificationId + 1) % _maxNotificationId;
    return _lastNotificationId;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      final NotificationSettings settings = 
          await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    return false;
  }

  /// Force refresh token (useful for testing)
  Future<String?> forceRefreshToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
      await _refreshToken();
      return _currentToken;
    } catch (e) {
      AppLogger.error('Force token refresh failed', tag: 'FCM', error: e);
      return null;
    }
  }

  /// Clear token (useful for logout)
  Future<void> clearToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
      _currentToken = null;
      AppLogger.success('FCM token cleared', tag: 'FCM');
    } catch (e) {
      AppLogger.error('Failed to clear FCM token', tag: 'FCM', error: e);
    }
  }

  /// Dispose of resources and subscriptions
  void dispose() {
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    _onTokenRefreshSubscription?.cancel();
    _tokenRefreshDebounceTimer?.cancel();
    
    _isInitialized = false;
    AppLogger.info('FCM service disposed', tag: 'FCM');
  }

  /// Get service status for debugging
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'permissionsGranted': _permissionsGranted,
      'hasToken': _currentToken != null,
      'tokenLength': _currentToken?.length ?? 0,
      'activeSubscriptions': {
        'onMessage': _onMessageSubscription != null,
        'onMessageOpenedApp': _onMessageOpenedAppSubscription != null,
        'onTokenRefresh': _onTokenRefreshSubscription != null,
      },
      'hasDebounceTimer': _tokenRefreshDebounceTimer?.isActive ?? false,
    };
  }
}