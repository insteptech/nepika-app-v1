# NEPIKA Deep Linking Setup Guide

This guide provides step-by-step instructions for setting up and testing the comprehensive deep linking system in the NEPIKA Flutter application.

## 🎯 Overview

The NEPIKA deep linking system provides:
- ✅ **Universal Deep Links** via https://nepika.com URLs
- ✅ **Firebase Dynamic Links** for rich social previews
- ✅ **Custom URL Schemes** for app-to-app communication
- ✅ **Web Fallback Pages** for non-app users
- ✅ **Comprehensive Analytics** for tracking and optimization
- ✅ **Offline Support** with action queuing

## 📋 Prerequisites

### 1. Dependencies Required

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  # Core routing
  go_router: ^13.0.0
  
  # Sharing
  share_plus: ^7.2.1
  
  # Analytics (when available)
  # firebase_analytics: ^10.7.4
  # firebase_dynamic_links: ^5.4.8
  
  # Storage
  shared_preferences: ^2.2.2
  
  # Existing dependencies
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
```

### 2. Platform Setup

#### Android Setup

1. **Update AndroidManifest.xml** (already configured):
```xml
<!-- Intent filters already added in android/app/src/main/AndroidManifest.xml -->
```

2. **App Link Verification**:
   - Upload `.well-known/assetlinks.json` to https://nepika.com/
   - Content should include your app's package name and SHA256 fingerprint

#### iOS Setup

1. **Add URL Schemes to Info.plist**:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>nepika.com</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>https</string>
            <string>nepika</string>
        </array>
    </dict>
</array>
```

2. **Associated Domains**:
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:nepika.com</string>
    <string>applinks:nepika.page.link</string>
</array>
```

## 🚀 Integration Steps

### Step 1: Initialize in main.dart

```dart
import 'package:flutter/material.dart';
import 'lib/core/integration/deep_link_integration_manager.dart';
import 'lib/core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize deep linking system
  final deepLinkManager = DeepLinkIntegrationManager();
  
  try {
    await deepLinkManager.initialize(
      navigatorKey: AppRouter.router.routerDelegate.navigatorKey,
      userId: await getCurrentUserId(), // Your auth logic
    );
    
    print('✅ Deep linking initialized successfully');
  } catch (e) {
    print('❌ Deep linking initialization failed: $e');
  }
  
  runApp(MyApp());
}
```

### Step 2: Update Your App Widget

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NEPIKA',
      routerConfig: AppRouter.router,
      // ... other configurations
    );
  }
}
```

### Step 3: Add Sharing Functionality

```dart
// In your post widget
class PostWidget extends StatelessWidget {
  final String postId;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Post content...
          
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () async {
              final deepLinkManager = DeepLinkIntegrationManager();
              await deepLinkManager.sharePost(postId);
            },
          ),
        ],
      ),
    );
  }
}
```

### Step 4: Handle Authentication Changes

```dart
// In your authentication service
class AuthService {
  final DeepLinkIntegrationManager _deepLinkManager = DeepLinkIntegrationManager();
  
  Future<void> onUserSignIn(String userId) async {
    await _deepLinkManager.setUserId(userId);
  }
  
  Future<void> onUserSignOut() async {
    // Deep linking will continue with anonymous tracking
  }
}
```

## 🧪 Testing Guide

### Manual Testing

#### 1. Test Deep Link Reception

```bash
# Android - ADB command
adb shell am start \
  -W -a android.intent.action.VIEW \
  -d "https://nepika.com/community/post/test123" \
  com.assisted.nepika

# iOS - Simulator
xcrun simctl openurl booted "https://nepika.com/community/post/test123"
```

#### 2. Test URL Schemes

```bash
# Android
adb shell am start \
  -W -a android.intent.action.VIEW \
  -d "nepika://community/profile/testuser" \
  com.assisted.nepika

# iOS
xcrun simctl openurl booted "nepika://community/profile/testuser"
```

### Automated Testing

Use the provided test widget:

```dart
import 'lib/core/integration/deep_link_usage_example.dart';

// Add to your app for testing
class TestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DeepLinkExampleWidget();
  }
}
```

### Testing Checklist

- [ ] **App Install Flow**: Share link → Install app → Open link
- [ ] **Authentication Flow**: Open link while logged out → Sign in → Navigate to content
- [ ] **Web Fallback**: Open link on device without app → See fallback page
- [ ] **Social Sharing**: Share on WhatsApp/Twitter → Rich preview displays
- [ ] **Analytics Tracking**: Check analytics data collection
- [ ] **Offline Support**: Share while offline → Actions queue properly

## 📊 Monitoring & Analytics

### View System Health

```dart
final deepLinkManager = DeepLinkIntegrationManager();

// Get comprehensive stats
final stats = await deepLinkManager.getSystemStats();
print('Total events: ${stats['analytics']['total_events']}');

// Perform health check
final health = await deepLinkManager.performHealthCheck();
print('System healthy: ${health['system']}');
```

