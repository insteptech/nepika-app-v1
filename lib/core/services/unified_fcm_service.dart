import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  static const int _maxRetries = 5;
  static const Duration _baseRetryDelay = Duration(seconds: 3);
  
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
    await initializeWithoutToken();
    
    // After basic initialization, get the token
    await _initializeTokenManagement();
  }

  /// Initialize FCM service without token generation (for splash screen)
  /// This prepares FCM but doesn't attempt token generation yet
  Future<void> initializeWithoutToken() async {
    if (_isInitialized) {
      AppLogger.warning('FCM service already initialized', tag: 'FCM');
      return;
    }

    try {
      AppLogger.info('Initializing unified FCM service (without token)...', tag: 'FCM');

      // 1. Initialize Firebase
      await _initializeFirebase();
      
      // 2. Request permissions
      await _requestPermissions();
      
      // 3. Initialize local notifications
      await _initializeLocalNotifications();
      
      // 4. Set up message handlers
      await _setupMessageHandlers();
      
      _isInitialized = true;
      AppLogger.success('FCM service initialized successfully (without token)', tag: 'FCM');
      
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
      // Check if Firebase is already initialized
      try {
        Firebase.app(); // This will throw if not initialized
        AppLogger.info('Firebase already initialized, skipping initialization', tag: 'FCM');
      } catch (e) {
        // Firebase not initialized, proceed with initialization
        AppLogger.info('Firebase not initialized, initializing now...', tag: 'FCM');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        AppLogger.success('Firebase initialized with proper configuration', tag: 'FCM');
      }
      
      // Enable auto-initialization
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      
    } catch (e) {
      AppLogger.error('Firebase initialization failed', tag: 'FCM', error: e);
      rethrow;
    }
  }

  /// Request all necessary permissions with retry mechanism
  Future<void> _requestPermissions() async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 1);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        AppLogger.info('Requesting permissions (attempt $attempt/$maxRetries)', tag: 'FCM');
        
        // Request FCM permissions with explicit configuration
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
        bool systemPermissionGranted = true;
        if (Platform.isAndroid) {
          // Check current status first
          final PermissionStatus currentStatus = await Permission.notification.status;
          AppLogger.info('Current notification permission status: $currentStatus', tag: 'FCM');
          
          if (currentStatus.isDenied) {
            final PermissionStatus requestedStatus = await Permission.notification.request();
            systemPermissionGranted = requestedStatus.isGranted;
            AppLogger.info('Requested notification permission result: $requestedStatus', tag: 'FCM');
          } else {
            systemPermissionGranted = currentStatus.isGranted;
          }
          
          _permissionsGranted = systemPermissionGranted && 
              fcmSettings.authorizationStatus == AuthorizationStatus.authorized;
        } else {
          _permissionsGranted = fcmSettings.authorizationStatus == AuthorizationStatus.authorized ||
              fcmSettings.authorizationStatus == AuthorizationStatus.provisional;
        }

        AppLogger.info(
          'Permission results - FCM: ${fcmSettings.authorizationStatus}, '
          'System: $systemPermissionGranted, Final: $_permissionsGranted',
          tag: 'FCM',
        );
        
        // If permissions are granted, break out of retry loop
        if (_permissionsGranted) {
          AppLogger.success('All permissions granted successfully', tag: 'FCM');
          return;
        }
        
        // If this is not the last attempt and permissions failed, retry
        if (attempt < maxRetries) {
          AppLogger.warning(
            'Permissions not fully granted, retrying in ${retryDelay.inSeconds}s...',
            tag: 'FCM',
          );
          await Future.delayed(retryDelay);
        }
        
      } catch (e) {
        AppLogger.error('Permission request attempt $attempt failed', tag: 'FCM', error: e);
        
        if (attempt == maxRetries) {
          _permissionsGranted = false;
          AppLogger.error('Permission request failed after $maxRetries attempts', tag: 'FCM');
          return;
        }
        
        await Future.delayed(retryDelay);
      }
    }
    
    // Final fallback - check if we have any permissions at all
    try {
      final NotificationSettings finalCheck = 
          await FirebaseMessaging.instance.getNotificationSettings();
      _permissionsGranted = finalCheck.authorizationStatus != AuthorizationStatus.denied &&
          finalCheck.authorizationStatus != AuthorizationStatus.notDetermined;
      
      AppLogger.warning(
        'Permission fallback check: ${finalCheck.authorizationStatus}, granted: $_permissionsGranted',
        tag: 'FCM',
      );
    } catch (e) {
      AppLogger.error('Permission fallback check failed', tag: 'FCM', error: e);
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
      AppLogger.info('Starting token management initialization...', tag: 'FCM');
      
      // Print debug info before token retrieval
      await printDebugInfo();
      
      // Get initial token with comprehensive logging
      AppLogger.info('Attempting to retrieve initial FCM token...', tag: 'FCM');
      await _refreshToken();

      if (_currentToken != null) {
        AppLogger.success('Initial token retrieved successfully', tag: 'FCM');
      } else {
        AppLogger.warning('Initial token retrieval returned null', tag: 'FCM');
      }

      // Listen for token refresh
      _onTokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
        _handleTokenRefresh,
        onError: (error) => AppLogger.error(
          'Token refresh listener error',
          tag: 'FCM',
          error: error,
        ),
      );

      AppLogger.success('Token management initialized with refresh listener', tag: 'FCM');
    } catch (e, stackTrace) {
      AppLogger.error('Token management initialization failed', tag: 'FCM', error: e);
      AppLogger.error('Stack trace: $stackTrace', tag: 'FCM');
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

  /// Get FCM token with robust retry logic and network checks
  Future<String?> _getTokenWithRetry() async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        AppLogger.info('Token retrieval attempt $attempt/$_maxRetries', tag: 'FCM');
        
        // Check network connectivity before attempting token retrieval
        if (!await _checkNetworkConnectivity()) {
          AppLogger.warning('No network connectivity on attempt $attempt', tag: 'FCM');
          if (attempt < _maxRetries) {
            await Future.delayed(_baseRetryDelay * attempt);
            continue;
          }
          return null;
        }
        
        // Check if Firebase is properly initialized
        if (!await _isFirebaseReady()) {
          AppLogger.warning('Firebase not ready on attempt $attempt', tag: 'FCM');
          if (attempt < _maxRetries) {
            await Future.delayed(_baseRetryDelay * attempt);
            continue;
          }
          return null;
        }
        
        // Check permissions before token retrieval
        if (!_permissionsGranted) {
          AppLogger.warning('Permissions not granted, attempting to re-request', tag: 'FCM');
          await _requestPermissions();
          if (!_permissionsGranted) {
            AppLogger.warning('Permissions still not granted on attempt $attempt', tag: 'FCM');
            if (attempt < _maxRetries) {
              await Future.delayed(_baseRetryDelay * attempt);
              continue;
            }
            return null;
          }
        }
        
        // Attempt to get the token
        AppLogger.info('Requesting FCM token from Firebase...', tag: 'FCM');
        final String? token = await FirebaseMessaging.instance.getToken();
        
        if (token != null && token.isNotEmpty && _validateFcmToken(token)) {
          AppLogger.success(
            'Valid FCM token received on attempt $attempt: ${token.substring(0, 20)}...',
            tag: 'FCM',
          );
          return token;
        } else {
          AppLogger.warning(
            'Invalid or null token received on attempt $attempt: ${token?.substring(0, 20) ?? 'null'}',
            tag: 'FCM',
          );
        }
        
        // If this is not the last attempt, wait before retrying
        if (attempt < _maxRetries) {
          final Duration delay = _baseRetryDelay * attempt;
          AppLogger.info(
            'Token retrieval failed, retrying in ${delay.inSeconds}s...',
            tag: 'FCM',
          );
          await Future.delayed(delay);
        }
        
      } catch (e, stackTrace) {
        AppLogger.error(
          'Token retrieval attempt $attempt failed with exception',
          tag: 'FCM',
          error: e,
        );
        
        if (attempt == _maxRetries) {
          AppLogger.error('Token retrieval failed after $attempt attempts', tag: 'FCM');
          AppLogger.error('Final error: $e', tag: 'FCM');
          AppLogger.error('Stack trace: $stackTrace', tag: 'FCM');
          return null;
        }
        
        await Future.delayed(_baseRetryDelay * attempt);
      }
    }
    
    AppLogger.error('Failed to retrieve FCM token after $_maxRetries attempts', tag: 'FCM');
    return null;
  }

  /// Check network connectivity
  Future<bool> _checkNetworkConnectivity() async {
    try {
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      
      // connectivity_plus 5.0.1 returns a single ConnectivityResult
      final isConnected = result == ConnectivityResult.mobile ||
                         result == ConnectivityResult.wifi ||
                         result == ConnectivityResult.ethernet;
      
      AppLogger.info('Network connectivity check: $isConnected ($result)', tag: 'FCM');
      return isConnected;
    } catch (e) {
      AppLogger.error('Network connectivity check failed', tag: 'FCM', error: e);
      // Assume connected if check fails
      return true;
    }
  }

  /// Check if Firebase is properly initialized and ready
  Future<bool> _isFirebaseReady() async {
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        AppLogger.warning('No Firebase apps found', tag: 'FCM');
        return false;
      }
      
      // Check if FirebaseMessaging is available
      final messaging = FirebaseMessaging.instance;
      
      // Try to get notification settings as a readiness check
      final settings = await messaging.getNotificationSettings();
      AppLogger.info('Firebase readiness check - Auth status: ${settings.authorizationStatus}', tag: 'FCM');
      
      return true;
    } catch (e) {
      AppLogger.error('Firebase readiness check failed', tag: 'FCM', error: e);
      return false;
    }
  }

  /// Validate FCM token format
  bool _validateFcmToken(String token) {
    // Accept any non-empty token that Firebase provides
    // Firebase tokens are always valid if they're generated by Firebase
    if (token.isEmpty) {
      AppLogger.warning('Empty token received', tag: 'FCM');
      return false;
    }
    
    // Should not be a fallback token
    if (token.startsWith('fcm-fallback-') || token.startsWith('fcm-error-')) {
      AppLogger.warning('Fallback/error token received: $token', tag: 'FCM');
      return false;
    }
    
    // All other tokens are valid - Firebase generates them correctly
    AppLogger.success('Token validation passed for token: ${token.substring(0, 10)}... (length: ${token.length})', tag: 'FCM');
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

  /// Generate and retrieve FCM token (for dashboard screen)
  /// Call this when user reaches dashboard to get the token
  Future<String?> generateToken() async {
    if (!_isInitialized) {
      AppLogger.warning('FCM service not initialized, initializing now...', tag: 'FCM');
      await initializeWithoutToken();
    }
    
    try {
      AppLogger.info('Generating FCM token from dashboard...', tag: 'FCM');
      await _initializeTokenManagement();
      return _currentToken;
    } catch (e) {
      AppLogger.error('Token generation from dashboard failed', tag: 'FCM', error: e);
      return null;
    }
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

  /// Get comprehensive service status for debugging
  Map<String, dynamic> getStatus() {
    return {
      'service': {
        'isInitialized': _isInitialized,
        'permissionsGranted': _permissionsGranted,
        'hasToken': _currentToken != null,
        'tokenLength': _currentToken?.length ?? 0,
        'tokenPreview': _currentToken?.substring(0, 20) ?? 'null',
      },
      'permissions': {
        'granted': _permissionsGranted,
      },
      'subscriptions': {
        'onMessage': _onMessageSubscription != null,
        'onMessageOpenedApp': _onMessageOpenedAppSubscription != null,
        'onTokenRefresh': _onTokenRefreshSubscription != null,
      },
      'timers': {
        'hasDebounceTimer': _tokenRefreshDebounceTimer?.isActive ?? false,
      },
      'firebase': {
        'appsCount': Firebase.apps.length,
        'appNames': Firebase.apps.map((app) => app.name).toList(),
      },
    };
  }

  /// Print comprehensive debug information
  Future<void> printDebugInfo() async {
    try {
      AppLogger.info('=== FCM Service Debug Information ===', tag: 'FCM');
      
      // Service status
      final status = getStatus();
      AppLogger.info('Service Status: $status', tag: 'FCM');
      
      // Device information
      AppLogger.info('Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}', tag: 'FCM');
      
      // Network connectivity
      final isConnected = await _checkNetworkConnectivity();
      AppLogger.info('Network Connected: $isConnected', tag: 'FCM');
      
      // Firebase status
      final firebaseReady = await _isFirebaseReady();
      AppLogger.info('Firebase Ready: $firebaseReady', tag: 'FCM');
      
      // Permission details
      if (Platform.isAndroid) {
        final notificationStatus = await Permission.notification.status;
        AppLogger.info('Android Notification Permission: $notificationStatus', tag: 'FCM');
      }
      
      // FCM settings
      try {
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        AppLogger.info('FCM Settings - Auth: ${settings.authorizationStatus}, '
                      'Alert: ${settings.alert}, Badge: ${settings.badge}, '
                      'Sound: ${settings.sound}', tag: 'FCM');
      } catch (e) {
        AppLogger.error('Failed to get FCM settings', tag: 'FCM', error: e);
      }
      
      AppLogger.info('=== End Debug Information ===', tag: 'FCM');
    } catch (e) {
      AppLogger.error('Failed to print debug info', tag: 'FCM', error: e);
    }
  }
}