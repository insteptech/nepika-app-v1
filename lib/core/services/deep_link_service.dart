import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/community/entities/community_entities.dart';
import '../routing/app_router.dart';
import 'analytics_service.dart';

/// Deep Link Service - Handles Firebase Dynamic Links, URL generation, and sharing
/// Manages the complete deep linking flow for NEPIKA community features
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  // Firebase Dynamic Links configuration
  static const String _dynamicLinkPrefix = 'https://nepika.page.link';
  static const String _baseUrl = 'https://nepika.com';
  static const String _androidPackageName = 'com.assisted.nepika';
  static const String _iosAppStoreId = '123456789'; // Replace with actual App Store ID
  static const String _iosBundleId = 'com.assisted.nepika';

  // Local storage keys
  static const String _pendingDeepLinkKey = 'pending_deep_link';
  static const String _deepLinkAnalyticsKey = 'deep_link_analytics';

  bool _isInitialized = false;
  StreamController<String>? _deepLinkController;
  final AnalyticsService _analytics = AnalyticsService();

  /// Initialize the deep link service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _deepLinkController = StreamController<String>.broadcast();
      
      // Initialize Firebase Dynamic Links when the package is available
      // For now, we'll simulate the functionality
      await _initializeFirebaseDynamicLinks();
      
      _isInitialized = true;
      debugPrint('DeepLinkService: Initialized successfully');
    } catch (e) {
      debugPrint('DeepLinkService: Initialization failed - $e');
      rethrow;
    }
  }

  /// Initialize Firebase Dynamic Links (simulated for now)
  Future<void> _initializeFirebaseDynamicLinks() async {
    try {
      // TODO: Initialize actual Firebase Dynamic Links when dependency is added
      // FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
      //   _handleIncomingDynamicLink(dynamicLinkData.link);
      // });
      
      // Handle initial link when app is launched from a link
      // final initialLink = await FirebaseDynamicLinks.instance.getInitialLink();
      // if (initialLink != null) {
      //   _handleIncomingDynamicLink(initialLink.link);
      // }
      
      debugPrint('DeepLinkService: Firebase Dynamic Links initialized');
    } catch (e) {
      debugPrint('DeepLinkService: Error initializing Firebase Dynamic Links - $e');
    }
  }

  /// Handle incoming dynamic link
  void _handleIncomingDynamicLink(Uri deepLink) {
    final url = deepLink.toString();
    debugPrint('DeepLinkService: Received deep link - $url');
    
    _deepLinkController?.add(url);
    
    // Track with analytics service
    _analytics.trackDeepLinkReceived(
      url: url,
      source: 'firebase_dynamic_link',
    );
  }

  /// Generate shareable URL for a post
  Future<String> generatePostShareUrl(String postId, {PostEntity? post}) async {
    try {
      final baseUrl = '$_baseUrl/community/post/$postId';
      
      // Create Firebase Dynamic Link parameters
      final dynamicLinkParams = {
        'link': baseUrl,
        'domainUriPrefix': _dynamicLinkPrefix,
        'android': {
          'packageName': _androidPackageName,
          'fallbackUrl': baseUrl,
        },
        'ios': {
          'bundleId': _iosBundleId,
          'appStoreId': _iosAppStoreId,
          'fallbackUrl': baseUrl,
        },
        'socialMetaTagInfo': _buildSocialMetaTags(
          title: post?.content ?? 'Check out this post on NEPIKA',
          description: 'Join the conversation on NEPIKA - the beauty and skincare community',
          imageUrl: post?.userAvatar,
        ),
      };

      // For now, return the base URL since we don't have Firebase Dynamic Links setup
      // TODO: Create actual Firebase Dynamic Link when dependency is available
      final shortUrl = await _createShortDynamicLink(dynamicLinkParams);
      
      debugPrint('DeepLinkService: Generated post share URL - $shortUrl');
      return shortUrl;
    } catch (e) {
      debugPrint('DeepLinkService: Error generating post share URL - $e');
      return '$_baseUrl/community/post/$postId';
    }
  }

  /// Generate shareable URL for a user profile
  Future<String> generateProfileShareUrl(String userId, {CommunityProfileEntity? profile}) async {
    try {
      final baseUrl = '$_baseUrl/community/profile/$userId';
      
      // Create Firebase Dynamic Link parameters
      final dynamicLinkParams = {
        'link': baseUrl,
        'domainUriPrefix': _dynamicLinkPrefix,
        'android': {
          'packageName': _androidPackageName,
          'fallbackUrl': baseUrl,
        },
        'ios': {
          'bundleId': _iosBundleId,
          'appStoreId': _iosAppStoreId,
          'fallbackUrl': baseUrl,
        },
        'socialMetaTagInfo': _buildSocialMetaTags(
          title: '${profile?.username ?? 'User'} on NEPIKA',
          description: profile?.bio ?? 'Follow ${profile?.username ?? 'this user'} on NEPIKA for beauty and skincare tips',
          imageUrl: profile?.profileImageUrl,
        ),
      };

      // For now, return the base URL since we don't have Firebase Dynamic Links setup
      // TODO: Create actual Firebase Dynamic Link when dependency is available
      final shortUrl = await _createShortDynamicLink(dynamicLinkParams);
      
      debugPrint('DeepLinkService: Generated profile share URL - $shortUrl');
      return shortUrl;
    } catch (e) {
      debugPrint('DeepLinkService: Error generating profile share URL - $e');
      return '$_baseUrl/community/profile/$userId';
    }
  }

  /// Create short dynamic link (simulated for now)
  Future<String> _createShortDynamicLink(Map<String, dynamic> params) async {
    try {
      // TODO: Create actual Firebase Dynamic Link when dependency is available
      // final shortLink = await FirebaseDynamicLinks.instance.buildShortLink(
      //   DynamicLinkParameters(
      //     uriPrefix: params['domainUriPrefix'],
      //     link: Uri.parse(params['link']),
      //     androidParameters: AndroidParameters(
      //       packageName: params['android']['packageName'],
      //       fallbackUrl: Uri.parse(params['android']['fallbackUrl']),
      //     ),
      //     iosParameters: IOSParameters(
      //       bundleId: params['ios']['bundleId'],
      //       appStoreId: params['ios']['appStoreId'],
      //       fallbackUrl: Uri.parse(params['ios']['fallbackUrl']),
      //     ),
      //     socialMetaTagParameters: SocialMetaTagParameters(
      //       title: params['socialMetaTagInfo']['title'],
      //       description: params['socialMetaTagInfo']['description'],
      //       imageUrl: params['socialMetaTagInfo']['imageUrl'] != null 
      //         ? Uri.parse(params['socialMetaTagInfo']['imageUrl']) 
      //         : null,
      //     ),
      //   ),
      // );
      // return shortLink.shortUrl.toString();
      
      // For now, return the base link
      return params['link'] as String;
    } catch (e) {
      debugPrint('DeepLinkService: Error creating short dynamic link - $e');
      return params['link'] as String;
    }
  }

  /// Build social meta tags for rich previews
  Map<String, dynamic> _buildSocialMetaTags({
    required String title,
    required String description,
    String? imageUrl,
  }) {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl ?? '$_baseUrl/assets/images/nepika_logo.png',
    };
  }

  /// Share a post with dynamic link
  Future<void> sharePost(String postId, {PostEntity? post}) async {
    try {
      final shareUrl = await generatePostShareUrl(postId, post: post);
      
      final shareText = _buildPostShareText(post, shareUrl);
      
      await Share.share(
        shareText,
        subject: 'Check out this post on NEPIKA',
      );
      
      // Track sharing analytics
      await _analytics.trackPostShared(
        postId: postId,
        method: 'system_share',
      );
      
      debugPrint('DeepLinkService: Post shared successfully - $postId');
    } catch (e) {
      debugPrint('DeepLinkService: Error sharing post - $e');
      rethrow;
    }
  }

  /// Share a user profile with dynamic link
  Future<void> shareProfile(String userId, {CommunityProfileEntity? profile}) async {
    try {
      final shareUrl = await generateProfileShareUrl(userId, profile: profile);
      
      final shareText = _buildProfileShareText(profile, shareUrl);
      
      await Share.share(
        shareText,
        subject: '${profile?.username ?? 'User'} on NEPIKA',
      );
      
      // Track sharing analytics
      await _analytics.trackProfileShared(
        userId: userId,
        method: 'system_share',
      );
      
      debugPrint('DeepLinkService: Profile shared successfully - $userId');
    } catch (e) {
      debugPrint('DeepLinkService: Error sharing profile - $e');
      rethrow;
    }
  }

  /// Build share text for posts
  String _buildPostShareText(PostEntity? post, String shareUrl) {
    if (post == null) {
      return 'Check out this post on NEPIKA!\n\n$shareUrl';
    }

    final content = post.content.length > 100 
        ? '${post.content.substring(0, 100)}...' 
        : post.content;
    
    return '''Check out this post by ${post.username} on NEPIKA:

"$content"

Join the conversation: $shareUrl''';
  }

  /// Build share text for profiles
  String _buildProfileShareText(CommunityProfileEntity? profile, String shareUrl) {
    if (profile == null) {
      return 'Check out this profile on NEPIKA!\n\n$shareUrl';
    }

    final bio = profile.bio != null && profile.bio!.isNotEmpty 
        ? '\n\n"${profile.bio}"' 
        : '';
    
    return '''Check out ${profile.username} on NEPIKA!$bio

👥 ${profile.followersCount} followers
📝 ${profile.postsCount} posts

Follow them: $shareUrl''';
  }

  /// Store pending deep link for after authentication
  Future<void> storePendingDeepLink(String deepLink) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingDeepLinkKey, deepLink);
      debugPrint('DeepLinkService: Stored pending deep link - $deepLink');
    } catch (e) {
      debugPrint('DeepLinkService: Error storing pending deep link - $e');
    }
  }

  /// Get pending deep link
  Future<String?> getPendingDeepLink() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deepLink = prefs.getString(_pendingDeepLinkKey);
      debugPrint('DeepLinkService: Retrieved pending deep link - $deepLink');
      return deepLink;
    } catch (e) {
      debugPrint('DeepLinkService: Error getting pending deep link - $e');
      return null;
    }
  }

  /// Clear pending deep link
  Future<void> clearPendingDeepLink() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingDeepLinkKey);
      debugPrint('DeepLinkService: Cleared pending deep link');
    } catch (e) {
      debugPrint('DeepLinkService: Error clearing pending deep link - $e');
    }
  }

  /// Track deep link analytics
  
  /// Track when a deep link is received
  Future<void> trackDeepLinkReceived(String url) async {
    await _trackAnalytics('deep_link_received', {'url': url});
  }

  /// Track when a deep link is opened
  Future<void> trackDeepLinkOpen(DeepLinkInfo deepLinkInfo) async {
    await _trackAnalytics('deep_link_opened', {
      'type': deepLinkInfo.type.name,
      'target_id': deepLinkInfo.targetId,
      'path': deepLinkInfo.path,
    });
  }

  /// Track when a post is shared
  Future<void> trackPostShared(String postId) async {
    await _trackAnalytics('post_shared', {'post_id': postId});
  }

  /// Track when a profile is shared
  Future<void> trackProfileShared(String userId) async {
    await _trackAnalytics('profile_shared', {'user_id': userId});
  }

  /// Internal analytics tracking
  Future<void> _trackAnalytics(String eventName, Map<String, String> parameters) async {
    try {
      // TODO: Integrate with Firebase Analytics when available
      // FirebaseAnalytics.instance.logEvent(
      //   name: eventName,
      //   parameters: parameters,
      // );
      
      // For now, store locally for debugging
      final prefs = await SharedPreferences.getInstance();
      final existingAnalytics = prefs.getStringList(_deepLinkAnalyticsKey) ?? [];
      
      final analyticsEntry = {
        'event': eventName,
        'parameters': parameters,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      existingAnalytics.add(analyticsEntry.toString());
      
      // Keep only last 100 entries
      if (existingAnalytics.length > 100) {
        existingAnalytics.removeRange(0, existingAnalytics.length - 100);
      }
      
      await prefs.setStringList(_deepLinkAnalyticsKey, existingAnalytics);
      
      debugPrint('DeepLinkService: Tracked analytics - $eventName: $parameters');
    } catch (e) {
      debugPrint('DeepLinkService: Error tracking analytics - $e');
    }
  }

  /// Get analytics data for debugging
  Future<List<String>> getAnalyticsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_deepLinkAnalyticsKey) ?? [];
    } catch (e) {
      debugPrint('DeepLinkService: Error getting analytics data - $e');
      return [];
    }
  }

  /// Check if the app can handle a specific URL
  bool canHandleUrl(String url) {
    try {
      final uri = Uri.parse(url);
      
      // Check if it's a nepika.com URL
      if (uri.host == 'nepika.com') {
        final pathSegments = uri.pathSegments;
        
        // Check for supported paths
        if (pathSegments.isNotEmpty && pathSegments[0] == 'community') {
          if (pathSegments.length >= 3) {
            return pathSegments[1] == 'post' || pathSegments[1] == 'profile';
          }
        }
      }
      
      // Check if it's a Firebase Dynamic Link
      if (uri.host == 'nepika.page.link') {
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('DeepLinkService: Error checking URL - $e');
      return false;
    }
  }

  /// Get deep link stream for listening to incoming links
  Stream<String>? get deepLinkStream => _deepLinkController?.stream;

  /// Extract metadata from URL for preview generation
  Future<Map<String, String?>> extractUrlMetadata(String url) async {
    try {
      final deepLinkInfo = AppRouter.parseDeepLink(url);
      
      if (deepLinkInfo == null) {
        return {'title': 'NEPIKA', 'description': 'Beauty and Skincare Community'};
      }
      
      switch (deepLinkInfo.type) {
        case DeepLinkType.post:
          return {
            'title': 'Post on NEPIKA',
            'description': 'Check out this post from the NEPIKA community',
            'type': 'post',
            'id': deepLinkInfo.targetId,
          };
        
        case DeepLinkType.profile:
          return {
            'title': 'User Profile on NEPIKA',
            'description': 'Check out this user profile on NEPIKA',
            'type': 'profile',
            'id': deepLinkInfo.targetId,
          };
      }
    } catch (e) {
      debugPrint('DeepLinkService: Error extracting URL metadata - $e');
      return {'title': 'NEPIKA', 'description': 'Beauty and Skincare Community'};
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _deepLinkController?.close();
    _deepLinkController = null;
    _isInitialized = false;
    debugPrint('DeepLinkService: Disposed');
  }
}