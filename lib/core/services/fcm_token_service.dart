/// ⚠️ DEPRECATED: This file is deprecated and will be removed in future versions.
/// Use UnifiedFcmService.instance instead from:
/// lib/core/services/unified_fcm_service.dart
/// 
/// Migration Guide:
/// - Replace FcmTokenService with UnifiedFcmService.instance
/// - All token management is now handled by UnifiedFcmService
/// - No need for separate service injection
library;

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../domain/fcm/usecases/save_fcm_token_usecase.dart';
import '../../domain/fcm/entities/fcm_token_entity.dart';

class FcmTokenService {
  final SaveFcmTokenUseCase saveFcmTokenUseCase;
  StreamSubscription? _tokenRefreshSubscription;
  Timer? _retryTimer;
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 30);
  
  FcmTokenService({
    required this.saveFcmTokenUseCase,
  });

  /// Initialize FCM token management
  Future<void> initialize() async {
    try {
      // Save initial token
      await _saveTokenWithRetry();
      
      // Listen for token refresh
      _listenForTokenRefresh();
      
      print('✅ FCM Token Service initialized successfully');
    } catch (e) {
      print('❌ FCM Token Service initialization failed: $e');
    }
  }

  /// Listen for FCM token refresh events
  void _listenForTokenRefresh() {
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) {
        print('🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...');
        _saveTokenWithRetry();
      },
      onError: (error) {
        print('❌ FCM Token refresh error: $error');
      },
    );
  }

  /// Save FCM token with retry logic
  Future<FcmTokenEntity?> _saveTokenWithRetry({int attempt = 1}) async {
    try {
      final result = await saveFcmTokenUseCase.call();
      
      // Cancel any pending retry timer
      _retryTimer?.cancel();
      
      print('✅ FCM Token saved successfully (attempt $attempt)');
      return result;
      
    } catch (e) {
      print('❌ FCM Token save failed (attempt $attempt): $e');
      
      if (attempt < maxRetries) {
        print('⏳ Retrying FCM token save in ${retryDelay.inSeconds} seconds...');
        
        _retryTimer = Timer(retryDelay, () {
          _saveTokenWithRetry(attempt: attempt + 1);
        });
      } else {
        print('🚨 FCM Token save failed after $maxRetries attempts');
      }
      
      return null;
    }
  }

  /// Force save FCM token (manual trigger)
  Future<FcmTokenEntity?> forceSaveToken() async {
    try {
      print('🔄 Force saving FCM token...');
      final result = await saveFcmTokenUseCase.forceSave();
      print('✅ FCM Token force saved successfully');
      return result;
    } catch (e) {
      print('❌ FCM Token force save failed: $e');
      return null;
    }
  }

  /// Check if token needs update and save if necessary
  Future<bool> checkAndUpdateToken() async {
    try {
      final needsUpdate = await saveFcmTokenUseCase.needsUpdate();
      
      if (needsUpdate) {
        print('🔄 FCM Token needs update, saving...');
        final result = await _saveTokenWithRetry();
        return result != null;
      } else {
        print('✅ FCM Token is up to date');
        return true;
      }
    } catch (e) {
      print('❌ FCM Token check failed: $e');
      return false;
    }
  }

  /// Clear FCM token (useful for logout)
  Future<void> clearToken() async {
    try {
      await saveFcmTokenUseCase.clearToken();
      print('✅ FCM Token cleared successfully');
    } catch (e) {
      print('❌ FCM Token clear failed: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _retryTimer?.cancel();
    print('🧹 FCM Token Service disposed');
  }

  /// Get service status for debugging
  Map<String, dynamic> getStatus() {
    return {
      'isListening': _tokenRefreshSubscription != null,
      'hasRetryTimer': _retryTimer?.isActive ?? false,
      'service': 'FcmTokenService',
      'initialized': true,
    };
  }
}