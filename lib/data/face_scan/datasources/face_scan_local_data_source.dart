import '../models/face_scan_result_model.dart';
import '../models/camera_scan_session_model.dart';

/// Abstract interface for local face scanning data operations.
/// 
/// This interface defines the contract for local storage operations including
/// session persistence, scan result caching, and user data management.
/// Implementations should handle local database/storage operations with proper
/// error handling and data consistency.
abstract class FaceScanLocalDataSource {
  // ===== Session Management =====

  /// Saves a camera scanning session to local storage.
  /// 
  /// Parameters:
  /// - [session]: Session data to save
  /// 
  /// Throws:
  /// - [Exception]: For storage operation errors
  Future<void> saveSession(CameraScanSessionModel session);

  /// Retrieves a camera scanning session from local storage.
  /// 
  /// Parameters:
  /// - [sessionId]: Unique identifier for the session
  /// 
  /// Returns:
  /// - [CameraScanSessionModel]: Session data or null if not found
  /// 
  /// Throws:
  /// - [Exception]: For storage operation errors
  Future<CameraScanSessionModel?> getSession(String sessionId);

  /// Updates an existing session in local storage.
  /// 
  /// Parameters:
  /// - [session]: Updated session data
  /// 
  /// Throws:
  /// - [Exception]: For storage operation errors
  Future<void> updateSession(CameraScanSessionModel session);

  /// Deletes a session from local storage.
  /// 
  /// Parameters:
  /// - [sessionId]: Session to delete
  /// 
  /// Throws:
  /// - [Exception]: For storage operation errors
  Future<void> deleteSession(String sessionId);

  /// Gets all active sessions for a user.
  /// 
  /// Parameters:
  /// - [userId]: User ID to get sessions for
  /// 
  /// Returns:
  /// - [List<CameraScanSessionModel>]: List of active sessions
  /// 
  /// Throws:
  /// - [Exception]: For storage operation errors
  Future<List<CameraScanSessionModel>> getActiveSessions(String userId);

  /// Clears all expired or completed sessions.
  /// 
  /// Parameters:
  /// - [olderThan]: Delete sessions older than this duration (default: 24 hours)
  /// 
  /// Returns:
  /// - [int]: Number of sessions cleaned up
  /// 
  /// Throws:
  /// - [Exception]: For storage operation errors
  Future<int> cleanupExpiredSessions({Duration? olderThan});

  // ===== Scan Results Management =====

  /// Saves a face scan result to local storage.
  /// 
  /// Parameters:
  /// - [scanResult]: Complete scan result to save
  /// 
  /// Throws:
  /// - [Exception]: For storage operation errors
  Future<void> saveScanResult(FaceScanResultModel scanResult);

  /// Retrieves a specific scan result from local storage.
  /// 
  /// Parameters:
  /// - [scanId]: Unique identifier for the scan result
  /// 
  /// Returns:
  /// - [FaceScanResultModel]: Scan result or null if not found
  /// 
  /// Throws:
  /// - [Exception]: For storage operation errors
  Future<FaceScanResultModel?> getScanResult(String scanId);

  /// Gets scan results for a user with optional filtering.
  /// 
  /// Parameters:
  /// - [userId]: User ID to get results for
  /// - [limit]: Maximum number of results to return
  /// - [offset]: Number of results to skip (for pagination)
  /// - [startDate]: Filter results from this date
  /// - [endDate]: Filter results until this date
  /// 
  /// Returns:
  /// - [List<FaceScanResultModel>]: List of scan results
  /// 
  /// Throws:
  /// - [Exception]: For storage operation errors
  Future<List<FaceScanResultModel>> getScanResults({
    required String userId,
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Gets the most recent scan result for a user.
  /// 
  /// Parameters:
  /// - [userId]: User ID to get latest result for
  /// 
  /// Returns:
  /// - [FaceScanResultModel]: Latest scan result or null if none exists
  /// 
  /// Throws:
  /// - [Exception]: For storage operation errors
  Future<FaceScanResultModel?> getLatestScanResult(String userId);

  /// Deletes scan results.
  /// 
  /// Parameters:
  /// - [scanId]: Specific scan ID to delete, or null to delete all for user
  /// - [userId]: User ID for authorization
  /// 
  /// Returns:
  /// - [bool]: True if deletion was successful
  /// 
  /// Throws:
  /// - [Exception]: For storage operation errors
  Future<bool> deleteScanResults({String? scanId, required String userId});

  /// Gets the total count of scan results for a user.
  /// 
  /// Parameters:
  /// - [userId]: User ID to count results for
  /// 
  /// Returns:
  /// - [int]: Total number of scan results
  /// 
  /// Throws:
  /// - [Exception]: For storage operation errors
  Future<int> getScanResultsCount(String userId);

  // ===== Cache Management =====

  /// Clears all cached data for a user.
  /// 
  /// Parameters:
  /// - [userId]: User ID to clear cache for
  /// 
  /// Returns:
  /// - [bool]: True if cache was cleared successfully
  /// 
  /// Throws:
  /// - [Exception]: For storage operation errors
  Future<bool> clearUserCache(String userId);

  /// Gets the total size of cached data.
  /// 
  /// Returns:
  /// - [int]: Size in bytes of all cached data
  /// 
  /// Throws:
  /// - [Exception]: For storage operation errors
  Future<int> getCacheSize();

  /// Optimizes the local storage (compact, reindex, etc.).
  /// 
  /// Returns:
  /// - [bool]: True if optimization was successful
  /// 
  /// Throws:
  /// - [Exception]: For storage operation errors
  Future<bool> optimizeStorage();

  // ===== Configuration =====

  /// Saves user preferences for face scanning.
  /// 
  /// Parameters:
  /// - [userId]: User ID
  /// - [preferences]: Preference settings as key-value pairs
  /// 
  /// Throws:
  /// - [Exception]: For storage operation errors
  Future<void> saveUserPreferences(String userId, Map<String, dynamic> preferences);

  /// Gets user preferences for face scanning.
  /// 
  /// Parameters:
  /// - [userId]: User ID to get preferences for
  /// 
  /// Returns:
  /// - [Map<String, dynamic>]: User preferences
  /// 
  /// Throws:
  /// - [Exception]: For storage operation errors
  Future<Map<String, dynamic>> getUserPreferences(String userId);

  /// Saves app configuration for face scanning features.
  /// 
  /// Parameters:
  /// - [config]: Configuration settings
  /// 
  /// Throws:
  /// - [Exception]: For storage operation errors
  Future<void> saveAppConfiguration(Map<String, dynamic> config);

  /// Gets app configuration for face scanning features.
  /// 
  /// Returns:
  /// - [Map<String, dynamic>]: App configuration
  /// 
  /// Throws:
  /// - [Exception]: For storage operation errors
  Future<Map<String, dynamic>> getAppConfiguration();
}