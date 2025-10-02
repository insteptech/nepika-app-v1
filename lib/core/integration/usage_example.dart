import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'community_integration_manager.dart';
import '../state/community_state_manager.dart';
import '../sync/community_sync_service.dart';
import '../../features/community/bloc/hybrid_posts_bloc.dart';
import '../../domain/community/repositories/community_repository.dart';

/// Usage Example - How to integrate the hybrid community state architecture
/// This demonstrates the proper initialization and usage patterns

class CommunityApp extends StatefulWidget {
  final CommunityRepository repository;
  final String userId;
  final String authToken;

  const CommunityApp({
    super.key,
    required this.repository,
    required this.userId,
    required this.authToken,
  });

  @override
  State<CommunityApp> createState() => _CommunityAppState();
}

class _CommunityAppState extends State<CommunityApp> {
  final CommunityIntegrationManager _integrationManager = CommunityIntegrationManager();
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    _initializeCommunitySystem();
  }

  /// Initialize the entire community system
  Future<void> _initializeCommunitySystem() async {
    if (_isInitializing) return;

    setState(() {
      _isInitializing = true;
      _initializationError = null;
    });

    try {
      // Initialize the integration manager which orchestrates all layers
      await _integrationManager.initialize(
        userId: widget.userId,
        authToken: widget.authToken,
        repository: widget.repository,
      );

      // Subscribe to integration events
      _integrationManager.eventStream?.listen((event) {
        _handleIntegrationEvent(event);
      });

      setState(() {
        _isInitialized = true;
        _isInitializing = false;
      });

      debugPrint('CommunityApp: Community system initialized successfully');
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _initializationError = e.toString();
      });

      debugPrint('CommunityApp: Community system initialization failed - $e');
    }
  }

  /// Handle integration events
  void _handleIntegrationEvent(CommunityIntegrationEvent event) {
    debugPrint('CommunityApp: Integration event - ${event.type}: ${event.message}');

    switch (event.type) {
      case CommunityIntegrationEventType.systemInitialized:
        // System is ready
        break;
      case CommunityIntegrationEventType.realTimeEventReceived:
        // Real-time update received
        break;
      case CommunityIntegrationEventType.systemError:
        // Handle system errors
        _showErrorSnackBar(event.message);
        break;
      default:
        // Handle other events as needed
        break;
    }
  }

  /// Show error snack bar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing community system...'),
            ],
          ),
        ),
      );
    }

    if (_initializationError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize community system',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _initializationError!,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeCommunitySystem,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Text('Community system not ready'),
        ),
      );
    }

    // Provide the components to the widget tree
    return MultiBlocProvider(
      providers: [
        // Provide the hybrid posts BLoC
        BlocProvider<HybridPostsBloc>(
          create: (context) => HybridPostsBloc(
            stateManager: _integrationManager.stateManager,
            syncService: _integrationManager.syncService,
          )..add(InitializePosts(
            userId: widget.userId,
            token: widget.authToken,
          )),
        ),
      ],
      child: MaterialApp(
        home: CommunityHomeScreen(
          integrationManager: _integrationManager,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _integrationManager.dispose();
    super.dispose();
  }
}

/// Example community home screen using the hybrid architecture
class CommunityHomeScreen extends StatefulWidget {
  final CommunityIntegrationManager integrationManager;

  const CommunityHomeScreen({
    super.key,
    required this.integrationManager,
  });

  @override
  State<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          // System stats button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showSystemStats(),
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _performFullRefresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status indicator
          _buildConnectionStatus(),
          
          // Posts feed using the hybrid BLoC
          Expanded(
            child: BlocBuilder<HybridPostsBloc, dynamic>(
              builder: (context, state) {
                return _buildPostsList(state);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createPost(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build connection status widget
  Widget _buildConnectionStatus() {
    return StreamBuilder<CommunityIntegrationEvent>(
      stream: widget.integrationManager.eventStream,
      builder: (context, snapshot) {
        final isConnected = widget.integrationManager.syncService.isConnected;
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          color: isConnected ? Colors.green[100] : Colors.orange[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isConnected ? Icons.cloud_done : Icons.cloud_off,
                size: 16,
                color: isConnected ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                isConnected ? 'Connected' : 'Offline',
                style: TextStyle(
                  color: isConnected ? Colors.green[800] : Colors.orange[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build posts list
  Widget _buildPostsList(dynamic state) {
    // This would be properly typed in a real implementation
    return ListView.builder(
      itemCount: 10, // Placeholder
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text('Post ${index + 1}'),
            subtitle: const Text('This is a sample post content...'),
            trailing: IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: () => _likePost('post_$index'),
            ),
          ),
        );
      },
    );
  }

  /// Like a post using the state manager
  void _likePost(String postId) {
    widget.integrationManager.stateManager.likePost(postId);
  }

  /// Create a new post
  void _createPost(BuildContext context) {
    // Show create post dialog/screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Post'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'What\'s on your mind?',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Create post through BLoC
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  /// Show system statistics
  void _showSystemStats() {
    final stats = widget.integrationManager.getSystemStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Statistics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${stats['status']}'),
              const SizedBox(height: 8),
              if (stats['state_manager'] != null) ...[
                const Text('State Manager:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('  Posts: ${stats['state_manager']['posts_count']}'),
                Text('  Profiles: ${stats['state_manager']['profiles_count']}'),
                Text('  Feed Posts: ${stats['state_manager']['feed_posts_count']}'),
                Text('  Pending Actions: ${stats['state_manager']['pending_actions_count']}'),
                const SizedBox(height: 8),
              ],
              if (stats['sync_service'] != null) ...[
                const Text('Sync Service:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('  Connected: ${stats['sync_service']['is_connected']}'),
                Text('  Syncing: ${stats['sync_service']['is_syncing']}'),
                const SizedBox(height: 8),
              ],
              const Text('Database: SharedPreferences'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Perform full system refresh
  Future<void> _performFullRefresh() async {
    try {
      await widget.integrationManager.performFullRefresh();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Community data refreshed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refresh failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Example of how to use the system in a different part of the app
class UserProfileScreen extends StatelessWidget {
  final String userId;
  final CommunityIntegrationManager integrationManager;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.integrationManager,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: StreamBuilder<CommunityGlobalState>(
        stream: integrationManager.stateManager.stateStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final globalState = snapshot.data!;
          final userProfile = globalState.profiles[userId]?.profile;

          if (userProfile == null) {
            return const Center(
              child: Text('User profile not found'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: userProfile.profileImageUrl != null
                          ? NetworkImage(userProfile.profileImageUrl!)
                          : null,
                      child: userProfile.profileImageUrl == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userProfile.username,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (userProfile.bio != null && userProfile.bio!.isNotEmpty)
                            Text(userProfile.bio!),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('${userProfile.followersCount} followers'),
                              const SizedBox(width: 16),
                              Text('${userProfile.postsCount} posts'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Follow button (if not current user)
                if (!userProfile.isSelf)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _toggleFollow(userProfile),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: userProfile.isFollowing ? Colors.grey : null,
                      ),
                      child: Text(userProfile.isFollowing ? 'Following' : 'Follow'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _toggleFollow(profile) {
    // TODO: Implement follow/unfollow through state manager
    debugPrint('Toggle follow for user: ${profile.userId}');
  }
}

/// Key Benefits Demonstrated:

/// 1. **Instant UI Updates**: All user actions (like, follow, etc.) update the UI immediately
///    through optimistic updates in the RAM state manager.

/// 2. **Offline Support**: Actions are queued when offline and processed when connectivity returns.

/// 3. **Real-time Sync**: Changes from other users appear in real-time through the sync service.

/// 4. **Persistent Storage**: All data is automatically cached in the database layer for instant
///    app startup without network calls.

/// 5. **Conflict Resolution**: The system handles conflicts between local and server data gracefully.

/// 6. **Unified State**: All BLoCs subscribe to the same state manager, ensuring consistency
///    across the entire app.

/// 7. **Performance Optimization**: Multi-level caching ensures optimal performance with
///    minimal server requests.

/// 8. **Scalability**: The architecture scales from hundreds to millions of posts with
///    efficient pagination and delta sync.

/// Usage Pattern:
/// 1. Initialize CommunityIntegrationManager once at app startup
/// 2. Pass state manager and sync service to all relevant BLoCs  
/// 3. All user actions go through the state manager for optimistic updates
/// 4. BLoCs listen to state manager streams for reactive UI updates
/// 5. Background sync keeps everything in sync with the server