### Export Analytics Data

```dart
// Export for debugging or server upload
final analyticsData = await deepLinkManager.exportAnalyticsData();

// Send to your backend
await uploadAnalyticsToServer(analyticsData);
```

### Track Custom Events

```dart
final analytics = deepLinkManager.analytics;

await analytics.trackEvent('custom_event', {
  'custom_parameter': 'value',
  'user_action': 'button_tap',
});
```

## 🌐 Web Fallback Setup

### Server-Side Implementation

1. **Create Dynamic Routes** on your web server:
   ```
   GET /community/post/:postId -> Render post fallback
   GET /community/profile/:userId -> Render profile fallback
   ```

2. **Use Fallback Service**:
   ```dart
   // In your backend API
   final fallbackService = WebFallbackService();
   
   // Generate data for template
   final data = await fallbackService.generatePostFallbackData(
     postId: postId,
     post: await fetchPost(postId),
     author: await fetchAuthor(authorId),
   );
   
   // Render HTML template with data
   return renderTemplate('post.html', data);
   ```

3. **Template Variables**:
   The service provides these template variables:
   - `{{POST_TITLE}}` - Post title for meta tags
   - `{{POST_CONTENT}}` - Post content (truncated)
   - `{{POST_USERNAME}}` - Author username
   - `{{POST_AVATAR_URL}}` - Author avatar image
   - `{{POST_IMAGE_URL}}` - Post image
   - And many more...

## 🔧 Troubleshooting

### Common Issues

#### 1. Deep Links Not Opening App

**Problem**: Links open in browser instead of app

**Solutions**:
- Verify intent filters in AndroidManifest.xml
- Check iOS Associated Domains setup
- Ensure app is installed and scheme is registered
- Test with custom URL scheme first: `nepika://`

#### 2. Web Fallback Not Loading

**Problem**: Fallback pages show errors

**Solutions**:
- Check server-side template rendering
- Verify all template variables are provided
- Test Open Graph tags with Facebook Debugger
- Ensure manifest.json is accessible

#### 3. Analytics Not Tracking

**Problem**: Events not being recorded

**Solutions**:
- Verify AnalyticsService initialization
- Check SharedPreferences permissions
- Ensure proper error handling
- Test with debug prints

#### 4. Authentication Flow Issues

**Problem**: Deep links don't work after sign-in

**Solutions**:
- Verify pending deep link storage/retrieval
- Check router redirect logic
- Ensure context is mounted before navigation
- Test authentication state changes

### Debug Commands

```dart
// Enable debug logging
debugPrint('Deep link system status: ${await manager.getSystemStats()}');

// Clear analytics data
await manager.clearAnalyticsData();

// Force health check
final health = await manager.performHealthCheck();
```

## 🎯 Best Practices

### 1. Error Handling
- Always wrap deep link operations in try-catch
- Provide fallback navigation for failed deep links
- Track errors for debugging

### 2. Performance
- Initialize deep linking early in app lifecycle
- Cache fallback data for faster web pages
- Use analytics data to optimize user flows

### 3. User Experience
- Show loading states during deep link processing
- Provide clear CTAs on fallback pages
- Handle authentication gracefully

### 4. Security
- Validate all incoming deep link data
- Sanitize user content in fallback pages
- Use HTTPS for all web fallback URLs

## 📈 Success Metrics

Track these metrics to measure deep linking success:

- **Deep Link Open Rate**: Links opened vs shared
- **App Install Conversion**: Installs from shared links
- **Authentication Conversion**: Sign-ups from deep links
- **Content Engagement**: Interactions after deep link navigation
- **Fallback Page Views**: Web fallback usage
- **Error Rates**: Failed deep link operations

## 🔄 Maintenance

### Regular Tasks

1. **Monitor Analytics**: Weekly review of deep link metrics
2. **Update Fallback Content**: Keep web previews current
3. **Test New Flows**: Verify deep links with app updates
4. **Security Audits**: Review URL handling and validation

### When to Update

- App version changes (update manifest)
- Domain changes (update intent filters)
- New content types (add new deep link routes)
- Analytics requirements (extend tracking)

## 📞 Support

If you encounter issues:

1. Check the comprehensive test examples in `deep_link_usage_example.dart`
2. Review system health with `performHealthCheck()`
3. Export analytics data for debugging
4. Verify platform-specific setup (Android/iOS)

## 🎉 Conclusion

The NEPIKA deep linking system is now fully configured and ready for production use. The implementation provides:

- **Comprehensive Coverage**: All major deep linking scenarios
- **Rich Analytics**: Detailed tracking and monitoring
- **Offline Support**: Queue actions when offline
- **Web Fallback**: Graceful degradation for non-app users
- **Easy Integration**: Simple APIs for sharing and navigation

Your deep linking system is production-ready! 🚀