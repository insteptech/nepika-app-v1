import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/camera_scan_session_model.dart';
import '../models/face_scan_result_model.dart';
import 'face_scan_local_data_source.dart';

/// Implementation of face scan local data source using SharedPreferences.
/// 
/// This implementation handles local storage of sessions, scan results,
/// and user preferences using SharedPreferences for persistence.
/// For production apps, consider using SQLite/Hive for better performance with large datasets.
@injectable
class FaceScanLocalDataSourceImpl implements FaceScanLocalDataSource {
  final SharedPreferences _prefs;

  // Storage keys
  static const String _sessionPrefix = 'face_scan_session_';
  static const String _scanResultPrefix = 'face_scan_result_';
  static const String _userPrefsPrefix = 'face_scan_user_prefs_';
  static const String _appConfigKey = 'face_scan_app_config';
  static const String _activeSessionsKey = 'face_scan_active_sessions';
  static const String _userResultsPrefix = 'face_scan_user_results_';

  FaceScanLocalDataSourceImpl(this._prefs);

  // ===== Session Management =====

  @override
  Future<void> saveSession(CameraScanSessionModel session) async {
    try {
      final sessionKey = _sessionPrefix + session.sessionId;
      final sessionJson = json.encode(session.toJson());
      
      await _prefs.setString(sessionKey, sessionJson);
      
      // Update active sessions list
      await _addToActiveSessionsList(session.userId, session.sessionId);
      
      debugPrint('💾 Saved face scan session: ${session.sessionId}');
    } catch (e) {
      throw Exception('Failed to save session: $e');
    }
  }

  @override
  Future<CameraScanSessionModel?> getSession(String sessionId) async {
    try {
      final sessionKey = _sessionPrefix + sessionId;
      final sessionJson = _prefs.getString(sessionKey);
      
      if (sessionJson == null) {
        return null;
      }
      
      final sessionData = json.decode(sessionJson) as Map<String, dynamic>;
      return CameraScanSessionModel.fromJson(sessionData);
    } catch (e) {
      debugPrint('❌ Failed to get session $sessionId: $e');
      return null;
    }
  }

