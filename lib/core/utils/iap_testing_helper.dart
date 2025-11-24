import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class IAPTestingHelper {
  static const String _channel = 'com.assisted.nepika/iap_testing';
  static const MethodChannel _methodChannel = MethodChannel(_channel);

  /// Check if app is running in sandbox environment (iOS) or testing mode (Android)
  static Future<bool> isTestEnvironment() async {
    if (!kDebugMode) return false;
    
    try {
      final result = await _methodChannel.invokeMethod('isTestEnvironment');
      return result as bool? ?? true; // Default to test mode in debug
    } catch (e) {
      // If native method not implemented, default to test mode in debug builds
      debugPrint('IAPTestingHelper: Failed to check test environment, defaulting to test mode: $e');
      return true;
    }
  }

  /// Get test product IDs for sandbox testing
  static Map<String, String> getTestProductIds() {
    return {
      'weekly': 'nepika_weekly_subscription',
      'yearly': 'nepika_yearly_subscription',
    };
  }

  /// Get test user information for sandbox
  static Map<String, String> getTestUserInfo() {
    return {
      'ios_sandbox_email': 'test.nepika@icloud.com',
      'android_test_license': 'android.test.purchased',
    };
  }

  /// Validate product ID format
  static bool isValidProductId(String productId) {
    final validIds = [
      'nepika_weekly_subscription',
      'nepika_yearly_subscription',
    ];
    return validIds.contains(productId);
  }

  /// Create debug log for purchase testing
  static void logPurchaseAttempt({
    required String productId,
    required String platform,
    String? userId,
  }) {
    if (!kDebugMode) return;
    
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('''
=== IAP PURCHASE ATTEMPT ===
Time: $timestamp
Product ID: $productId
Platform: $platform
User ID: ${userId ?? 'Not provided'}
Test Environment: ${kDebugMode ? 'Yes' : 'No'}
=============================
''');
  }

  /// Log purchase result for debugging
  static void logPurchaseResult({
    required String productId,
    required String status,
    String? error,
    String? transactionId,
  }) {
    if (!kDebugMode) return;
    
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('''
=== IAP PURCHASE RESULT ===
Time: $timestamp
Product ID: $productId
Status: $status
Transaction ID: ${transactionId ?? 'None'}
Error: ${error ?? 'None'}
===========================
''');
  }

  /// Check if current build is for testing
  static bool isTestBuild() {
    return kDebugMode;
  }

  /// Get recommended test scenarios
  static List<Map<String, dynamic>> getTestScenarios() {
    return [
      {
        'name': 'Successful Purchase',
        'description': 'Test successful weekly subscription purchase',
        'product_id': 'nepika_weekly_subscription',
        'expected_result': 'success',
      },
      {
        'name': 'Purchase Cancellation',
        'description': 'User cancels purchase during payment flow',
        'product_id': 'nepika_weekly_subscription',
        'expected_result': 'cancelled',
      },
      {
        'name': 'Network Failure',
        'description': 'Test behavior when network is unavailable',
        'product_id': 'nepika_yearly_subscription',
        'expected_result': 'error',
      },
      {
        'name': 'Already Subscribed',
        'description': 'Test purchasing when already subscribed',
        'product_id': 'nepika_weekly_subscription',
        'expected_result': 'already_owned',
      },
      {
        'name': 'Restore Purchases',
        'description': 'Test restoring previous purchases',
        'product_id': 'all',
        'expected_result': 'restored',
      },
    ];
  }

  /// Generate test receipt data for backend testing
  static Map<String, dynamic> generateTestReceipt({
    required String productId,
    required String platform,
  }) {
    final now = DateTime.now();
    return {
      'product_id': productId,
      'purchase_time': now.millisecondsSinceEpoch,
      'purchase_state': 1, // Purchased
      'developer_payload': 'test_payload',
      'package_name': 'com.assisted.nepika',
      'order_id': 'test_order_${now.millisecondsSinceEpoch}',
      'platform': platform,
      'is_test': true,
    };
  }

  /// Validate test environment setup
  static Future<Map<String, bool>> validateTestSetup() async {
    final results = <String, bool>{};
    
    try {
      // Check if products are configured
      results['products_configured'] = getTestProductIds().isNotEmpty;
      
      // Check if in test environment
      results['test_environment'] = await isTestEnvironment();
      
      // Check debug mode
      results['debug_mode'] = kDebugMode;
      
      // Platform check
      results['platform_supported'] = defaultTargetPlatform == TargetPlatform.iOS || 
                                     defaultTargetPlatform == TargetPlatform.android;
      
    } catch (e) {
      debugPrint('IAPTestingHelper: Validation failed: $e');
      results['validation_failed'] = true;
    }
    
    return results;
  }

  /// Print testing setup guide
  static void printTestingGuide() {
    if (!kDebugMode) return;
    
    debugPrint('''
📱 NEPIKA IAP TESTING GUIDE 📱

🍎 iOS Testing:
1. Use a sandbox Apple ID: test.nepika@icloud.com
2. Sign out of your Apple ID in Settings
3. When prompted during purchase, sign in with sandbox account
4. Check App Store Connect for sandbox transactions

🤖 Android Testing:
1. Upload APK to Internal Testing track in Google Play Console
2. Add your email as a test user
3. Install from Play Console link
4. Use real Google account for testing

📋 Test Products:
- Weekly: nepika_weekly_subscription (\$1.99)
- Yearly: nepika_yearly_subscription (\$60.00)

🔍 Test Scenarios:
${getTestScenarios().map((scenario) => '- ${scenario['name']}: ${scenario['description']}').join('\n')}

❗ Important Notes:
- iOS requires App Store Connect submission before testing
- Android requires app upload to Play Console
- Test in device, not simulator/emulator
- Clear app data between test runs
''');
  }
}