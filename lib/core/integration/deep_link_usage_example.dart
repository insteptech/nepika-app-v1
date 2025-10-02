import 'package:flutter/material.dart';
import 'deep_link_integration_manager.dart';
import '../routing/app_router.dart';

/// Deep Link Usage Example - Demonstrates how to use the deep linking system
/// This file shows practical examples of integrating deep linking into the NEPIKA app
class DeepLinkUsageExample {
  static final DeepLinkIntegrationManager _deepLinkManager = DeepLinkIntegrationManager();

  /// Example 1: Initialize deep linking in main.dart
  static Future<void> initializeInMainApp({String? userId}) async {
    try {
      // Initialize the entire deep linking system
      await _deepLinkManager.initialize(
        navigatorKey: AppRouter.router.routerDelegate.navigatorKey,
        userId: userId,
      );
      
      print('✅ Deep linking system initialized successfully');
      
      // Perform health check
      final health = await _deepLinkManager.performHealthCheck();
      print('🏥 System health: ${health['system'] ? 'Healthy' : 'Issues detected'}');
      
    } catch (e) {
      print('❌ Failed to initialize deep linking: $e');
    }
  }

  /// Example 2: Handle incoming deep link from app launch
  static Future<void> handleAppLaunchDeepLink(String url) async {
    try {
      print('🔗 Processing deep link from app launch: $url');
      
      // Track the app launch
      await _deepLinkManager.trackAppLaunchFromDeepLink(url);
      
      // The deep link will be processed automatically by the system
      print('✅ Deep link processed successfully');
      
    } catch (e) {
      print('❌ Failed to handle app launch deep link: $e');
    }
  }

  /// Example 3: Share a post with analytics tracking
  static Future<void> sharePostExample(String postId) async {
    try {
      print('📤 Sharing post: $postId');
      
      // Share the post using the integration manager
      await _deepLinkManager.sharePost(postId);
      
      print('✅ Post shared successfully with analytics tracking');
      
    } catch (e) {
      print('❌ Failed to share post: $e');
    }
  }

  /// Example 4: Share a profile with analytics tracking
  static Future<void> shareProfileExample(String userId) async {
    try {
      print('📤 Sharing profile: $userId');
      
      // Share the profile using the integration manager
      await _deepLinkManager.shareProfile(userId);
      
      print('✅ Profile shared successfully with analytics tracking');
      
    } catch (e) {
      print('❌ Failed to share profile: $e');
    }
  }

  /// Example 5: Generate web fallback data for server-side rendering
  static Future<void> generateWebFallbackExample() async {
    try {
      print('🌐 Generating web fallback data...');
      
      // Generate fallback data for a post
      final postFallback = await _deepLinkManager.generatePostFallbackData('post123');
      print('📄 Post fallback data generated: ${postFallback.keys.length} fields');
      
      // Generate fallback data for a profile
      final profileFallback = await _deepLinkManager.generateProfileFallbackData('user456');
      print('👤 Profile fallback data generated: ${profileFallback.keys.length} fields');
      
      print('✅ Web fallback data generated successfully');
      
    } catch (e) {
      print('❌ Failed to generate web fallback data: $e');
    }
  }

  /// Example 6: Monitor system health and analytics
  static Future<void> monitorSystemExample() async {
    try {
      print('📊 Monitoring deep link system...');
      
      // Get system statistics
      final stats = await _deepLinkManager.getSystemStats();
      print('📈 System stats collected:');
      print('  - Total events: ${stats['analytics']?['total_events'] ?? 0}');
      final systemStats = stats['system'] as Map<String, dynamic>?;
      print('  - System health: ${systemStats?['is_initialized'] ?? false}');
      
      // Perform health check
      final health = await _deepLinkManager.performHealthCheck();
      final healthyComponents = health.values.where((h) => h).length;
      print('🏥 Health check: $healthyComponents/${health.length} components healthy');
      
      // Export analytics data for debugging
      final analyticsData = await _deepLinkManager.exportAnalyticsData();
      print('📤 Analytics data exported: ${analyticsData['events']?.length ?? 0} events');
      
      print('✅ System monitoring completed');
      
    } catch (e) {
      print('❌ Failed to monitor system: $e');
    }
  }

  /// Example 7: Handle user authentication change
  static Future<void> handleUserAuthChange(String? newUserId) async {
    try {
      if (newUserId != null) {
        print('🔐 User authenticated: $newUserId');
        await _deepLinkManager.setUserId(newUserId);
        print('✅ User ID updated in deep link system');
      } else {
        print('🚪 User logged out');
        // Analytics will continue with anonymous tracking
      }
    } catch (e) {
      print('❌ Failed to handle auth change: $e');
    }
  }

