import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/community/entities/community_entities.dart';

/// Web Fallback Service - Generates web fallback page data for server-side rendering
/// This service prepares data that would be used by a backend to render the HTML templates
class WebFallbackService {
  static final WebFallbackService _instance = WebFallbackService._internal();
  factory WebFallbackService() => _instance;
  WebFallbackService._internal();

  static const String _baseUrl = 'https://nepika.com';
  static const String _defaultImageUrl = '$_baseUrl/assets/images/nepika_logo.png';

  /// Generate fallback data for a post
  Future<Map<String, String>> generatePostFallbackData({
    required String postId,
    PostEntity? post,
    CommunityProfileEntity? author,
  }) async {
    try {
      // Default values
      final postTitle = post?.content != null && post!.content.isNotEmpty
          ? '${post.content.split(' ').take(8).join(' ')}${post.content.split(' ').length > 8 ? '...' : ''}'
          : 'Post on NEPIKA';
      
      final postContent = post?.content ?? 'Check out this post from the NEPIKA community';
      final username = author?.username ?? post?.username ?? 'NEPIKA User';
      final avatarUrl = author?.profileImageUrl ?? post?.userAvatar ?? _defaultImageUrl;
      final postImageUrl = _defaultImageUrl; // PostEntity doesn't have imageUrl field
      final timestamp = post?.createdAt != null 
          ? _formatTimestamp(post!.createdAt)
          : 'Recently';
      
      // Generate avatar initial
      final avatarInitial = username.isNotEmpty ? username[0].toUpperCase() : 'U';
      
      // Format stats
      final likes = post?.likeCount ?? 0;
      final comments = post?.commentCount ?? 0;
      
      return {
        'POST_ID': postId,
        'POST_TITLE': postTitle,
        'POST_CONTENT': _truncateText(postContent, 150),
        'POST_USERNAME': username,
        'POST_AVATAR_URL': avatarUrl,
        'POST_AVATAR_INITIAL': avatarInitial,
        'POST_IMAGE_URL': postImageUrl,
        'POST_IMAGE_CLASS': postImageUrl != _defaultImageUrl ? 'has-image' : '',
        'POST_TIMESTAMP': timestamp,
        'POST_LIKES': _formatNumber(likes),
        'POST_COMMENTS': _formatNumber(comments),
        'DEEP_LINK_PATH': 'community/post/$postId',
        'PAGE_TITLE': postTitle,
        'PAGE_DESCRIPTION': 'Check out this post by $username on NEPIKA - $postContent',
      };
    } catch (e) {
      debugPrint('WebFallbackService: Error generating post fallback data - $e');
      return _getDefaultPostData(postId);
    }
  }

  /// Generate fallback data for a profile
  Future<Map<String, String>> generateProfileFallbackData({
    required String userId,
    CommunityProfileEntity? profile,
  }) async {
    try {
      // Default values
      final username = profile?.username ?? 'NEPIKA User';
      final handle = profile?.username ?? 'user';
      final bio = profile?.bio ?? 'Beauty and skincare enthusiast on NEPIKA';
      final profileImageUrl = profile?.profileImageUrl ?? _defaultImageUrl;
      final postsCount = profile?.postsCount ?? 0;
      final followersCount = profile?.followersCount ?? 0;
      final followingCount = profile?.followingCount ?? 0;
      
      // Generate avatar initial
      final avatarInitial = username.isNotEmpty ? username[0].toUpperCase() : 'U';
      
      // Generate badges
      final badges = _generateProfileBadges(profile);
      
      return {
        'PROFILE_ID': userId,
        'PROFILE_USERNAME': username,
        'PROFILE_HANDLE': handle,
        'PROFILE_BIO': _truncateText(bio, 120),
        'PROFILE_IMAGE_URL': profileImageUrl,
        'PROFILE_AVATAR_INITIAL': avatarInitial,
        'PROFILE_POSTS': _formatNumber(postsCount),
        'PROFILE_FOLLOWERS': _formatNumber(followersCount),
        'PROFILE_FOLLOWING': _formatNumber(followingCount),
        'PROFILE_BADGES': badges,
        'DEEP_LINK_PATH': 'community/profile/$userId',
        'PAGE_TITLE': '$username on NEPIKA',
        'PAGE_DESCRIPTION': 'Follow $username on NEPIKA for beauty and skincare tips. $bio',
      };
    } catch (e) {
      debugPrint('WebFallbackService: Error generating profile fallback data - $e');
      return _getDefaultProfileData(userId);
    }
  }

