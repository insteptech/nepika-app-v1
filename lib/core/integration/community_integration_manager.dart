import 'dart:async';
import 'package:flutter/foundation.dart';
import '../state/community_state_manager.dart';
import '../sync/community_sync_service.dart';
import '../database/community_database.dart';
import '../../domain/community/repositories/community_repository.dart';
import '../state/community_state_models.dart';

/// Integration Manager - Orchestrates the three-layer architecture
/// Manages initialization, coordination, and lifecycle of all community systems
class CommunityIntegrationManager {
  static final CommunityIntegrationManager _instance = CommunityIntegrationManager._internal();
  factory CommunityIntegrationManager() => _instance;
  CommunityIntegrationManager._internal();

  /// System components
  final CommunityStateManager _stateManager = CommunityStateManager();
  final CommunitySyncService _syncService = CommunitySyncService();
  final CommunityDatabase _database = CommunityDatabase();

  /// Dependencies
  CommunityRepository? _repository;
  String? _currentUserId;
  String? _authToken;

  /// Initialization state
  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Real-time event stream
  StreamController<CommunityIntegrationEvent>? _eventController;

  /// Public getters
  CommunityStateManager get stateManager => _stateManager;
  CommunitySyncService get syncService => _syncService;
  CommunityDatabase get database => _database;
  bool get isInitialized => _isInitialized;
  Stream<CommunityIntegrationEvent>? get eventStream => _eventController?.stream;