  @override
  Future<void> updateSession(CameraScanSessionModel session) async {
    try {
      // Update is the same as save for SharedPreferences
      await saveSession(session);
    } catch (e) {
      throw Exception('Failed to update session: $e');
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    try {
      final sessionKey = _sessionPrefix + sessionId;
      await _prefs.remove(sessionKey);
      
      // Remove from active sessions list
      await _removeFromActiveSessionsList(sessionId);
      
      debugPrint('🗑️ Deleted face scan session: $sessionId');
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  @override
  Future<List<CameraScanSessionModel>> getActiveSessions(String userId) async {
    try {
      final activeSessionsKey = _activeSessionsKey + '_$userId';
      final sessionIds = _prefs.getStringList(activeSessionsKey) ?? [];
      
      final sessions = <CameraScanSessionModel>[];
      
      for (final sessionId in sessionIds) {
        final session = await getSession(sessionId);
        if (session != null && session.userId == userId) {
          sessions.add(session);
        }
      }
      
      return sessions;
    } catch (e) {
      debugPrint('❌ Failed to get active sessions for user $userId: $e');
      return [];
    }
  }

  @override
  Future<int> cleanupExpiredSessions({Duration? olderThan}) async {
    try {
      final cutoffTime = DateTime.now().subtract(olderThan ?? const Duration(hours: 24));
      int cleanedCount = 0;
      
      // Get all session keys
      final allKeys = _prefs.getKeys().where((key) => key.startsWith(_sessionPrefix));
      
      for (final sessionKey in allKeys) {
        final sessionJson = _prefs.getString(sessionKey);
        if (sessionJson != null) {
          try {
            final sessionData = json.decode(sessionJson) as Map<String, dynamic>;
            final createdAt = DateTime.parse(sessionData['created_at'] as String);
            
            if (createdAt.isBefore(cutoffTime)) {
              await _prefs.remove(sessionKey);
              cleanedCount++;
            }
          } catch (e) {
            // Invalid session data, remove it
            await _prefs.remove(sessionKey);
            cleanedCount++;
          }
        }
      }
      
      // Clean up active sessions lists
      await _cleanupActiveSessionsLists();
      
      debugPrint('🧹 Cleaned up $cleanedCount expired face scan sessions');
      return cleanedCount;
    } catch (e) {
      throw Exception('Failed to cleanup expired sessions: $e');
    }
  }

  // ===== Scan Results Management =====

  @override
  Future<void> saveScanResult(FaceScanResultModel scanResult) async {
    try {
      final resultKey = _scanResultPrefix + scanResult.scanId;
      final resultJson = json.encode(scanResult.toJson());
      
      await _prefs.setString(resultKey, resultJson);
      
      // Update user results list
      await _addToUserResultsList(scanResult.userId, scanResult.scanId);
      
      debugPrint('💾 Saved face scan result: ${scanResult.scanId}');
    } catch (e) {
      throw Exception('Failed to save scan result: $e');
    }
  }

  @override
  Future<FaceScanResultModel?> getScanResult(String scanId) async {
    try {
      final resultKey = _scanResultPrefix + scanId;
      final resultJson = _prefs.getString(resultKey);
      
      if (resultJson == null) {
        return null;
      }
      
      final resultData = json.decode(resultJson) as Map<String, dynamic>;
      return FaceScanResultModel.fromJson(
        resultData,
        userId: resultData['user_id'] as String,
        scanId: resultData['scan_id'] as String,
        processingTimeMs: resultData['processing_time_ms'] as int,
      );
    } catch (e) {
      debugPrint('❌ Failed to get scan result $scanId: $e');
      return null;
    }
  }

  @override
  Future<List<FaceScanResultModel>> getScanResults({
    required String userId,
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userResultsKey = _userResultsPrefix + userId;
      final resultIds = _prefs.getStringList(userResultsKey) ?? [];
      
      final results = <FaceScanResultModel>[];
      
      for (final resultId in resultIds) {
        final result = await getScanResult(resultId);
        if (result != null && result.userId == userId) {
          // Apply date filters
          if (startDate != null && result.timestamp.isBefore(startDate)) continue;
          if (endDate != null && result.timestamp.isAfter(endDate)) continue;
          
          results.add(result);
        }
      }
      
      // Sort by timestamp (newest first)
      results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Apply offset and limit
      final offsetValue = offset ?? 0;
      final limitValue = limit;
      
      if (offsetValue > 0) {
        if (offsetValue >= results.length) return [];
        final remainingResults = results.sublist(offsetValue);
        return limitValue != null 
            ? remainingResults.take(limitValue).toList()
            : remainingResults;
      }
      
      return limitValue != null 
          ? results.take(limitValue).toList()
          : results;
    } catch (e) {
      debugPrint('❌ Failed to get scan results for user $userId: $e');
      return [];
    }
  }

  @override
  Future<FaceScanResultModel?> getLatestScanResult(String userId) async {
    try {
      final results = await getScanResults(userId: userId, limit: 1);
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      debugPrint('❌ Failed to get latest scan result for user $userId: $e');
      return null;
    }
  }

  @override
  Future<bool> deleteScanResults({String? scanId, required String userId}) async {
    try {
      if (scanId != null) {
        // Delete specific scan result
        final resultKey = _scanResultPrefix + scanId;
        await _prefs.remove(resultKey);
        await _removeFromUserResultsList(userId, scanId);
        
        debugPrint('🗑️ Deleted face scan result: $scanId');
      } else {
        // Delete all scan results for user
        final userResultsKey = _userResultsPrefix + userId;
        final resultIds = _prefs.getStringList(userResultsKey) ?? [];
        
        for (final resultId in resultIds) {
          final resultKey = _scanResultPrefix + resultId;
          await _prefs.remove(resultKey);
        }
        
        await _prefs.remove(userResultsKey);
        
        debugPrint('🗑️ Deleted all face scan results for user: $userId');
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete scan results: $e');
      return false;
    }
  }

  @override
  Future<int> getScanResultsCount(String userId) async {
    try {
      final userResultsKey = _userResultsPrefix + userId;
      final resultIds = _prefs.getStringList(userResultsKey) ?? [];
      return resultIds.length;
    } catch (e) {
      debugPrint('❌ Failed to get scan results count for user $userId: $e');
      return 0;
    }
  }

  // ===== Cache Management =====

  @override
  Future<bool> clearUserCache(String userId) async {
    try {
      // Clear user sessions
      final activeSessions = await getActiveSessions(userId);
      for (final session in activeSessions) {
        await deleteSession(session.sessionId);
      }
      
      // Clear user scan results
      await deleteScanResults(userId: userId);
      
      // Clear user preferences
      final userPrefsKey = _userPrefsPrefix + userId;
      await _prefs.remove(userPrefsKey);
      
      debugPrint('🧹 Cleared all cache for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to clear cache for user $userId: $e');
      return false;
    }
  }

  @override
  Future<int> getCacheSize() async {
    try {
      int totalSize = 0;
      
      // Get all face scan related keys
      final faceScaleKeys = _prefs.getKeys().where((key) => 
          key.startsWith(_sessionPrefix) ||
          key.startsWith(_scanResultPrefix) ||
          key.startsWith(_userPrefsPrefix) ||
          key.startsWith(_userResultsPrefix) ||
          key == _appConfigKey ||
          key.startsWith(_activeSessionsKey)
      );
      
      for (final key in faceScaleKeys) {
        final value = _prefs.getString(key);
        if (value != null) {
          totalSize += value.length * 2; // Approximate UTF-16 encoding size
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('❌ Failed to calculate cache size: $e');
      return 0;
    }
  }

  @override
  Future<bool> optimizeStorage() async {
    try {
      // SharedPreferences doesn't need explicit optimization
      // But we can clean up expired data
      await cleanupExpiredSessions();
      
      debugPrint('✨ Storage optimization completed');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to optimize storage: $e');
      return false;
    }
  }

  // ===== Configuration =====

  @override
  Future<void> saveUserPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      final userPrefsKey = _userPrefsPrefix + userId;
      final prefsJson = json.encode(preferences);
      await _prefs.setString(userPrefsKey, prefsJson);
      
      debugPrint('💾 Saved user preferences for: $userId');
    } catch (e) {
      throw Exception('Failed to save user preferences: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    try {
      final userPrefsKey = _userPrefsPrefix + userId;
      final prefsJson = _prefs.getString(userPrefsKey);
      
      if (prefsJson == null) {
        return {};
      }
      
      return json.decode(prefsJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Failed to get user preferences for $userId: $e');
      return {};
    }
  }

  @override
  Future<void> saveAppConfiguration(Map<String, dynamic> config) async {
    try {
      final configJson = json.encode(config);
      await _prefs.setString(_appConfigKey, configJson);
      
      debugPrint('💾 Saved app configuration');
    } catch (e) {
      throw Exception('Failed to save app configuration: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getAppConfiguration() async {
    try {
      final configJson = _prefs.getString(_appConfigKey);
      
      if (configJson == null) {
        return {};
      }
      
      return json.decode(configJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Failed to get app configuration: $e');
      return {};
    }
  }

  // ===== Private Helper Methods =====

  Future<void> _addToActiveSessionsList(String userId, String sessionId) async {
    try {
      final activeSessionsKey = _activeSessionsKey + '_$userId';
      final sessionIds = _prefs.getStringList(activeSessionsKey) ?? [];
      
      if (!sessionIds.contains(sessionId)) {
        sessionIds.add(sessionId);
        await _prefs.setStringList(activeSessionsKey, sessionIds);
      }
    } catch (e) {
      debugPrint('❌ Failed to add to active sessions list: $e');
    }
  }

  Future<void> _removeFromActiveSessionsList(String sessionId) async {
    try {
      // Find and remove from all user active session lists
      final allKeys = _prefs.getKeys().where((key) => key.startsWith(_activeSessionsKey));
      
      for (final key in allKeys) {
        final sessionIds = _prefs.getStringList(key) ?? [];
        if (sessionIds.contains(sessionId)) {
          sessionIds.remove(sessionId);
          await _prefs.setStringList(key, sessionIds);
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to remove from active sessions list: $e');
    }
  }

  Future<void> _cleanupActiveSessionsLists() async {
    try {
      final allKeys = _prefs.getKeys().where((key) => key.startsWith(_activeSessionsKey));
      
      for (final key in allKeys) {
        final sessionIds = _prefs.getStringList(key) ?? [];
        final validSessionIds = <String>[];
        
        for (final sessionId in sessionIds) {
          final session = await getSession(sessionId);
          if (session != null) {
            validSessionIds.add(sessionId);
          }
        }
        
        await _prefs.setStringList(key, validSessionIds);
      }
    } catch (e) {
      debugPrint('❌ Failed to cleanup active sessions lists: $e');
    }
  }

  Future<void> _addToUserResultsList(String userId, String resultId) async {
    try {
      final userResultsKey = _userResultsPrefix + userId;
      final resultIds = _prefs.getStringList(userResultsKey) ?? [];
      
      if (!resultIds.contains(resultId)) {
        resultIds.add(resultId);
        await _prefs.setStringList(userResultsKey, resultIds);
      }
    } catch (e) {
      debugPrint('❌ Failed to add to user results list: $e');
    }
  }

  Future<void> _removeFromUserResultsList(String userId, String resultId) async {
    try {
      final userResultsKey = _userResultsPrefix + userId;
      final resultIds = _prefs.getStringList(userResultsKey) ?? [];
      
      if (resultIds.contains(resultId)) {
        resultIds.remove(resultId);
        await _prefs.setStringList(userResultsKey, resultIds);
      }
    } catch (e) {
      debugPrint('❌ Failed to remove from user results list: $e');
    }
  }
}