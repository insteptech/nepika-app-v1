import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/community/entities/community_entities.dart';
import '../../core/config/constants/app_constants.dart';

/// Service for managing recent search data in local storage
/// Saves user search results in user-isolated SharedPreferences
class RecentSearchesService {
  static const int _maxRecentSearches = 10;

  /// Generate a unique storage key for the current logged-in user
  static Future<String> _getStorageKey() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString(AppConstants.userDataKey);
    if (userDataStr != null) {
      try {
        final userData = jsonDecode(userDataStr);
        final userId = userData['id'];
        if (userId != null) {
          return 'recent_searches_$userId';
        }
      } catch (e) {
        debugPrint('RecentSearchesService: Error parsing user data: $e');
      }
    }
    return 'recent_searches_anonymous';
  }

  /// Save a user to recent searches when they visit their profile
  static Future<void> saveRecentSearch(UserSearchResultEntity user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getStorageKey();
      final recentSearches = await getRecentSearches();
      
      // Remove if already exists to avoid duplicates (moves it to the top)
      recentSearches.removeWhere((search) => search.id == user.id);
      
      // Add to the beginning of the list
      recentSearches.insert(0, user);
      
      // Keep only the maximum number of recent searches
      if (recentSearches.length > _maxRecentSearches) {
        recentSearches.removeRange(_maxRecentSearches, recentSearches.length);
      }
      
      // Convert to JSON and save
      final jsonList = recentSearches.map((u) => _userToJson(u)).toList();
      await prefs.setString(key, jsonEncode(jsonList));
      
      debugPrint('RecentSearchesService: Saved recent search for user: ${user.username} under key: $key');
    } catch (e) {
      debugPrint('RecentSearchesService: Error saving recent search: $e');
    }
  }

  /// Get all recent searches for the logged-in user
  static Future<List<UserSearchResultEntity>> getRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getStorageKey();
      final jsonString = prefs.getString(key);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) => _userFromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('RecentSearchesService: Error getting recent searches: $e');
      return [];
    }
  }

  /// Remove a specific recent search
  static Future<void> removeRecentSearch(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getStorageKey();
      final recentSearches = await getRecentSearches();
      
      recentSearches.removeWhere((search) => search.id == userId);
      
      // Save updated list
      final jsonList = recentSearches.map((user) => _userToJson(user)).toList();
      await prefs.setString(key, jsonEncode(jsonList));
      
      debugPrint('RecentSearchesService: Removed recent search for user: $userId');
    } catch (e) {
      debugPrint('RecentSearchesService: Error removing recent search: $e');
    }
  }

  /// Clear all recent searches for the logged-in user
  static Future<void> clearAllRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getStorageKey();
      await prefs.remove(key);
      debugPrint('RecentSearchesService: Cleared all recent searches under key: $key');
    } catch (e) {
      debugPrint('RecentSearchesService: Error clearing recent searches: $e');
    }
  }

  /// Check if there are any recent searches
  static Future<bool> hasRecentSearches() async {
    final recentSearches = await getRecentSearches();
    return recentSearches.isNotEmpty;
  }

  /// Convert UserSearchResultEntity to JSON
  static Map<String, dynamic> _userToJson(UserSearchResultEntity user) {
    return {
      'id': user.id,
      'username': user.username,
      'profileImageUrl': user.profileImageUrl,
      'followersCount': user.followersCount,
      'isFollowing': user.isFollowing,
      'isVerified': user.isVerified,
      'isSelf': user.isSelf,
      'savedAt': DateTime.now().toIso8601String(), // Track when it was saved
    };
  }

  /// Convert JSON to UserSearchResultEntity
  static UserSearchResultEntity _userFromJson(Map<String, dynamic> json) {
    return UserSearchResultEntity(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      followersCount: json['followersCount'] as int? ?? 0,
      isFollowing: json['isFollowing'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      isSelf: json['isSelf'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}