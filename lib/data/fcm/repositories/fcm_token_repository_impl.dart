import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/services/unified_fcm_service.dart';
import 'package:nepika/core/utils/app_logger.dart';
import 'package:nepika/domain/fcm/entities/fcm_token_entity.dart';
import 'package:nepika/domain/fcm/repositories/fcm_token_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FcmTokenRepositoryImpl implements FcmTokenRepository {
  final ApiBase apiBase;

  // Cache SharedPreferences instance to avoid repeated async calls
  SharedPreferences? _cachedPrefs;

  // Local storage keys
  static const String _fcmTokenKey = 'stored_fcm_token';
  static const String _lastSavedTokenKey = 'last_saved_fcm_token';
  static const String _lastSaveTimestampKey = 'last_save_timestamp';

  FcmTokenRepositoryImpl({
    required this.apiBase,
  });

  /// Get SharedPreferences instance (cached)
  Future<SharedPreferences> get _prefs async {
    _cachedPrefs ??= await SharedPreferences.getInstance();
    return _cachedPrefs!;
  }

  @override
  Future<FcmTokenEntity> saveFcmToken({
    required String fcmToken,
    String? fcmRefreshToken,
  }) async {
    try {
      // Validate token before sending
      final validatedToken = _validateToken(fcmToken);
      if (validatedToken == null) {
        throw Exception('Invalid FCM token format');
      }

      AppLogger.info('Saving FCM token to backend...', tag: 'FCM_REPO');
      AppLogger.info('POST request details:', tag: 'FCM_REPO');
      AppLogger.info('  - Path: /auth/users/save-fcm-token', tag: 'FCM_REPO');
      AppLogger.info('  - Token length: ${validatedToken.length}', tag: 'FCM_REPO');
      AppLogger.info('  - Token preview: ${validatedToken.substring(0, 20)}...', tag: 'FCM_REPO');

      final response = await apiBase.request(
        path: '/auth/users/save-fcm-token',
        method: 'POST',
        body: {
          'fcm_token': validatedToken,
          if (fcmRefreshToken != null) 'fcm_refresh_token': fcmRefreshToken,
        },
      );

      AppLogger.info('FCM save response received:', tag: 'FCM_REPO');
      AppLogger.info('  - Status: ${response.statusCode}', tag: 'FCM_REPO');
      AppLogger.info('  - Response data: ${response.data}', tag: 'FCM_REPO');

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Store the token locally after successful API call
        await storeTokenLocally(validatedToken);
        await _storeLastSavedToken(validatedToken);
        await _storeLastSaveTimestamp();

        AppLogger.success('FCM token saved to backend successfully', tag: 'FCM_REPO');

        return FcmTokenEntity(
          fcmToken: validatedToken,
          fcmRefreshToken: fcmRefreshToken,
          lastUpdated: DateTime.now(),
          isActive: true,
        );
      } else {
        final errorMessage = response.data['message'] ?? 'Failed to save FCM token';
        AppLogger.error('Backend rejected FCM token: $errorMessage', tag: 'FCM_REPO');
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error saving FCM token',
        tag: 'FCM_REPO',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<String?> getCurrentFcmToken() async {
    try {
      // Use the unified FCM service to get the current token
      final unifiedService = UnifiedFcmService.instance;
      return unifiedService.currentToken;
    } catch (e) {
      AppLogger.error('Error getting current FCM token', tag: 'FCM_REPO', error: e);
      return null;
    }
  }

  @override
  Future<bool> hasTokenChanged(String newToken) async {
    try {
      final lastSavedToken = await _getLastSavedToken();
      return lastSavedToken != newToken;
    } catch (e) {
      AppLogger.error('Error checking token change', tag: 'FCM_REPO', error: e);
      return true; // Assume changed if we can't determine
    }
  }

  @override
  Future<String?> getStoredFcmToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fcmTokenKey);
    } catch (e) {
      AppLogger.error('Error getting stored FCM token', tag: 'FCM_REPO', error: e);
      return null;
    }
  }

  @override
  Future<void> storeTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
    } catch (e) {
      AppLogger.error('Error storing FCM token locally', tag: 'FCM_REPO', error: e);
      rethrow;
    }
  }

  @override
  Future<void> clearStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fcmTokenKey);
      await prefs.remove(_lastSavedTokenKey);
    } catch (e) {
      AppLogger.error('Error clearing stored FCM token', tag: 'FCM_REPO', error: e);
      rethrow;
    }
  }

  // Helper methods
  Future<void> _storeLastSavedToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSavedTokenKey, token);
    } catch (e) {
      AppLogger.error('Error storing last saved token', tag: 'FCM_REPO', error: e);
    }
  }

  Future<String?> _getLastSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastSavedTokenKey);
    } catch (e) {
      AppLogger.error('Error getting last saved token', tag: 'FCM_REPO', error: e);
      return null;
    }
  }

  /// Store timestamp of last successful save
  Future<void> _storeLastSaveTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSaveTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      AppLogger.error('Error storing last save timestamp', tag: 'FCM_REPO', error: e);
    }
  }

  /// Unified FCM token validation (matches UnifiedFcmService validation)
  String? _validateToken(String token) {
    // Empty check
    if (token.isEmpty) {
      AppLogger.warning('Empty token received in repository', tag: 'FCM_REPO');
      return null;
    }
    
    // Minimum length check (Firebase tokens are typically 140+ chars)
    if (token.length < 140) {
      AppLogger.warning('Token too short in repository: ${token.length} chars', tag: 'FCM_REPO');
      return null;
    }
    
    // Format validation - FCM tokens are base64url encoded but can contain colons
    // Firebase FCM tokens have format: [base64url]:[base64url] which is normal
    final RegExp validTokenPattern = RegExp(r'^[A-Za-z0-9_:-]+$');
    if (!validTokenPattern.hasMatch(token)) {
      AppLogger.warning('Invalid token format in repository', tag: 'FCM_REPO');
      return null;
    }
    
    // Reject fallback/error tokens
    if (token.startsWith('fcm-fallback-') || token.startsWith('fcm-error-')) {
      AppLogger.warning('Fallback/error token received in repository', tag: 'FCM_REPO');
      return null;
    }
    
    AppLogger.success('Repository token validation passed (length: ${token.length})', tag: 'FCM_REPO');
    return token;
  }
}