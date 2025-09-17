import 'package:flutter/foundation.dart';
import '../network/secure_api_client.dart';
import '../config/constants/api_endpoints.dart';
import '../debug/run_token_test.dart';

/// Example demonstrating automatic token refresh functionality
/// 
/// This class shows how API requests now automatically:
/// 1. Add the stored access token to headers
/// 2. Detect 401 Unauthorized responses
/// 3. Automatically refresh the token using the refresh token
/// 4. Retry the original request with the new token
/// 5. Handle refresh failures by logging out the user
class TokenRefreshExample {
  
  /// Example: Make a profile API request
  /// This will automatically handle token refresh if the token is expired
  static Future<void> demonstrateProfileAPICall() async {
    try {
      debugPrint('🧪 TokenRefreshExample: Making profile API request...');
      
      // Make API call - token is automatically added and refreshed if needed
      final response = await SecureApiClient.instance.request(
        path: ApiEndpoints.userDetails,
        method: 'GET',
      );
      
      if (response.statusCode == 200) {
        debugPrint('✅ TokenRefreshExample: Profile API call successful!');
        debugPrint('📄 Response data: ${response.data}');
      } else {
        debugPrint('⚠️ TokenRefreshExample: Profile API call failed with status: ${response.statusCode}');
      }
      
    } catch (e) {
      debugPrint('❌ TokenRefreshExample: Profile API call error: $e');
    }
  }
  
  /// Example: Make a products API request
  /// This demonstrates how the middleware works with different endpoints
  static Future<void> demonstrateProductsAPICall() async {
    try {
      debugPrint('🧪 TokenRefreshExample: Making products API request...');
      
      final response = await SecureApiClient.instance.request(
        path: ApiEndpoints.userMyProducts,
        method: 'GET',
      );
      
      if (response.statusCode == 200) {
        debugPrint('✅ TokenRefreshExample: Products API call successful!');
        debugPrint('📄 Response data: ${response.data}');
      } else {
        debugPrint('⚠️ TokenRefreshExample: Products API call failed with status: ${response.statusCode}');
      }
      
    } catch (e) {
      debugPrint('❌ TokenRefreshExample: Products API call error: $e');
    }
  }
  
  /// Example: Manually test token refresh
  /// This can be used for testing or explicit token refresh scenarios
  static Future<void> demonstrateManualTokenRefresh() async {
    try {
      debugPrint('🧪 TokenRefreshExample: Attempting manual token refresh...');
      
      final success = await SecureApiClient.instance.refreshTokenManually();
      
      if (success) {
        debugPrint('✅ TokenRefreshExample: Manual token refresh successful!');
      } else {
        debugPrint('❌ TokenRefreshExample: Manual token refresh failed');
      }
      
    } catch (e) {
      debugPrint('❌ TokenRefreshExample: Manual token refresh error: $e');
    }
  }
  
  /// Example: Simulate token expiry scenario
  /// This shows what happens when both access and refresh tokens expire
  static Future<void> demonstrateTokenExpiryScenario() async {
    try {
      debugPrint('🧪 TokenRefreshExample: Simulating token expiry scenario...');
      debugPrint('📝 Note: If both tokens are expired, user will be logged out automatically');
      
      // This request will fail with 401, trigger refresh attempt
      // If refresh also fails, user will be logged out and redirected to login
      final response = await SecureApiClient.instance.request(
        path: ApiEndpoints.userDetails,
        method: 'GET',
      );
      
      debugPrint('✅ TokenRefreshExample: Request succeeded (tokens were valid or refreshed)');
      debugPrint('📄 Response status: ${response.statusCode}');
      
    } catch (e) {
      debugPrint('❌ TokenRefreshExample: Token expiry scenario error: $e');
      debugPrint('🚪 User should now be redirected to login screen');
    }
  }
  
  /// Run comprehensive diagnostics to debug token refresh issues
  /// This will test token storage, backend connectivity, and the refresh system
  static Future<void> runDebugDiagnostics() async {
    debugPrint('🔧 TokenRefreshExample: Running debug diagnostics...');
    await TokenTestRunner.runDiagnostics();
  }
  
  /// Test only the backend refresh token endpoint
  static Future<void> testBackendRefreshEndpoint() async {
    debugPrint('🌐 TokenRefreshExample: Testing backend refresh endpoint...');
    await TokenTestRunner.testBackendOnly();
  }
}

/// How the Token Refresh System Works:
/// 
/// 1. **Automatic Token Addition**: 
///    - SecureApiClient automatically adds the stored access token to all API requests
///    - No need to manually pass tokens in your API calls
/// 
/// 2. **401 Detection**: 
///    - TokenRefreshInterceptor detects 401 Unauthorized responses
///    - Automatically triggers token refresh process
/// 
/// 3. **Token Refresh**: 
///    - Uses stored refresh token to get new access token
///    - Updates stored tokens with new values
///    - Retries original failed request with new token
/// 
/// 4. **Refresh Failure Handling**: 
///    - If refresh token is also expired/invalid, clears all tokens
///    - Navigates user to login screen
///    - Clears navigation stack to prevent back navigation to protected screens
/// 
/// 5. **Seamless User Experience**: 
///    - All token management happens transparently
///    - User continues their workflow without interruption
///    - Only logs out when both tokens are invalid
/// 
/// Usage in your code:
/// ```dart
/// // OLD WAY - Manual token management:
/// final token = await getStoredToken();
/// final response = await apiClient.get('/profile', headers: {'Authorization': 'Bearer $token'});
/// 
/// // NEW WAY - Automatic token management:
/// final response = await SecureApiClient.instance.request(path: '/profile', method: 'GET');
/// // Token is automatically added, refreshed if needed, and request retried!
/// ```