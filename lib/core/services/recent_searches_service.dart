import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/community/entities/community_entities.dart';

/// Service for managing recent search data in local storage
/// Saves user search results only when user visits their profile
class RecentSearchesService {
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;

  /// Save a user to recent searches when they visit their profile
  static Future<void> saveRecentSearch(UserSearchResultEntity user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentSearches = await getRecentSearches();
      
      // Remove if already exists to avoid duplicates
      recentSearches.removeWhere((search) => search.id == user.id);
      
      // Add to the beginning of the list
      recentSearches.insert(0, user);
      
      // Keep only the maximum number of recent searches
      if (recentSearches.length > _maxRecentSearches) {
        recentSearches.removeRange(_maxRecentSearches, recentSearches.length);
      }
      
      // Convert to JSON and save
      final jsonList = recentSearches.map((user) => _userToJson(user)).toList();
      await prefs.setString(_recentSearchesKey, jsonEncode(jsonList));
      
      debugPrint('RecentSearchesService: Saved recent search for user: ${user.username}');
    } catch (e) {
      debugPrint('RecentSearchesService: Error saving recent search: $e');
    }
  }

  /// Get all recent searches
  static Future<List<UserSearchResultEntity>> getRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_recentSearchesKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) => _userFromJson(json)).toList();
    } catch (e) {
      debugPrint('RecentSearchesService: Error getting recent searches: $e');
      return [];
    }
  }

  /// Remove a specific recent search
  static Future<void> removeRecentSearch(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentSearches = await getRecentSearches();
      
      recentSearches.removeWhere((search) => search.id == userId);
      
      // Save updated list
      final jsonList = recentSearches.map((user) => _userToJson(user)).toList();
      await prefs.setString(_recentSearchesKey, jsonEncode(jsonList));
      
      debugPrint('RecentSearchesService: Removed recent search for user: $userId');
    } catch (e) {
      debugPrint('RecentSearchesService: Error removing recent search: $e');
    }
  }

  /// Clear all recent searches
  static Future<void> clearAllRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
      debugPrint('RecentSearchesService: Cleared all recent searches');
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
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      followersCount: json['followersCount'] ?? 0,
      isFollowing: json['isFollowing'] ?? false,
      isVerified: json['isVerified'] ?? false,
      isSelf: json['isSelf'] ?? false,
      createdAt: DateTime.tryParse(json['savedAt'] ?? '') ?? DateTime.now(),
    );
  }
}