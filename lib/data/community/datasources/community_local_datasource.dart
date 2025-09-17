import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/community/entities/community_entities.dart';

abstract class CommunityLocalDataSource {
  Future<void> cachePost(PostEntity post);
  Future<void> cachePosts(List<PostEntity> posts);
  Future<List<PostEntity>> getCachedPosts();
  Future<PostEntity?> getCachedPost(String postId);
  Future<void> updateCachedPost(PostEntity post);
  Future<void> removeCachedPost(String postId);
  
  Future<void> cacheComments(String postId, List<PostEntity> comments);
  Future<List<PostEntity>> getCachedComments(String postId);
  Future<void> addCachedComment(String postId, PostEntity comment);
  
  Future<void> cacheUserProfile(CommunityProfileEntity profile);
  Future<CommunityProfileEntity?> getCachedUserProfile(String userId);
  Future<void> updateCachedUserProfile(CommunityProfileEntity profile);
  
  Future<void> cacheFollowStatus(String userId, bool isFollowing);
  Future<bool?> getCachedFollowStatus(String userId);
  
  Future<void> cacheBlockStatus(String userId, bool isBlocked);
  Future<bool?> getCachedBlockStatus(String userId);
  
  Future<void> cacheLikeStatus(String postId, bool isLiked, int likeCount);
  Future<Map<String, dynamic>?> getCachedLikeStatus(String postId);
  
  Future<void> clearAllCache();
  Future<void> clearPostsCache();
  Future<void> clearCommentsCache();
  Future<void> clearProfilesCache();
}

class CommunityLocalDataSourceImpl implements CommunityLocalDataSource {
  static const String _postsKey = 'community_posts';
  static const String _commentsKey = 'community_comments_';
  static const String _profilesKey = 'community_profiles_';
  static const String _followStatusKey = 'follow_status_';
  static const String _blockStatusKey = 'block_status_';
  static const String _likeStatusKey = 'like_status_';
  
  @override
  Future<void> cachePost(PostEntity post) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedPosts = await getCachedPosts();
    
    final existingIndex = cachedPosts.indexWhere((p) => p.id == post.id);
    if (existingIndex >= 0) {
      cachedPosts[existingIndex] = post;
    } else {
      cachedPosts.insert(0, post);
    }
    
    // Keep only latest 100 posts to prevent storage overflow
    if (cachedPosts.length > 100) {
      cachedPosts.removeRange(100, cachedPosts.length);
    }
    
    final postsJson = cachedPosts.map((p) => p.toJson()).toList();
    await prefs.setString(_postsKey, jsonEncode(postsJson));
  }
  
  @override
  Future<void> cachePosts(List<PostEntity> posts) async {
    final prefs = await SharedPreferences.getInstance();
    final postsJson = posts.map((p) => p.toJson()).toList();
    await prefs.setString(_postsKey, jsonEncode(postsJson));
  }
  
  @override
  Future<List<PostEntity>> getCachedPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final postsString = prefs.getString(_postsKey);
    
    if (postsString == null) return [];
    
    try {
      final postsJson = jsonDecode(postsString) as List;
      return postsJson.map((json) => PostEntity.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<PostEntity?> getCachedPost(String postId) async {
    final posts = await getCachedPosts();
    try {
      return posts.firstWhere((post) => post.id == postId);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> updateCachedPost(PostEntity post) async {
    await cachePost(post);
  }
  
  @override
  Future<void> removeCachedPost(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedPosts = await getCachedPosts();
    
    cachedPosts.removeWhere((post) => post.id == postId);
    
    final postsJson = cachedPosts.map((p) => p.toJson()).toList();
    await prefs.setString(_postsKey, jsonEncode(postsJson));
  }
  
  @override
  Future<void> cacheComments(String postId, List<PostEntity> comments) async {
    final prefs = await SharedPreferences.getInstance();
    final commentsJson = comments.map((c) => c.toJson()).toList();
    await prefs.setString('$_commentsKey$postId', jsonEncode(commentsJson));
  }
  
  @override
  Future<List<PostEntity>> getCachedComments(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final commentsString = prefs.getString('$_commentsKey$postId');
    
    if (commentsString == null) return [];
    
    try {
      final commentsJson = jsonDecode(commentsString) as List;
      return commentsJson.map((json) => PostEntity.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> addCachedComment(String postId, PostEntity comment) async {
    final cachedComments = await getCachedComments(postId);
    cachedComments.insert(0, comment);
    
    // Keep only latest 50 comments per post
    if (cachedComments.length > 50) {
      cachedComments.removeRange(50, cachedComments.length);
    }
    
    await cacheComments(postId, cachedComments);
  }
  
  @override
  Future<void> cacheUserProfile(CommunityProfileEntity profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_profilesKey${profile.userId}', jsonEncode(profile.toJson()));
  }
  
  @override
  Future<CommunityProfileEntity?> getCachedUserProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final profileString = prefs.getString('$_profilesKey$userId');
    
    if (profileString == null) return null;
    
    try {
      final profileJson = jsonDecode(profileString);
      return CommunityProfileEntity.fromJson(profileJson);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> updateCachedUserProfile(CommunityProfileEntity profile) async {
    await cacheUserProfile(profile);
  }
  
  @override
  Future<void> cacheFollowStatus(String userId, bool isFollowing) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_followStatusKey$userId', isFollowing);
  }
  
  @override
  Future<bool?> getCachedFollowStatus(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_followStatusKey$userId');
  }
  
  @override
  Future<void> cacheBlockStatus(String userId, bool isBlocked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_blockStatusKey$userId', isBlocked);
  }
  
  @override
  Future<bool?> getCachedBlockStatus(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_blockStatusKey$userId');
  }
  
  @override
  Future<void> cacheLikeStatus(String postId, bool isLiked, int likeCount) async {
    final prefs = await SharedPreferences.getInstance();
    final likeData = {
      'is_liked': isLiked,
      'like_count': likeCount,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString('$_likeStatusKey$postId', jsonEncode(likeData));
  }
  
  @override
  Future<Map<String, dynamic>?> getCachedLikeStatus(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final likeString = prefs.getString('$_likeStatusKey$postId');
    
    if (likeString == null) return null;
    
    try {
      return jsonDecode(likeString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_postsKey) ||
          key.startsWith(_commentsKey) ||
          key.startsWith(_profilesKey) ||
          key.startsWith(_followStatusKey) ||
          key.startsWith(_blockStatusKey) ||
          key.startsWith(_likeStatusKey)) {
        await prefs.remove(key);
      }
    }
  }
  
  @override
  Future<void> clearPostsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_postsKey);
  }
  
  @override
  Future<void> clearCommentsCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_commentsKey)) {
        await prefs.remove(key);
      }
    }
  }
  
  @override
  Future<void> clearProfilesCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_profilesKey)) {
        await prefs.remove(key);
      }
    }
  }
}