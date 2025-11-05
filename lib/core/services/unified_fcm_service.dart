import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import '../api_base.dart';
import '../di/injection_container.dart';
import '../../domain/fcm/usecases/save_fcm_token_usecase.dart';
import '../../firebase_options.dart';
import '../services/navigation_service.dart';
import 'local_notification_service.dart';

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
  
  // Token management state
  bool _isTokenGenerating = false;
  bool _isTokenSaving = false;
  DateTime? _lastTokenAttempt;
  int _consecutiveFailures = 0;
  
  // Message deduplication
  final Set<String> _processedMessageIds = <String>{};
  static const int _maxProcessedMessages = 100; // Keep last 100 message IDs
  
  // Stream subscriptions for proper disposal
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  StreamSubscription<String>? _onTokenRefreshSubscription;
  
  // Token refresh debouncing
  Timer? _tokenRefreshDebounceTimer;
  static const Duration _tokenRefreshDebounceDelay = Duration(seconds: 3);
  
  // Optimized retry configuration
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  static const Duration _circuitBreakerTimeout = Duration(minutes: 5);
  static const int _circuitBreakerThreshold = 3;
  
  // Notification ID management
  static const int _maxNotificationId = 2147483647; // Max int32 value
  int _lastNotificationId = 0;

  /// Public getters
  bool get isInitialized => _isInitialized;
  bool get permissionsGranted => _permissionsGranted;
  String? get currentToken => _currentToken;
  bool get isTokenGenerating => _isTokenGenerating;
  bool get isInCircuitBreaker => _isCircuitBreakerActive();

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

  /// Initialize local notifications with iOS foreground support
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // FIXED: Enhanced iOS settings for foreground notifications
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: false,
      requestProvisionalPermission: true, // iOS 12+ provisional notifications
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
      onDidReceiveBackgroundNotificationResponse: _handleBackgroundNotificationTap,
    );

    // CRITICAL: Create Android notification channel first (before any notifications)
    if (Platform.isAndroid) {
      await _createAndroidNotificationChannel();
      AppLogger.info('Android notification channel created with max importance', tag: 'FCM');
    }

    // CRITICAL: Configure iOS foreground notification presentation
    if (Platform.isIOS) {
      await _configureIOSForegroundNotifications();
    }

    AppLogger.success('Local notifications initialized with foreground support', tag: 'FCM');
  }

  /// Create Android notification channel
  Future<void> _createAndroidNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'nepika_notifications',
      'Nepika Notifications',
      description: 'App notifications and reminders',
      importance: Importance.max,  // CRITICAL: Must be max for Android notifications to show
      enableVibration: true,
      playSound: true,
      showBadge: true,
      enableLights: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      AppLogger.success('Android notification channel created', tag: 'FCM');
    }
  }

  /// CRITICAL: Configure iOS foreground notification presentation
  Future<void> _configureIOSForegroundNotifications() async {
    try {
      // Check if LocalNotificationService has already configured iOS notifications
      // to avoid duplicate permission requests
      bool skipPermissionRequest = false;
      try {
        final localNotificationService = LocalNotificationService.instance;
        final status = localNotificationService.getStatus();
        final isLocalNotificationInitialized = status['isInitialized'] as bool? ?? false;
        
        if (isLocalNotificationInitialized) {
          AppLogger.info('LocalNotificationService already configured iOS permissions, skipping permission request', tag: 'FCM');
          skipPermissionRequest = true;
        }
      } catch (e) {
        AppLogger.warning('Could not check LocalNotificationService status: $e', tag: 'FCM');
        // Continue with normal initialization
      }

      // Always get iOS plugin reference for FCM service (needed for local notifications)
      final IOSFlutterLocalNotificationsPlugin? iosPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        // Only request permissions if LocalNotificationService hasn't done it
        if (!skipPermissionRequest) {
          // Request comprehensive permissions
          final bool? permissionsGranted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: false,
            provisional: true, // iOS 12+ allows provisional notifications
          );

          AppLogger.info('iOS notification permissions granted: $permissionsGranted', tag: 'FCM');
        } else {
          AppLogger.info('Using existing iOS notification permissions from LocalNotificationService', tag: 'FCM');
        }

        // Configure Firebase Messaging for iOS foreground presentation
        // IMPORTANT: Disable automatic presentation to let local notifications handle it
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: false,  // Disable automatic alerts (let local notifications handle it)
          badge: true,   // Keep badge updates
          sound: false,  // Disable automatic sound (let local notifications handle it)
        );

        AppLogger.success('iOS foreground notification presentation configured', tag: 'FCM');
      }
    } catch (e) {
      AppLogger.error('Failed to configure iOS foreground notifications: $e', tag: 'FCM');
    }
  }


  /// Handle background notification response
  @pragma('vm:entry-point')
  static void _handleBackgroundNotificationTap(NotificationResponse response) {
    AppLogger.info('Background notification tapped: ${response.payload}', tag: 'FCM');
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
    // Prevent concurrent token generation
    if (_isTokenGenerating) {
      AppLogger.info('Token generation already in progress, skipping...', tag: 'FCM');
      return;
    }

    // Check circuit breaker
    if (_isCircuitBreakerActive()) {
      AppLogger.warning('Circuit breaker active, skipping token generation', tag: 'FCM');
      return;
    }

    _isTokenGenerating = true;
    
    try {
      AppLogger.info('Starting optimized token management initialization...', tag: 'FCM');
      
      // Check if we already have a valid cached token
      final cachedToken = await _getCachedValidToken();
      if (cachedToken != null) {
        _currentToken = cachedToken;
        AppLogger.success('Using cached valid token', tag: 'FCM');
        _resetCircuitBreaker();
        return;
      }
      
      // Get fresh token with smart retry
      AppLogger.info('Generating fresh FCM token...', tag: 'FCM');
      await _refreshTokenOptimized();

      if (_currentToken != null) {
        AppLogger.success('Fresh token generated successfully', tag: 'FCM');
        _resetCircuitBreaker();
      } else {
        AppLogger.warning('Token generation returned null', tag: 'FCM');
        _recordFailure();
      }

      // Set up token refresh listener (only once)
      _onTokenRefreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh.listen(
        _handleTokenRefresh,
        onError: (error) => AppLogger.error(
          'Token refresh listener error',
          tag: 'FCM',
          error: error,
        ),
      );

      AppLogger.success('Token management initialized successfully', tag: 'FCM');
    } catch (e) {
      AppLogger.error('Token management initialization failed', tag: 'FCM', error: e);
      _recordFailure();
    } finally {
      _isTokenGenerating = false;
    }
  }

  /// Handle token refresh with debouncing (FIXED - now uses the provided new token)
  void _handleTokenRefresh(String newToken) {
    AppLogger.info('FCM token refresh detected', tag: 'FCM');
    
    // Skip if circuit breaker is active
    if (_isCircuitBreakerActive()) {
      AppLogger.warning('Circuit breaker active, skipping token refresh', tag: 'FCM');
      return;
    }
    
    // Cancel previous debounce timer
    _tokenRefreshDebounceTimer?.cancel();
    
    // Start new debounce timer with the new token
    _tokenRefreshDebounceTimer = Timer(_tokenRefreshDebounceDelay, () {
      _processRefreshedToken(newToken);
    });
  }

  /// Process refreshed token (FIXED - uses provided token instead of making new API call)
  Future<void> _processRefreshedToken(String newToken) async {
    if (_isTokenSaving) {
      AppLogger.info('Token save already in progress, skipping refresh', tag: 'FCM');
      return;
    }

    try {
      AppLogger.info('Processing refreshed FCM token...', tag: 'FCM');
      
      // Validate the new token provided by Firebase
      if (_validateFcmTokenUnified(newToken)) {
        final bool tokenChanged = _currentToken != newToken;
        _currentToken = newToken;
        
        if (tokenChanged) {
          AppLogger.info('FCM token refreshed and updated successfully', tag: 'FCM');
          
          // Save to backend with proper error handling
          await _saveTokenToBackendOptimized(newToken);
        } else {
          AppLogger.info('Refreshed token is same as current, skipping backend save', tag: 'FCM');
        }
        
        _resetCircuitBreaker();
      } else {
        AppLogger.warning('Invalid refreshed FCM token received from Firebase', tag: 'FCM');
        _recordFailure();
        
        // Fallback: try to get a fresh token if the refreshed one is invalid
        await _refreshTokenOptimized();
      }
    } catch (e) {
      AppLogger.error('Processing refreshed token failed', tag: 'FCM', error: e);
      _recordFailure();
      
      // Fallback: try to get a fresh token
      await _refreshTokenOptimized();
    }
  }

  /// Optimized token refresh with unified validation (fallback method)
  Future<void> _refreshTokenOptimized() async {
    if (_isTokenSaving) {
      AppLogger.info('Token save already in progress, skipping refresh', tag: 'FCM');
      return;
    }

    try {
      AppLogger.info('Falling back to fresh token retrieval...', tag: 'FCM');
      final String? token = await _getTokenWithSmartRetry();
      
      if (token != null && _validateFcmTokenUnified(token)) {
        final bool tokenChanged = _currentToken != token;
        _currentToken = token;
        
        if (tokenChanged) {
          AppLogger.info('FCM token updated successfully via fallback', tag: 'FCM');
          
          // Save to backend with proper error handling
          await _saveTokenToBackendOptimized(token);
        } else {
          AppLogger.info('Fallback token unchanged, skipping backend save', tag: 'FCM');
        }
        
        _resetCircuitBreaker();
      } else {
        AppLogger.warning('Invalid or null FCM token received via fallback', tag: 'FCM');
        _recordFailure();
      }
    } catch (e) {
      AppLogger.error('Fallback token refresh failed', tag: 'FCM', error: e);
      _recordFailure();
    }
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

  /// Circuit breaker pattern methods
  bool _isCircuitBreakerActive() {
    if (_consecutiveFailures < _circuitBreakerThreshold) return false;
    
    final timeSinceLastAttempt = _lastTokenAttempt != null 
        ? DateTime.now().difference(_lastTokenAttempt!)
        : Duration.zero;
        
    return timeSinceLastAttempt < _circuitBreakerTimeout;
  }
  
  void _recordFailure() {
    _consecutiveFailures++;
    _lastTokenAttempt = DateTime.now();
    AppLogger.warning('FCM failure recorded. Count: $_consecutiveFailures', tag: 'FCM');
  }
  
  void _resetCircuitBreaker() {
    if (_consecutiveFailures > 0) {
      AppLogger.info('FCM circuit breaker reset. Previous failures: $_consecutiveFailures', tag: 'FCM');
      _consecutiveFailures = 0;
    }
  }

  /// Get cached valid token from local storage
  Future<String?> _getCachedValidToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedToken = prefs.getString('stored_fcm_token');
      final lastSaveTime = prefs.getInt('last_save_timestamp');
      
      if (cachedToken != null && lastSaveTime != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - lastSaveTime;
        // Token is valid for 24 hours
        if (cacheAge < 86400000 && _validateFcmTokenUnified(cachedToken)) {
          return cachedToken;
        }
      }
    } catch (e) {
      AppLogger.error('Error getting cached token', tag: 'FCM', error: e);
    }
    return null;
  }

  /// Smart retry with exponential backoff and jitter
  Future<String?> _getTokenWithSmartRetry() async {
    _lastTokenAttempt = DateTime.now();
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        AppLogger.info('Smart token retrieval attempt $attempt/$_maxRetries', tag: 'FCM');
        
        // Quick connectivity and readiness checks
        if (!await _isSystemReady()) {
          if (attempt < _maxRetries) {
            await _smartDelay(attempt);
            continue;
          }
          return null;
        }
        
        // Get token from Firebase
        final String? token = await FirebaseMessaging.instance.getToken();
        
        // CRITICAL DEBUG: Log actual token details for root cause analysis
        if (token != null) {
          AppLogger.info('🔍 TOKEN DEBUG - Length: ${token.length}, Preview: ${token.length > 20 ? token.substring(0, 20) : token}...', tag: 'FCM');
        } else {
          AppLogger.warning('🔍 TOKEN DEBUG - Token is null from Firebase', tag: 'FCM');
        }
        
        if (token != null && _validateFcmTokenUnified(token)) {
          AppLogger.success('Valid token retrieved on attempt $attempt', tag: 'FCM');
          return token;
        }
        
        if (attempt < _maxRetries) {
          await _smartDelay(attempt);
        }
        
      } catch (e) {
        AppLogger.error('Token retrieval attempt $attempt failed', tag: 'FCM', error: e);
        if (attempt == _maxRetries) return null;
        await _smartDelay(attempt);
      }
    }
    
    return null;
  }

  /// Smart delay with jitter to prevent thundering herd
  Future<void> _smartDelay(int attempt) async {
    final baseDelay = _baseRetryDelay.inMilliseconds * attempt;
    final jitter = (baseDelay * 0.1 * (DateTime.now().millisecond % 100) / 100).round();
    final totalDelay = Duration(milliseconds: baseDelay + jitter);
    await Future.delayed(totalDelay);
  }

  /// Fast system readiness check
  Future<bool> _isSystemReady() async {
    try {
      // Check permissions first (fastest)
      if (!_permissionsGranted) return false;
      
      // Quick Firebase check
      if (Firebase.apps.isEmpty) return false;
      
      // Basic connectivity (no external calls)
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
      
    } catch (e) {
      return false;
    }
  }

  /// Unified token validation (single source of truth)
  bool _validateFcmTokenUnified(String token) {
    AppLogger.info('🔍 VALIDATION DEBUG - Starting validation for token length: ${token.length}', tag: 'FCM');
    
    // Empty check
    if (token.isEmpty) {
      AppLogger.warning('❌ VALIDATION FAILED: Empty token received', tag: 'FCM');
      return false;
    }
    
    // Minimum length check (Firebase tokens are typically 140+ chars)
    if (token.length < 140) {
      AppLogger.warning('❌ VALIDATION FAILED: Token too short: ${token.length} chars (need 140+)', tag: 'FCM');
      return false;
    }
    
    // Format validation - FCM tokens are base64url encoded but can contain colons
    // Firebase FCM tokens have format: [base64url]:[base64url] which is normal
    final RegExp validTokenPattern = RegExp(r'^[A-Za-z0-9_:-]+$');
    if (!validTokenPattern.hasMatch(token)) {
      AppLogger.warning('❌ VALIDATION FAILED: Invalid token format - contains invalid characters', tag: 'FCM');
      // Show first few chars to debug what's invalid
      final preview = token.length > 50 ? token.substring(0, 50) : token;
      AppLogger.warning('❌ Token preview: $preview', tag: 'FCM');
      return false;
    }
    
    // Reject fallback/error tokens
    if (token.startsWith('fcm-fallback-') || token.startsWith('fcm-error-')) {
      AppLogger.warning('❌ VALIDATION FAILED: Fallback/error token received', tag: 'FCM');
      return false;
    }
    
    AppLogger.success('✅ VALIDATION PASSED: Token valid (length: ${token.length})', tag: 'FCM');
    return true;
  }


  /// FIXED: Use proper clean architecture for 100% success rate
  Future<void> _saveTokenToBackendOptimized(String token) async {
    if (_isTokenSaving) {
      AppLogger.info('Token save already in progress, skipping duplicate request', tag: 'FCM');
      return;
    }

    _isTokenSaving = true;
    
    try {
      AppLogger.info('Saving FCM token via clean architecture for 100% reliability...', tag: 'FCM');
      
      // Set the current token BEFORE calling use case to ensure consistency
      _currentToken = token;
      
      // Use the proper use case with built-in validation, retry logic, and error handling
      final saveFcmTokenUseCase = ServiceLocator.get<SaveFcmTokenUseCase>();
      
      // The use case handles all validation, duplication checks, and error scenarios
      final result = await saveFcmTokenUseCase.call();
      
      AppLogger.success('FCM token saved via use case: ${result.fcmToken.substring(0, 20)}...', tag: 'FCM');
      _resetCircuitBreaker();
      
    } catch (e) {
      AppLogger.error('Use case failed to save FCM token: $e', tag: 'FCM');
      _recordFailure();
      
      // Fallback to direct API call for backward compatibility
      await _saveTokenDirectFallback(token);
    } finally {
      _isTokenSaving = false;
    }
  }

  /// Fallback method using direct API call (for emergency use only)
  Future<void> _saveTokenDirectFallback(String token) async {
    try {
      AppLogger.warning('Using direct API fallback for token save', tag: 'FCM');
      
      final prefs = await SharedPreferences.getInstance();
      final lastSavedToken = prefs.getString('last_saved_fcm_token');
      
      if (lastSavedToken == token) {
        AppLogger.info('Token already saved (fallback check), skipping request', tag: 'FCM');
        return;
      }

      final apiBase = ApiBase();
      final response = await apiBase.request(
        path: '/auth/users/save-fcm-token',
        method: 'POST',
        body: {'fcm_token': token},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        await prefs.setString('stored_fcm_token', token);
        await prefs.setString('last_saved_fcm_token', token);
        await prefs.setInt('last_save_timestamp', DateTime.now().millisecondsSinceEpoch);
        
        AppLogger.success('FCM token saved via fallback API', tag: 'FCM');
        _resetCircuitBreaker();
      } else {
        final errorMessage = response.data['message'] ?? 'Unknown backend error';
        AppLogger.error('Fallback API rejected FCM token: $errorMessage', tag: 'FCM');
        _recordFailure();
        throw Exception('Fallback save failed: $errorMessage');
      }
    } catch (e) {
      AppLogger.error('Fallback token save failed', tag: 'FCM', error: e);
      _recordFailure();
      rethrow;
    }
  }


  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info(
      'Foreground message received: ${message.notification?.title}',
      tag: 'FCM',
    );
    
    AppLogger.info('🔥 FOREGROUND MESSAGE DEBUG:', tag: 'FCM');
    AppLogger.info('  - Message ID: ${message.messageId}', tag: 'FCM');
    AppLogger.info('  - Notification Title: ${message.notification?.title}', tag: 'FCM');
    AppLogger.info('  - Notification Body: ${message.notification?.body}', tag: 'FCM');
    AppLogger.info('  - Data: ${message.data}', tag: 'FCM');
    
    // Check for duplicate messages
    if (message.messageId != null) {
      if (_processedMessageIds.contains(message.messageId)) {
        AppLogger.info('  - ⚠️ DUPLICATE MESSAGE DETECTED - Skipping processing', tag: 'FCM');
        return;
      }
      _processedMessageIds.add(message.messageId!);
      AppLogger.info('  - ✅ New message - Added to processed set', tag: 'FCM');
    }
    
    // CRITICAL FIX: Always show local notifications for both platforms in foreground
    // This ensures notifications appear when app is open
    AppLogger.info('  - Showing local notification for foreground message...', tag: 'FCM');
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
      AppLogger.info('📱 SHOWING LOCAL NOTIFICATION:', tag: 'FCM');
      
      final notification = message.notification;
      final data = message.data;

      String title = notification?.title ?? 
                    data['title'] ?? 
                    'Nepika';
      String body = notification?.body ?? 
                   data['body'] ?? 
                   'You have a new notification';

      // Use message ID for uniqueness if available, otherwise generate
      final int notificationId = message.messageId != null 
          ? message.messageId.hashCode.abs() % 2147483647
          : _generateNotificationId();

      AppLogger.info('  - Title: $title', tag: 'FCM');
      AppLogger.info('  - Body: $body', tag: 'FCM');
      AppLogger.info('  - Notification ID: $notificationId', tag: 'FCM');

      // Enhanced Android notification details for better visibility
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'nepika_notifications',
        'Nepika Notifications',
        channelDescription: 'App notifications and reminders',
        importance: Importance.max,  // CRITICAL: Must match channel importance
        priority: Priority.max,      // CRITICAL: Must be max for immediate display
        showWhen: true,
        enableVibration: true,
        playSound: true,
        enableLights: true,
        autoCancel: true,
        ongoing: false,
        showProgress: false,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ticker: 'Nepika',
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.social,
      );

      // FIXED: Enhanced iOS notification details for foreground presentation
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,           // Show alert in foreground
        presentSound: true,           // Play sound in foreground
        presentBadge: true,           // Update badge in foreground
        interruptionLevel: InterruptionLevel.active,  // Active interruption
        categoryIdentifier: 'nepika_general',         // Custom category
        threadIdentifier: 'nepika_thread',            // Group notifications
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      AppLogger.info('  - Showing notification via LocalNotificationService...', tag: 'FCM');
      
      // Try to use LocalNotificationService first (if available)
      try {
        final localNotificationService = LocalNotificationService.instance;
        final success = await localNotificationService.showImmediateNotification(
          title: title,
          body: body,
        );
        
        if (success) {
          AppLogger.success('✅ Local notification displayed via LocalNotificationService!', tag: 'FCM');
          return;
        } else {
          AppLogger.warning('LocalNotificationService failed, falling back to FCM plugin...', tag: 'FCM');
        }
      } catch (e) {
        AppLogger.warning('LocalNotificationService unavailable, using FCM plugin: $e', tag: 'FCM');
      }
      
      // Fallback to own local notification plugin
      AppLogger.info('  - Calling _localNotifications.show() as fallback...', tag: 'FCM');
      
      await _localNotifications.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: data['screen'], // Pass screen for navigation
      );

      AppLogger.success('✅ Local notification displayed successfully!', tag: 'FCM');
      AppLogger.info('  - If you don\'t see the notification, check device permissions', tag: 'FCM');
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

  /// Generate token and ensure it's saved (recommended for dashboard)
  /// Returns the token only after ensuring it's saved to backend
  /// Includes iOS-specific permission handling
  Future<String?> generateTokenAndEnsureSaved() async {
    try {
      AppLogger.info('Generating FCM token with guaranteed backend save...', tag: 'FCM');
      
      // For iOS, ensure permissions are granted before token generation
      if (Platform.isIOS) {
        final hasPermission = await _ensureIOSPermissions();
        if (!hasPermission) {
          AppLogger.warning('iOS notification permissions not granted, skipping token generation', tag: 'FCM');
          return null;
        }
      }
      
      final token = await generateToken();
      if (token != null) {
        // Ensure token is saved before returning
        await _ensureTokenIsSaved(token);
        AppLogger.success('FCM token generated and saved successfully', tag: 'FCM');
        return token;
      } else {
        AppLogger.warning('FCM token generation failed', tag: 'FCM');
        return null;
      }
    } catch (e) {
      AppLogger.error('FCM token generation and save failed: $e', tag: 'FCM');
      return null;
    }
  }

  /// Ensure iOS permissions are granted before token generation
  Future<bool> _ensureIOSPermissions() async {
    try {
      AppLogger.info('Checking iOS notification permissions...', tag: 'FCM');
      
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      final hasPermission = settings.authorizationStatus == AuthorizationStatus.authorized ||
                           settings.authorizationStatus == AuthorizationStatus.provisional;
      
      if (!hasPermission) {
        AppLogger.info('iOS permissions not granted, requesting now...', tag: 'FCM');
        
        final newSettings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          announcement: false,
        );
        
        final newPermission = newSettings.authorizationStatus == AuthorizationStatus.authorized ||
                             newSettings.authorizationStatus == AuthorizationStatus.provisional;
        
        AppLogger.info('iOS permission request result: ${newSettings.authorizationStatus}, granted: $newPermission', tag: 'FCM');
        return newPermission;
      }
      
      AppLogger.info('iOS permissions already granted: ${settings.authorizationStatus}', tag: 'FCM');
      return true;
    } catch (e) {
      AppLogger.error('Failed to ensure iOS permissions: $e', tag: 'FCM');
      return false;
    }
  }

  /// Generate and retrieve FCM token (optimized for first-time users)
  /// Call this when user reaches dashboard to get the token
  Future<String?> generateToken() async {
    // If we already have a valid token, return it immediately
    if (_currentToken != null && _validateFcmTokenUnified(_currentToken!)) {
      AppLogger.info('Returning existing valid token', tag: 'FCM');
      return _currentToken;
    }

    // Initialize service if needed (non-blocking for first-time users)
    if (!_isInitialized) {
      AppLogger.info('FCM service not initialized, initializing for first-time user...', tag: 'FCM');
      await initializeWithoutToken();
    }
    
    // Skip token generation if circuit breaker is active
    if (_isCircuitBreakerActive()) {
      AppLogger.warning('Circuit breaker active, returning cached token if available', tag: 'FCM');
      return await _getCachedValidToken();
    }
    
    try {
      AppLogger.info('Generating FCM token optimized for user experience...', tag: 'FCM');
      await _initializeTokenManagement();
      
      // For first-time users, return token even if backend save fails
      if (_currentToken != null) {
        AppLogger.success('Token generated successfully for first-time user', tag: 'FCM');
        return _currentToken;
      } else {
        AppLogger.warning('Token generation failed, trying cached token', tag: 'FCM');
        return await _getCachedValidToken();
      }
    } catch (e) {
      AppLogger.error('Token generation failed, attempting fallback', tag: 'FCM', error: e);
      // Return cached token as fallback for better UX
      return await _getCachedValidToken();
    }
  }

  /// Fast token generation for first-time users (non-blocking UI)
  /// Returns a Future that resolves when token is generated and saved
  Future<void> generateTokenInBackground() async {
    // Run token generation in background without blocking UI
    Future.microtask(() async {
      try {
        AppLogger.info('Starting background FCM token generation...', tag: 'FCM');
        final token = await generateToken();
        
        if (token != null) {
          AppLogger.success('Background FCM token generated: ${token.substring(0, 20)}...', tag: 'FCM');
          
          // Ensure token is saved to backend
          await _ensureTokenIsSaved(token);
        } else {
          AppLogger.warning('Background FCM token generation returned null', tag: 'FCM');
        }
      } catch (e) {
        AppLogger.error('Background token generation failed: $e', tag: 'FCM');
      }
    });
  }

  /// Ensure token is saved to backend with retry mechanism
  Future<void> _ensureTokenIsSaved(String token) async {
    try {
      AppLogger.info('Ensuring FCM token is saved to backend...', tag: 'FCM');
      
      // Always force save to ensure backend has the token
      // This bypasses local cache checks to guarantee backend sync
      AppLogger.info('🔄 FORCE SAVING token to ensure backend sync', tag: 'FCM');
      
      await _saveTokenToBackendOptimized(token);
      
      AppLogger.success('FCM token save ensured successfully', tag: 'FCM');
    } catch (e) {
      AppLogger.error('Failed to ensure token is saved: $e', tag: 'FCM');
      
      // Retry once after delay
      await Future.delayed(const Duration(seconds: 3));
      try {
        AppLogger.info('🔄 RETRYING FCM token save...', tag: 'FCM');
        await _saveTokenToBackendOptimized(token);
        AppLogger.success('FCM token saved on retry', tag: 'FCM');
      } catch (retryError) {
        AppLogger.error('FCM token save retry failed: $retryError', tag: 'FCM');
        
        // Last resort: try direct fallback
        try {
          AppLogger.info('🔄 LAST RESORT: Using direct API fallback', tag: 'FCM');
          await _saveTokenDirectFallback(token);
          AppLogger.success('FCM token saved via direct fallback', tag: 'FCM');
        } catch (fallbackError) {
          AppLogger.error('All FCM token save attempts failed: $fallbackError', tag: 'FCM');
        }
      }
    }
  }

  /// Force refresh token (useful for testing)
  Future<String?> forceRefreshToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
      await _refreshTokenOptimized();
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

  /// Check if the backend FCM token matches current device token and is valid
  /// Returns true if backend token is valid and matches current device
  Future<bool> isBackendTokenValid(String? backendToken) async {
    try {
      AppLogger.info('🔍 Checking if backend FCM token is valid...', tag: 'FCM');
      
      // If backend token is null or empty, it's not valid
      if (backendToken == null || backendToken.isEmpty) {
        AppLogger.info('❌ Backend token is empty/null', tag: 'FCM');
        return false;
      }
      
      // Get current device token
      final currentToken = await generateToken();
      if (currentToken == null) {
        AppLogger.warning('⚠️ Could not get current device token for comparison', tag: 'FCM');
        return false;
      }
      
      // Compare tokens
      final tokensMatch = backendToken == currentToken;
      
      // Validate token format
      final isValidFormat = _validateFcmTokenUnified(backendToken);
      
      AppLogger.info('🔍 Token comparison results:', tag: 'FCM');
      AppLogger.info('  - Backend token: ${backendToken.substring(0, 20)}...', tag: 'FCM');
      AppLogger.info('  - Current token: ${currentToken.substring(0, 20)}...', tag: 'FCM');
      AppLogger.info('  - Tokens match: $tokensMatch', tag: 'FCM');
      AppLogger.info('  - Valid format: $isValidFormat', tag: 'FCM');
      
      final isValid = tokensMatch && isValidFormat;
      
      if (isValid) {
        AppLogger.success('✅ Backend FCM token is valid and matches current device', tag: 'FCM');
      } else {
        AppLogger.warning('❌ Backend FCM token is invalid or doesn\'t match current device', tag: 'FCM');
      }
      
      return isValid;
    } catch (e) {
      AppLogger.error('Error checking backend token validity: $e', tag: 'FCM');
      return false;
    }
  }

  /// Optimized token saving that checks backend token first
  /// Only saves if backend token is missing, invalid, or doesn't match current device
  Future<String?> generateTokenWithBackendCheck(String? backendToken) async {
    try {
      AppLogger.info('🔍 Starting optimized FCM token generation with backend check...', tag: 'FCM');
      
      // First check if backend token is valid
      final isBackendValid = await isBackendTokenValid(backendToken);
      
      if (isBackendValid) {
        AppLogger.success('✅ Backend token is valid, skipping save operation', tag: 'FCM');
        _currentToken = backendToken; // Update current token reference
        return backendToken;
      }
      
      // Backend token is invalid/missing, proceed with normal flow
      AppLogger.info('🔄 Backend token invalid, proceeding with token generation and save...', tag: 'FCM');
      return await generateTokenAndEnsureSaved();
      
    } catch (e) {
      AppLogger.error('Error in optimized token generation: $e', tag: 'FCM');
      // Fallback to normal generation
      return await generateTokenAndEnsureSaved();
    }
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

  /// Test foreground notification functionality (CRITICAL for debugging iOS issues)
  Future<bool> testForegroundNotification() async {
    try {
      AppLogger.info('🧪 TESTING FOREGROUND NOTIFICATION...', tag: 'FCM');

      // Check if service is initialized
      if (!_isInitialized) {
        AppLogger.error('❌ FCM service not initialized for testing', tag: 'FCM');
        return false;
      }

      // Run comprehensive diagnostics first
      AppLogger.info('🔍 Running notification diagnostics...', tag: 'FCM');
      final diagnostics = await runNotificationDiagnostics();
      AppLogger.info('📊 Diagnostics: $diagnostics', tag: 'FCM');

      // Create test message with unique ID to prevent duplicates
      final uniqueId = 'test_foreground_${DateTime.now().millisecondsSinceEpoch}';
      final testMessage = RemoteMessage(
        messageId: uniqueId,
        notification: const RemoteNotification(
          title: '🧪 FOREGROUND Test Notification',
          body: 'Testing foreground notification display - check if you see this!',
        ),
        data: {
          'screen': 'dashboard',
          'test': 'true',
          'type': 'foreground_test',
          'unique_id': uniqueId,
        },
      );

      AppLogger.info('📱 Simulating foreground message handler...', tag: 'FCM');
      _handleForegroundMessage(testMessage);
      
      AppLogger.success('✅ Test notification triggered - check your device!', tag: 'FCM');
      return true;
    } catch (e) {
      AppLogger.error('❌ Test foreground notification failed', tag: 'FCM', error: e);
      return false;
    }
  }

  /// Test immediate local notification (bypass FCM)
  Future<bool> testImmediateNotification() async {
    try {
      AppLogger.info('🚀 TESTING IMMEDIATE LOCAL NOTIFICATION...', tag: 'FCM');
      
      if (!_isInitialized) {
        AppLogger.error('❌ FCM service not initialized', tag: 'FCM');
        return false;
      }

      final uniqueId = DateTime.now().millisecondsSinceEpoch;
      
      await _localNotifications.show(
        uniqueId,
        '🚀 IMMEDIATE Test Notification',
        'This bypasses FCM and shows directly - if you see this, local notifications work!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'nepika_notifications',
            'Nepika Notifications',
            channelDescription: 'App notifications and reminders',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
          ),
        ),
      );

      AppLogger.success('✅ Immediate notification sent!', tag: 'FCM');
      return true;
    } catch (e) {
      AppLogger.error('❌ Immediate notification failed', tag: 'FCM', error: e);
      return false;
    }
  }

  /// Comprehensive notification diagnostics
  Future<Map<String, dynamic>> runNotificationDiagnostics() async {
    final diagnostics = <String, dynamic>{};
    
    try {
      AppLogger.info('Running comprehensive notification diagnostics...', tag: 'FCM');
      
      // Basic service status
      diagnostics['fcm_initialized'] = _isInitialized;
      diagnostics['permissions_granted'] = _permissionsGranted;
      diagnostics['has_token'] = _currentToken != null;
      diagnostics['platform'] = Platform.isIOS ? 'iOS' : 'Android';
      
      // FCM-specific checks
      try {
        final fcmSettings = await FirebaseMessaging.instance.getNotificationSettings();
        diagnostics['fcm_authorization'] = fcmSettings.authorizationStatus.toString();
        diagnostics['fcm_alert'] = fcmSettings.alert.toString();
        diagnostics['fcm_badge'] = fcmSettings.badge.toString();
        diagnostics['fcm_sound'] = fcmSettings.sound.toString();
        
        if (Platform.isIOS) {
          diagnostics['fcm_announcement'] = fcmSettings.announcement.toString();
          diagnostics['fcm_car_play'] = fcmSettings.carPlay.toString();
          diagnostics['fcm_critical_alert'] = fcmSettings.criticalAlert.toString();
          diagnostics['fcm_show_previews'] = fcmSettings.showPreviews.toString();
          // Note: provisional property not available in current firebase_messaging version
        }
      } catch (e) {
        diagnostics['fcm_settings_error'] = e.toString();
      }
      
      // Local notification checks
      try {
        final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final iosPlugin = _localNotifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        
        if (Platform.isAndroid && androidPlugin != null) {
          diagnostics['android_notifications_enabled'] = await androidPlugin.areNotificationsEnabled();
          diagnostics['android_exact_alarms'] = await androidPlugin.canScheduleExactNotifications();
        }
        
        if (Platform.isIOS && iosPlugin != null) {
          // Request permissions to check current status
          final iosPermissions = await iosPlugin.requestPermissions(
            alert: true, badge: true, sound: true,
          );
          diagnostics['ios_permissions_granted'] = iosPermissions;
        }
      } catch (e) {
        diagnostics['local_notifications_error'] = e.toString();
      }
      
      // Test notification capability
      try {
        diagnostics['test_notification_success'] = await testForegroundNotification();
      } catch (e) {
        diagnostics['test_notification_error'] = e.toString();
      }
      
      AppLogger.info('Notification diagnostics completed: $diagnostics', tag: 'FCM');
      return diagnostics;
    } catch (e) {
      diagnostics['diagnostics_error'] = e.toString();
      AppLogger.error('Notification diagnostics failed', tag: 'FCM', error: e);
      return diagnostics;
    }
  }

  /// Get token save status for debugging
  Future<Map<String, dynamic>> getTokenSaveStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSavedToken = prefs.getString('last_saved_fcm_token');
      final lastSaveTime = prefs.getInt('last_save_timestamp') ?? 0;
      final storedToken = prefs.getString('stored_fcm_token');
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final saveAge = lastSaveTime > 0 ? now - lastSaveTime : null;
      
      return {
        'currentToken': _currentToken?.substring(0, 20),
        'currentTokenLength': _currentToken?.length ?? 0,
        'lastSavedToken': lastSavedToken?.substring(0, 20),
        'storedToken': storedToken?.substring(0, 20),
        'lastSaveTime': lastSaveTime > 0 ? DateTime.fromMillisecondsSinceEpoch(lastSaveTime).toString() : 'Never',
        'saveAgeMinutes': saveAge != null ? (saveAge / 60000).round() : null,
        'tokensMatch': _currentToken == lastSavedToken,
        'isTokenGenerating': _isTokenGenerating,
        'isTokenSaving': _isTokenSaving,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Test token save to backend (for debugging)
  Future<bool> testTokenSave() async {
    try {
      if (_currentToken == null) {
        AppLogger.warning('No current token to test save', tag: 'FCM');
        return false;
      }
      
      AppLogger.info('Testing token save to backend...', tag: 'FCM');
      await _ensureTokenIsSaved(_currentToken!);
      AppLogger.success('Token save test completed', tag: 'FCM');
      return true;
    } catch (e) {
      AppLogger.error('Token save test failed: $e', tag: 'FCM');
      return false;
    }
  }

  /// Print comprehensive debug information
  Future<void> printDebugInfo() async {
    try {
      AppLogger.info('=== FCM Service Debug Information ===', tag: 'FCM');
      
      // Service status
      final status = getStatus();
      AppLogger.info('Service Status: $status', tag: 'FCM');
      
      // Token save status
      final tokenStatus = await getTokenSaveStatus();
      AppLogger.info('Token Save Status: $tokenStatus', tag: 'FCM');
      
      // Device information
      AppLogger.info('Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}', tag: 'FCM');
      
      // Network connectivity
      final isConnected = await _checkNetworkConnectivity();
      AppLogger.info('Network Connected: $isConnected', tag: 'FCM');
      
      // Firebase status
      final firebaseReady = await _isFirebaseReady();
      AppLogger.info('Firebase Ready: $firebaseReady', tag: 'FCM');
      
      // Comprehensive notification diagnostics
      final notificationDiagnostics = await runNotificationDiagnostics();
      AppLogger.info('Notification Diagnostics: $notificationDiagnostics', tag: 'FCM');
      
      AppLogger.info('=== End Debug Information ===', tag: 'FCM');
    } catch (e) {
      AppLogger.error('Failed to print debug info: $e', tag: 'FCM');
    }
  }
}