  /// Generate Open Graph metadata for a post
  Map<String, String> generatePostOpenGraphTags({
    required String postId,
    PostEntity? post,
    CommunityProfileEntity? author,
  }) {
    final postTitle = post?.content != null && post!.content.isNotEmpty
        ? '${post.content.split(' ').take(8).join(' ')}${post.content.split(' ').length > 8 ? '...' : ''}'
        : 'Post on NEPIKA';
    
    final postContent = post?.content ?? 'Check out this post from the NEPIKA community';
    final username = author?.username ?? post?.username ?? 'NEPIKA User';
    final postImageUrl = _defaultImageUrl; // PostEntity doesn't have imageUrl field
    
    return {
      'og:title': '$postTitle | NEPIKA',
      'og:description': _truncateText(postContent, 160),
      'og:image': postImageUrl,
      'og:url': '$_baseUrl/community/post/$postId',
      'og:type': 'article',
      'article:author': username,
      'twitter:card': 'summary_large_image',
      'twitter:title': '$postTitle | NEPIKA',
      'twitter:description': _truncateText(postContent, 160),
      'twitter:image': postImageUrl,
      'twitter:creator': '@$username',
    };
  }

  /// Generate Open Graph metadata for a profile
  Map<String, String> generateProfileOpenGraphTags({
    required String userId,
    CommunityProfileEntity? profile,
  }) {
    final username = profile?.username ?? 'NEPIKA User';
    final bio = profile?.bio ?? 'Beauty and skincare enthusiast on NEPIKA';
    final profileImageUrl = profile?.profileImageUrl ?? _defaultImageUrl;
    
    return {
      'og:title': '$username on NEPIKA',
      'og:description': _truncateText(bio, 160),
      'og:image': profileImageUrl,
      'og:url': '$_baseUrl/community/profile/$userId',
      'og:type': 'profile',
      'profile:username': username,
      'twitter:card': 'summary_large_image',
      'twitter:title': '$username on NEPIKA',
      'twitter:description': _truncateText(bio, 160),
      'twitter:image': profileImageUrl,
      'twitter:creator': '@$username',
    };
  }

  /// Generate structured data (JSON-LD) for a post
  Map<String, dynamic> generatePostStructuredData({
    required String postId,
    PostEntity? post,
    CommunityProfileEntity? author,
  }) {
    final postTitle = post?.content != null && post!.content.isNotEmpty
        ? '${post.content.split(' ').take(8).join(' ')}${post.content.split(' ').length > 8 ? '...' : ''}'
        : 'Post on NEPIKA';
    
    final postContent = post?.content ?? 'Check out this post from the NEPIKA community';
    final username = author?.username ?? post?.username ?? 'NEPIKA User';
    final postImageUrl = _defaultImageUrl; // PostEntity doesn't have imageUrl field
    final createdAt = post?.createdAt ?? DateTime.now();
    
    return {
      '@context': 'https://schema.org',
      '@type': 'SocialMediaPosting',
      'headline': postTitle,
      'articleBody': postContent,
      'image': postImageUrl,
      'url': '$_baseUrl/community/post/$postId',
      'datePublished': createdAt.toIso8601String(),
      'author': {
        '@type': 'Person',
        'name': username,
        'url': '$_baseUrl/community/profile/${author?.id ?? 'unknown'}',
      },
      'publisher': {
        '@type': 'Organization',
        'name': 'NEPIKA',
        'url': _baseUrl,
        'logo': _defaultImageUrl,
      },
      'mainEntityOfPage': {
        '@type': 'WebPage',
        '@id': '$_baseUrl/community/post/$postId',
      },
    };
  }

