# Token Refresh System Implementation

## Overview

This implementation provides automatic token refresh functionality for the Flutter app, ensuring seamless API access and proper authentication state management.

## Key Features

✅ **Automatic Token Storage**: Both access and refresh tokens are stored after OTP verification  
✅ **Transparent Token Management**: Tokens are automatically added to API requests  
✅ **Automatic 401 Handling**: Detects expired tokens and refreshes automatically  
✅ **Request Retry**: Original requests are retried with new tokens  
✅ **Secure Logout**: Handles refresh token expiry with proper navigation  
✅ **Production Ready**: Comprehensive error handling and logging  

## Architecture

### Core Components

1. **SecureApiClient** (`/lib/core/network/secure_api_client.dart`)
   - Main API client with token refresh capability
   - Singleton pattern for consistent token management
   - Automatic token addition to requests

2. **TokenRefreshInterceptor** (`/lib/core/network/token_refresh_interceptor.dart`)
   - Dio interceptor that handles 401 responses
   - Manages token refresh workflow
   - Retries failed requests with new tokens

3. **NavigationService** (`/lib/core/services/navigation_service.dart`)
   - Global navigation management
   - Handles logout navigation and stack clearing

4. **Enhanced ApiBase** (`/lib/core/api_base.dart`)
   - Backward compatible wrapper
   - Routes auth endpoints to legacy client
   - Routes protected endpoints to SecureApiClient

## Token Flow

### 1. OTP Verification & Token Storage
```dart
// In auth_repository_impl.dart:95-96
await localDataSource.storeToken(authResponse.token);
await localDataSource.storeRefreshToken(authResponse.refreshToken);
```

### 2. Automatic Token Addition
```dart
// SecureApiClient automatically adds tokens to requests
Future<void> _addAuthToken(RequestOptions options) async {
  final accessToken = prefs.getString(AppConstants.accessTokenKey);
  if (accessToken != null && accessToken.isNotEmpty) {
    options.headers['Authorization'] = 'Bearer $accessToken';
  }
}
```

### 3. 401 Handling & Token Refresh
```dart
@override
void onError(DioException err, ErrorInterceptorHandler handler) async {
  if (err.response?.statusCode == 401) {
    // 1. Get refresh token
    final refreshToken = prefs.getString(AppConstants.refreshTokenKey);
    
    // 2. Call refresh endpoint
    final refreshResponse = await refreshDio.post(
      ApiEndpoints.refreshToken,
      data: {'refresh_token': refreshToken},
    );
    
    // 3. Store new tokens
    await prefs.setString(AppConstants.accessTokenKey, newAccessToken);
    
    // 4. Retry original request
    final response = await dio.fetch(err.requestOptions);
    handler.resolve(response);
  }
}
```

### 4. Refresh Failure & Logout
```dart
void _handleLogout() async {
  // Clear all stored tokens
  await TokenRefreshManager.clearTokensAndLogout();
  
  // Navigate to login and clear stack
  NavigationService.navigateToLogin();
}
```

## Usage Examples

### Before (Manual Token Management)
```dart
// OLD WAY - Error prone and repetitive
final token = await getStoredToken();
if (token == null) {
  // Handle no token case
  return;
}

try {
  final response = await apiClient.get(
    '/profile',
    headers: {'Authorization': 'Bearer $token'}
  );
  // Handle response
} catch (e) {
  if (e is 401) {
    // Manually handle token refresh
    final newToken = await refreshToken();
    // Retry request
    final response = await apiClient.get(
      '/profile',
      headers: {'Authorization': 'Bearer $newToken'}
    );
  }
}
```

### After (Automatic Token Management)
```dart
// NEW WAY - Automatic and seamless
final response = await SecureApiClient.instance.request(
  path: '/profile',
  method: 'GET',
);
// Token is automatically added, refreshed if needed, and request retried!
```

### Existing API Clients (Updated)
```dart
// products_remote_datasource_impl.dart
@override
Future<List<ProductModel>> getMyProducts({required String token}) async {
  // Token parameter kept for compatibility, but not used
  // SecureApiClient automatically handles token management
  final response = await apiBase.request(
    path: ApiEndpoints.userMyProducts,
    method: 'GET',
    // No need for Authorization header - added automatically
  );
  
  // Token refresh happens transparently if needed
  return parseResponse(response);
}
```

## Setup Instructions

### 1. Navigation Integration
Add to your `main.dart`:
```dart
import 'core/services/navigation_service.dart';

MaterialApp(
  navigatorKey: NavigationService.navigatorKey, // Add this line
  // ... rest of your app config
)
```

### 2. API Endpoints
Ensure refresh token endpoint is defined:
```dart
// api_endpoints.dart
static const String refreshToken = '/auth/users/refresh-token';
```

### 3. Constants
Refresh token key already defined:
```dart
// app_constants.dart
static const String refreshTokenKey = 'refresh_token';
```

## Security Features

### Token Storage
- Uses SharedPreferences for secure local storage
- Tokens are stored with defined keys for consistency
- Automatic cleanup on logout

### Request Security
- Auth endpoints bypass token refresh to prevent loops
- Separate Dio instances prevent interceptor conflicts
- Comprehensive error handling

### Logout Security
- Clears ALL authentication data
- Forces navigation to login
- Removes entire navigation stack
- Prevents back navigation to protected screens

## Testing

Use the provided example class:
```dart
import 'core/examples/token_refresh_example.dart';

// Test profile API with automatic token refresh
await TokenRefreshExample.demonstrateProfileAPICall();

// Test manual token refresh
await TokenRefreshExample.demonstrateManualTokenRefresh();

// Simulate token expiry scenario
await TokenRefreshExample.demonstrateTokenExpiryScenario();
```

## Error Scenarios Handled

1. **Access Token Expired**: Automatically refreshed, request retried
2. **Refresh Token Expired**: User logged out, navigated to login
3. **Network Issues**: Standard error handling applies
4. **Malformed Responses**: Proper error logging and fallback
5. **Missing Tokens**: Graceful degradation

## Migration Path

### Phase 1 (Current): Backward Compatibility
- Existing API clients work without changes
- Token parameters maintained for compatibility
- Gradual migration possible

### Phase 2 (Future): Full Migration
```dart
// Remove token parameters from data source methods
Future<List<ProductModel>> getMyProducts() async {
  // No token parameter needed
  final response = await apiBase.request(
    path: ApiEndpoints.userMyProducts,
    method: 'GET',
  );
  return parseResponse(response);
}
```

## Monitoring & Debugging

### Logging
All token operations are logged with clear prefixes:
- 🔄 Token refresh operations
- 🔐 Token addition to requests  
- 🚪 Logout operations
- ✅ Success operations
- ❌ Error operations

### Debug Methods
```dart
// Manual token refresh for testing
await SecureApiClient.instance.refreshTokenManually();

// Check token refresh status
TokenRefreshManager.instance.setAuthFailureHandler(() {
  print('Auth failure detected');
});
```

## Production Considerations

### Performance
- Singleton pattern prevents multiple API client instances
- Efficient token caching
- Minimal overhead for non-auth endpoints

### Reliability
- Comprehensive error handling
- Fallback mechanisms
- Proper resource cleanup

### Security
- No token logging in production
- Secure token storage
- Automatic cleanup on failures

This implementation is production-ready and provides a robust foundation for authenticated API communication in the Flutter app.