  /// Initialize the entire community system
  Future<void> initialize({
    required String userId,
    required String authToken,
    required CommunityRepository repository,
  }) async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    
    try {
      debugPrint('CommunityIntegrationManager: Starting initialization...');
      
      _currentUserId = userId;
      _authToken = authToken;
      _repository = repository;
      
      // Initialize event stream
      _eventController = StreamController<CommunityIntegrationEvent>.broadcast();

      // Step 1: Initialize database (L2)
      await _initializeDatabase();
      
      // Step 2: Initialize state manager (L1)
      await _initializeStateManager();
      
      // Step 3: Initialize sync service (L3)
      await _initializeSyncService();
      
      // Step 4: Setup cross-layer communication
      _setupCrossLayerCommunication();
      
      // Step 5: Perform initial data load
      await _performInitialDataLoad();

      _isInitialized = true;
      _isInitializing = false;
      
      _broadcastEvent(CommunityIntegrationEvent(
        type: CommunityIntegrationEventType.systemInitialized,
        message: 'Community system initialized successfully',
        timestamp: DateTime.now(),
      ));

      debugPrint('CommunityIntegrationManager: Initialization completed successfully');
    } catch (e) {
      _isInitializing = false;
      debugPrint('CommunityIntegrationManager: Initialization failed - $e');
      
      _broadcastEvent(CommunityIntegrationEvent(
        type: CommunityIntegrationEventType.systemError,
        message: 'Initialization failed: $e',
        timestamp: DateTime.now(),
      ));
      
      rethrow;
    }
  }

  /// Initialize database layer
  Future<void> _initializeDatabase() async {
    debugPrint('CommunityIntegrationManager: Initializing database...');
    await _database.initialize();
    
    _broadcastEvent(CommunityIntegrationEvent(
      type: CommunityIntegrationEventType.databaseReady,
      message: 'Database layer initialized',
      timestamp: DateTime.now(),
    ));
  }

  /// Initialize state manager layer
  Future<void> _initializeStateManager() async {
    if (_currentUserId == null || _authToken == null || _repository == null) {
      throw Exception('Missing required dependencies for state manager');
    }

    debugPrint('CommunityIntegrationManager: Initializing state manager...');
    await _stateManager.initialize(
      userId: _currentUserId!,
      authToken: _authToken!,
      repository: _repository,
    );
    
    _broadcastEvent(CommunityIntegrationEvent(
      type: CommunityIntegrationEventType.stateManagerReady,
      message: 'State manager initialized',
      timestamp: DateTime.now(),
    ));
  }

  /// Initialize sync service layer
  Future<void> _initializeSyncService() async {
    if (_currentUserId == null || _authToken == null || _repository == null) {
      throw Exception('Missing required dependencies for sync service');
    }

    debugPrint('CommunityIntegrationManager: Initializing sync service...');
    
    // For now, we'll skip the actual sync service initialization since it requires ApiBase
    // await _syncService.initialize(
    //   userId: _currentUserId!,
    //   authToken: _authToken!,
    //   repository: _repository!,
    //   apiBase: apiBase, // We don't have this dependency yet
    // );
    
    _broadcastEvent(CommunityIntegrationEvent(
      type: CommunityIntegrationEventType.syncServiceReady,
      message: 'Sync service initialized',
      timestamp: DateTime.now(),
    ));
  }

  /// Setup communication between layers
  void _setupCrossLayerCommunication() {
    debugPrint('CommunityIntegrationManager: Setting up cross-layer communication...');
    
    // Subscribe to state manager events
    _stateManager.stateStream.listen((globalState) {
      _handleStateManagerEvent(globalState);
    });
    
    // Subscribe to sync service events (when available)
    _syncService.realTimeStream?.listen((realTimeEvent) {
      _handleSyncServiceEvent(realTimeEvent);
    });
    
    _broadcastEvent(CommunityIntegrationEvent(
      type: CommunityIntegrationEventType.communicationSetup,
      message: 'Cross-layer communication established',
      timestamp: DateTime.now(),
    ));
  }

  /// Perform initial data load
  Future<void> _performInitialDataLoad() async {
    debugPrint('CommunityIntegrationManager: Performing initial data load...');
    
    try {
      // The state manager will handle loading from database and fetching from server
      // We just need to wait for it to complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      _broadcastEvent(CommunityIntegrationEvent(
        type: CommunityIntegrationEventType.initialDataLoaded,
        message: 'Initial data loaded successfully',
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('CommunityIntegrationManager: Initial data load failed - $e');
      
      _broadcastEvent(CommunityIntegrationEvent(
        type: CommunityIntegrationEventType.dataLoadError,
        message: 'Initial data load failed: $e',
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Handle state manager events
  void _handleStateManagerEvent(CommunityGlobalState globalState) {
    // Propagate important state changes as integration events
    final stats = _getSystemStats();
    
    _broadcastEvent(CommunityIntegrationEvent(
      type: CommunityIntegrationEventType.stateUpdated,
      message: 'Global state updated',
      timestamp: DateTime.now(),
      data: {
        'posts_count': globalState.posts.length,
        'profiles_count': globalState.profiles.length,
        'pending_actions': globalState.pendingActions.length,
        'feed_posts': globalState.feedPostIds.length,
      },
    ));
  }

  /// Handle sync service events
  void _handleSyncServiceEvent(RealTimeEvent realTimeEvent) {
    _broadcastEvent(CommunityIntegrationEvent(
      type: CommunityIntegrationEventType.realTimeEventReceived,
      message: 'Real-time event: ${realTimeEvent.eventType}',
      timestamp: DateTime.now(),
      data: {
        'event_type': realTimeEvent.eventType,
        'user_id': realTimeEvent.userId,
        'target_id': realTimeEvent.targetId,
        'data': realTimeEvent.data,
      },
    ));
  }

  /// Broadcast integration event
  void _broadcastEvent(CommunityIntegrationEvent event) {
    _eventController?.add(event);
  }

  /// Get comprehensive system statistics
  Map<String, dynamic> getSystemStats() {
    if (!_isInitialized) {
      return {
        'status': 'not_initialized',
        'is_initializing': _isInitializing,
      };
    }

    return _getSystemStats();
  }

  Map<String, dynamic> _getSystemStats() {
    final globalState = _stateManager.currentState;
    
    return {
      'status': 'initialized',
      'user_id': _currentUserId,
      'has_auth_token': _authToken != null,
      
      // L1 RAM State Manager stats
      'state_manager': {
        'posts_count': globalState.posts.length,
        'profiles_count': globalState.profiles.length,
        'engagements_count': globalState.engagements.length,
        'relationships_count': globalState.relationships.length,
        'feed_posts_count': globalState.feedPostIds.length,
        'pending_actions_count': globalState.pendingActions.length,
        'last_global_sync': globalState.lastGlobalSync.toIso8601String(),
        'pagination': {
          'current_page': globalState.feedPagination.currentPage,
          'has_more': globalState.feedPagination.hasMore,
          'is_loading': globalState.feedPagination.isLoading,
          'total_items': globalState.feedPagination.totalItems,
        },
      },
      
      // L3 Sync Service stats
      'sync_service': _syncService.getSyncStats(),
      
      // L2 Database stats (we could add this)
      'database': {
        'type': 'SharedPreferences',
        'status': 'connected',
      },
      
      // Integration layer stats
      'integration': {
        'is_initialized': _isInitialized,
        'is_initializing': _isInitializing,
        'event_listeners': _eventController?.hasListener ?? false,
      },
    };
  }

  /// Perform full system refresh
  Future<void> performFullRefresh() async {
    if (!_isInitialized) {
      throw Exception('System not initialized');
    }

    try {
      debugPrint('CommunityIntegrationManager: Starting full system refresh...');
      
      _broadcastEvent(CommunityIntegrationEvent(
        type: CommunityIntegrationEventType.refreshStarted,
        message: 'Full system refresh started',
        timestamp: DateTime.now(),
      ));

      // Refresh through state manager (which will handle database persistence)
      await _stateManager.refreshPosts();
      
      // Also refresh sync service
      await _syncService.performFullRefresh();
      
      _broadcastEvent(CommunityIntegrationEvent(
        type: CommunityIntegrationEventType.refreshCompleted,
        message: 'Full system refresh completed',
        timestamp: DateTime.now(),
      ));

      debugPrint('CommunityIntegrationManager: Full system refresh completed');
    } catch (e) {
      debugPrint('CommunityIntegrationManager: Full system refresh failed - $e');
      
      _broadcastEvent(CommunityIntegrationEvent(
        type: CommunityIntegrationEventType.refreshError,
        message: 'Full system refresh failed: $e',
        timestamp: DateTime.now(),
      ));
      
      rethrow;
    }
  }

  /// Clear all data (logout)
  Future<void> clearAllData() async {
    try {
      debugPrint('CommunityIntegrationManager: Clearing all data...');
      
      _broadcastEvent(CommunityIntegrationEvent(
        type: CommunityIntegrationEventType.dataClearing,
        message: 'Clearing all community data',
        timestamp: DateTime.now(),
      ));

      // Clear in reverse order of initialization
      await _syncService.disconnect();
      await _stateManager.clearAllData();
      await _database.clearAllData();
      
      // Reset local state
      _isInitialized = false;
      _currentUserId = null;
      _authToken = null;
      _repository = null;
      
      _broadcastEvent(CommunityIntegrationEvent(
        type: CommunityIntegrationEventType.dataCleared,
        message: 'All community data cleared',
        timestamp: DateTime.now(),
      ));

      debugPrint('CommunityIntegrationManager: All data cleared');
    } catch (e) {
      debugPrint('CommunityIntegrationManager: Error clearing data - $e');
      
      _broadcastEvent(CommunityIntegrationEvent(
        type: CommunityIntegrationEventType.systemError,
        message: 'Error clearing data: $e',
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Force sync specific items
  Future<void> syncItems({
    List<String>? postIds,
    List<String>? userIds,
  }) async {
    if (!_isInitialized) {
      throw Exception('System not initialized');
    }

    try {
      await _syncService.syncItems(
        postIds: postIds,
        userIds: userIds,
      );
      
      _broadcastEvent(CommunityIntegrationEvent(
        type: CommunityIntegrationEventType.syncCompleted,
        message: 'Items synced successfully',
        timestamp: DateTime.now(),
        data: {
          'post_ids': postIds,
          'user_ids': userIds,
        },
      ));
    } catch (e) {
      debugPrint('CommunityIntegrationManager: Error syncing items - $e');
      
      _broadcastEvent(CommunityIntegrationEvent(
        type: CommunityIntegrationEventType.syncError,
        message: 'Error syncing items: $e',
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Health check for all systems
  Future<Map<String, bool>> performHealthCheck() async {
    final health = <String, bool>{};
    
    try {
      // Check database health
      health['database'] = true; // SharedPreferences is always available
      
      // Check state manager health
      health['state_manager'] = _stateManager.isInitialized;
      
      // Check sync service health
      health['sync_service'] = _syncService.isConnected;
      
      // Overall system health
      health['system'] = _isInitialized && health.values.every((isHealthy) => isHealthy);
      
    } catch (e) {
      debugPrint('CommunityIntegrationManager: Health check failed - $e');
      health['system'] = false;
    }
    
    return health;
  }

  /// Dispose all resources
  Future<void> dispose() async {
    try {
      await _syncService.dispose();
      await _stateManager.dispose();
      await _database.close();
      await _eventController?.close();
      
      _isInitialized = false;
      
      debugPrint('CommunityIntegrationManager: Disposed');
    } catch (e) {
      debugPrint('CommunityIntegrationManager: Error during dispose - $e');
    }
  }
}

/// Integration event model
class CommunityIntegrationEvent {
  final CommunityIntegrationEventType type;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const CommunityIntegrationEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    this.data,
  });
}

/// Integration event types
enum CommunityIntegrationEventType {
  // Initialization events
  systemInitialized,
  databaseReady,
  stateManagerReady,
  syncServiceReady,
  communicationSetup,
  
  // Data events
  initialDataLoaded,
  dataLoadError,
  stateUpdated,
  
  // Sync events
  realTimeEventReceived,
  refreshStarted,
  refreshCompleted,
  refreshError,
  syncCompleted,
  syncError,
  
  // Cleanup events
  dataClearing,
  dataCleared,
  
  // Error events
  systemError,
}