  /// Example 8: Test deep link processing manually
  static Future<void> testDeepLinkProcessing(BuildContext context) async {
    if (!context.mounted) return;
    
    try {
      print('🧪 Testing deep link processing...');
      
      // Test post deep link
      const postUrl = 'https://nepika.com/community/post/test123';
      await _deepLinkManager.processDeepLink(postUrl, context);
      print('✅ Post deep link processed');
      
      // Test profile deep link
      const profileUrl = 'https://nepika.com/community/profile/testuser';
      await _deepLinkManager.processDeepLink(profileUrl, context);
      print('✅ Profile deep link processed');
      
      print('✅ Deep link processing tests completed');
      
    } catch (e) {
      print('❌ Deep link processing test failed: $e');
    }
  }

  /// Example 9: Handle app link verification (Android)
  static Future<void> handleAppLinkVerificationExample() async {
    try {
      print('🔗 Handling app link verification...');
      
      await _deepLinkManager.handleAppLinkVerification();
      
      print('✅ App link verification handled');
      
    } catch (e) {
      print('❌ App link verification failed: $e');
    }
  }

  /// Example 10: Clean up resources
  static Future<void> cleanupExample() async {
    try {
      print('🧹 Cleaning up deep link system...');
      
      // Export any remaining analytics data before cleanup
      final finalData = await _deepLinkManager.exportAnalyticsData();
      print('📤 Final analytics export: ${finalData['events']?.length ?? 0} events');
      
      // Dispose all resources
      await _deepLinkManager.dispose();
      
      print('✅ Deep link system cleaned up successfully');
      
    } catch (e) {
      print('❌ Failed to clean up deep link system: $e');
    }
  }

  /// Complete integration example for main.dart
  static Future<void> completeIntegrationExample() async {
    try {
      print('🚀 Starting complete deep link integration example...');
      
      // 1. Initialize the system
      await initializeInMainApp(userId: 'example_user_123');
      
      // 2. Simulate sharing content
      await sharePostExample('example_post_456');
      await shareProfileExample('example_user_789');
      
      // 3. Generate web fallback data
      await generateWebFallbackExample();
      
      // 4. Monitor the system
      await monitorSystemExample();
      
      // 5. Handle authentication change
      await handleUserAuthChange('updated_user_123');
      
      // 6. Handle app link verification
      await handleAppLinkVerificationExample();
      
      print('✅ Complete integration example finished successfully');
      
    } catch (e) {
      print('❌ Complete integration example failed: $e');
    }
  }
}

/// Widget example showing how to integrate deep linking in a Flutter widget
class DeepLinkExampleWidget extends StatefulWidget {
  const DeepLinkExampleWidget({super.key});

  @override
  State<DeepLinkExampleWidget> createState() => _DeepLinkExampleWidgetState();
}

class _DeepLinkExampleWidgetState extends State<DeepLinkExampleWidget> {
  final DeepLinkIntegrationManager _deepLinkManager = DeepLinkIntegrationManager();
  Map<String, dynamic>? _systemStats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSystemStats();
  }

  Future<void> _loadSystemStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _deepLinkManager.getSystemStats();
      setState(() => _systemStats = stats);
    } catch (e) {
      print('Error loading system stats: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deep Link System Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSystemStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSystemHealthCard(),
                  const SizedBox(height: 16),
                  _buildAnalyticsCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSystemHealthCard() {
    final isHealthy = _systemStats?['system']?['is_initialized'] == true;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle : Icons.error,
                  color: isHealthy ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'System Health',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${isHealthy ? 'Healthy' : 'Issues Detected'}',
              style: TextStyle(
                color: isHealthy ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard() {
    final analytics = _systemStats?['analytics'] as Map<String, dynamic>?;
    final totalEvents = analytics?['total_events'] ?? 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Total Events: $totalEvents'),
            Text('Session ID: ${analytics?['session_id'] ?? 'Unknown'}'),
            Text('User ID: ${analytics?['user_id'] ?? 'Anonymous'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _testSharePost(),
                  child: const Text('Test Share Post'),
                ),
                ElevatedButton(
                  onPressed: () => _testShareProfile(),
                  child: const Text('Test Share Profile'),
                ),
                ElevatedButton(
                  onPressed: () => _performHealthCheck(),
                  child: const Text('Health Check'),
                ),
                ElevatedButton(
                  onPressed: () => _exportAnalytics(),
                  child: const Text('Export Analytics'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testSharePost() async {
    try {
      await _deepLinkManager.sharePost('test_post_123');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post share test completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post share test failed: $e')),
        );
      }
    }
  }

  Future<void> _testShareProfile() async {
    try {
      await _deepLinkManager.shareProfile('test_user_456');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile share test completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile share test failed: $e')),
        );
      }
    }
  }

  Future<void> _performHealthCheck() async {
    try {
      final health = await _deepLinkManager.performHealthCheck();
      final healthyCount = health.values.where((h) => h).length;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Health check: $healthyCount/${health.length} components healthy'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Health check failed: $e')),
        );
      }
    }
  }

  Future<void> _exportAnalytics() async {
    try {
      final data = await _deepLinkManager.exportAnalyticsData();
      final eventCount = data['events']?.length ?? 0;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analytics exported: $eventCount events')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analytics export failed: $e')),
        );
      }
    }
  }
}