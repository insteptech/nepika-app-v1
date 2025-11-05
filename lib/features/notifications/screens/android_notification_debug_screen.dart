import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/unified_fcm_service.dart';
import '../../../core/services/android_notification_service.dart';
import '../../../core/utils/app_logger.dart';

/// Android Notification Debug Screen
/// This screen helps debug and fix Android notification issues
class AndroidNotificationDebugScreen extends StatefulWidget {
  const AndroidNotificationDebugScreen({super.key});

  @override
  State<AndroidNotificationDebugScreen> createState() => _AndroidNotificationDebugScreenState();
}

class _AndroidNotificationDebugScreenState extends State<AndroidNotificationDebugScreen> {
  Map<String, dynamic>? _fcmStatus;
  Map<String, dynamic>? _androidStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final fcmStatus = UnifiedFcmService.instance.getStatus();
      final androidStatus = await AndroidNotificationService.instance.getAndroidNotificationStatus();
      
      setState(() {
        _fcmStatus = fcmStatus;
        _androidStatus = androidStatus;
      });
    } catch (e) {
      AppLogger.error('Failed to load notification status', tag: 'Debug', error: e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Android Notification Debug'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader('Android Notification Debugging'),
                  const SizedBox(height: 20),
                  
                  // Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: 20),
                  
                  // FCM Status
                  _buildStatusCard('FCM Service Status', _fcmStatus),
                  const SizedBox(height: 16),
                  
                  // Android Status
                  _buildStatusCard('Android Notification Status', _androidStatus),
                  const SizedBox(height: 20),
                  
                  // Detailed Actions
                  _buildDetailedActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use this screen to diagnose and fix Android notification issues. '
            'Try the test buttons below to verify your setup.',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Tests',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _testAndroidNotification,
                  icon: const Icon(Icons.android),
                  label: const Text('Test Android'),
                ),
                ElevatedButton.icon(
                  onPressed: _testFcmNotification,
                  icon: const Icon(Icons.notification_important),
                  label: const Text('Test FCM'),
                ),
                ElevatedButton.icon(
                  onPressed: _checkPermissions,
                  icon: const Icon(Icons.security),
                  label: const Text('Check Perms'),
                ),
                ElevatedButton.icon(
                  onPressed: _openSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('Open Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, Map<String, dynamic>? status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (status == null)
              const Text('Loading status...')
            else
              ...status.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.value.toString(),
                        style: TextStyle(
                          color: _getStatusColor(entry.value),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Status'),
              subtitle: const Text('Reload all notification status information'),
              onTap: _loadStatus,
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Run Full Diagnostics'),
              subtitle: const Text('Comprehensive notification system check'),
              onTap: _runFullDiagnostics,
            ),
            ListTile(
              leading: const Icon(Icons.healing),
              title: const Text('Fix Common Issues'),
              subtitle: const Text('Attempt automatic fixes for known problems'),
              onTap: _fixCommonIssues,
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Show Debug Info'),
              subtitle: const Text('Print detailed debug information to console'),
              onTap: _showDebugInfo,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(dynamic value) {
    if (value is bool) {
      return value ? Colors.green : Colors.red;
    }
    if (value.toString().toLowerCase().contains('granted') ||
        value.toString().toLowerCase().contains('true') ||
        value.toString().toLowerCase().contains('authorized')) {
      return Colors.green;
    }
    if (value.toString().toLowerCase().contains('denied') ||
        value.toString().toLowerCase().contains('false') ||
        value.toString().toLowerCase().contains('error')) {
      return Colors.red;
    }
    return Colors.orange;
  }

  Future<void> _testAndroidNotification() async {
    _showLoadingDialog('Testing Android Notification...');
    
    try {
      final success = await AndroidNotificationService.instance.showTestNotification();
      Navigator.of(context).pop(); // Close loading dialog
      
      _showResultDialog(
        'Android Test Result',
        success 
            ? 'Android notification test successful! Check if you received the notification.'
            : 'Android notification test failed. Check permissions and configuration.',
        success,
      );
    } catch (e) {
      Navigator.of(context).pop();
      _showResultDialog('Android Test Error', 'Error: $e', false);
    }
  }

  Future<void> _testFcmNotification() async {
    _showLoadingDialog('Testing FCM Notification...');
    
    try {
      final success = await UnifiedFcmService.instance.testForegroundNotification();
      Navigator.of(context).pop();
      
      _showResultDialog(
        'FCM Test Result',
        success 
            ? 'FCM notification test successful! Check if you received the notification.'
            : 'FCM notification test failed. Check FCM configuration.',
        success,
      );
    } catch (e) {
      Navigator.of(context).pop();
      _showResultDialog('FCM Test Error', 'Error: $e', false);
    }
  }

  Future<void> _checkPermissions() async {
    _showLoadingDialog('Checking Permissions...');
    
    try {
      final notificationStatus = await Permission.notification.status;
      Navigator.of(context).pop();
      
      String message = 'Notification Permission: $notificationStatus\n\n';
      
      if (notificationStatus.isGranted) {
        message += '✅ Notification permission is granted.';
      } else if (notificationStatus.isDenied) {
        message += '❌ Notification permission is denied. Tap "Request Permission" to fix.';
      } else if (notificationStatus.isPermanentlyDenied) {
        message += '⚠️ Notification permission is permanently denied. Open app settings to enable.';
      }
      
      _showPermissionDialog('Permission Status', message, notificationStatus);
    } catch (e) {
      Navigator.of(context).pop();
      _showResultDialog('Permission Check Error', 'Error: $e', false);
    }
  }

  Future<void> _openSettings() async {
    try {
      final opened = await AndroidNotificationService.instance.openNotificationSettings();
      if (!opened) {
        _showResultDialog(
          'Settings Error',
          'Could not open notification settings. Please manually go to:\n'
          'Settings > Apps > Nepika > Notifications',
          false,
        );
      }
    } catch (e) {
      _showResultDialog('Settings Error', 'Error opening settings: $e', false);
    }
  }

  Future<void> _runFullDiagnostics() async {
    _showLoadingDialog('Running Full Diagnostics...');
    
    try {
      final diagnostics = await UnifiedFcmService.instance.runNotificationDiagnostics();
      Navigator.of(context).pop();
      
      final buffer = StringBuffer();
      buffer.writeln('FULL DIAGNOSTIC RESULTS:\n');
      
      diagnostics.forEach((key, value) {
        buffer.writeln('$key: $value');
      });
      
      _showResultDialog('Diagnostic Results', buffer.toString(), true);
    } catch (e) {
      Navigator.of(context).pop();
      _showResultDialog('Diagnostic Error', 'Error: $e', false);
    }
  }

  Future<void> _fixCommonIssues() async {
    _showLoadingDialog('Attempting Fixes...');
    
    try {
      // Re-initialize notification services
      await AndroidNotificationService.instance.initialize();
      await UnifiedFcmService.instance.initialize();
      
      // Refresh status
      await _loadStatus();
      
      Navigator.of(context).pop();
      _showResultDialog(
        'Fix Attempt Complete',
        'Common fixes have been applied:\n'
        '• Re-initialized notification services\n'
        '• Refreshed status\n\n'
        'Try testing notifications again.',
        true,
      );
    } catch (e) {
      Navigator.of(context).pop();
      _showResultDialog('Fix Error', 'Error applying fixes: $e', false);
    }
  }

  Future<void> _showDebugInfo() async {
    try {
      await UnifiedFcmService.instance.printDebugInfo();
      _showResultDialog(
        'Debug Info',
        'Detailed debug information has been printed to the console. '
        'Check your IDE or device logs for comprehensive details.',
        true,
      );
    } catch (e) {
      _showResultDialog('Debug Error', 'Error printing debug info: $e', false);
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showResultDialog(String title, String message, bool isSuccess) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog(String title, String message, PermissionStatus status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (status.isDenied)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Permission.notification.request();
                _checkPermissions();
              },
              child: const Text('Request Permission'),
            ),
          if (status.isPermanentlyDenied)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}