  /// Generate structured data (JSON-LD) for a profile
  Map<String, dynamic> generateProfileStructuredData({
    required String userId,
    CommunityProfileEntity? profile,
  }) {
    final username = profile?.username ?? 'NEPIKA User';
    final bio = profile?.bio ?? 'Beauty and skincare enthusiast on NEPIKA';
    final profileImageUrl = profile?.profileImageUrl ?? _defaultImageUrl;
    
    return {
      '@context': 'https://schema.org',
      '@type': 'Person',
      'name': username,
      'description': bio,
      'image': profileImageUrl,
      'url': '$_baseUrl/community/profile/$userId',
      'sameAs': '$_baseUrl/community/profile/$userId',
      'worksFor': {
        '@type': 'Organization',
        'name': 'NEPIKA',
        'url': _baseUrl,
      },
    };
  }

  /// Cache fallback data for faster retrieval
  Future<void> cacheFallbackData(String key, Map<String, String> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(data);
      await prefs.setString('fallback_cache_$key', jsonData);
      
      // Also store timestamp for cache expiry
      await prefs.setInt('fallback_cache_${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('WebFallbackService: Error caching fallback data - $e');
    }
  }

  /// Retrieve cached fallback data
  Future<Map<String, String>?> getCachedFallbackData(String key, {int maxAgeMinutes = 30}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString('fallback_cache_$key');
      final timestamp = prefs.getInt('fallback_cache_${key}_timestamp');
      
      if (jsonData != null && timestamp != null) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        final maxAge = maxAgeMinutes * 60 * 1000; // Convert to milliseconds
        
        if (age < maxAge) {
          return Map<String, String>.from(jsonDecode(jsonData));
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('WebFallbackService: Error retrieving cached fallback data - $e');
      return null;
    }
  }

  /// Helper methods
  
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _generateProfileBadges(CommunityProfileEntity? profile) {
    if (profile == null) return '';
    
    final badges = <String>[];
    
    // Add verification badge if verified
    if (profile.isVerified == true) {
      badges.add('<span class="badge verified">✓ Verified</span>');
    }
    
    // Add expert badge based on follower count
    if (profile.followersCount > 1000) {
      badges.add('<span class="badge expert">⭐ Expert</span>');
    }
    
    // Add active user badge based on post count
    if (profile.postsCount > 50) {
      badges.add('<span class="badge">📝 Active</span>');
    }
    
    return badges.join('');
  }

  Map<String, String> _getDefaultPostData(String postId) {
    return {
      'POST_ID': postId,
      'POST_TITLE': 'Post on NEPIKA',
      'POST_CONTENT': 'Check out this post from the NEPIKA beauty and skincare community',
      'POST_USERNAME': 'NEPIKA User',
      'POST_AVATAR_URL': _defaultImageUrl,
      'POST_AVATAR_INITIAL': 'U',
      'POST_IMAGE_URL': _defaultImageUrl,
      'POST_IMAGE_CLASS': '',
      'POST_TIMESTAMP': 'Recently',
      'POST_LIKES': '0',
      'POST_COMMENTS': '0',
      'DEEP_LINK_PATH': 'community/post/$postId',
      'PAGE_TITLE': 'Post on NEPIKA',
      'PAGE_DESCRIPTION': 'Check out this post from the NEPIKA beauty and skincare community',
    };
  }

  Map<String, String> _getDefaultProfileData(String userId) {
    return {
      'PROFILE_ID': userId,
      'PROFILE_USERNAME': 'NEPIKA User',
      'PROFILE_HANDLE': 'user',
      'PROFILE_BIO': 'Beauty and skincare enthusiast on NEPIKA',
      'PROFILE_IMAGE_URL': _defaultImageUrl,
      'PROFILE_AVATAR_INITIAL': 'U',
      'PROFILE_POSTS': '0',
      'PROFILE_FOLLOWERS': '0',
      'PROFILE_FOLLOWING': '0',
      'PROFILE_BADGES': '',
      'DEEP_LINK_PATH': 'community/profile/$userId',
      'PAGE_TITLE': 'NEPIKA User',
      'PAGE_DESCRIPTION': 'Follow this user on NEPIKA for beauty and skincare tips',
    };
  }
}