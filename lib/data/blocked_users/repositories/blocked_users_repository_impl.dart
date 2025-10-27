import 'package:flutter/foundation.dart';
import '../../../core/api_base.dart';
import '../../../domain/blocked_users/entities/blocked_user_entities.dart';
import '../../../domain/blocked_users/repositories/blocked_users_repository.dart';

class BlockedUsersRepositoryImpl implements BlockedUsersRepository {
  final ApiBase _apiBase;

  BlockedUsersRepositoryImpl(this._apiBase);

  @override
  Future<BlockedUsersResponseEntity> getBlockedUsers({
    required String token,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      debugPrint('BlockedUsersRepository: Fetching blocked users - page: $page, size: $pageSize');
      
      final response = await _apiBase.request(
        path: '/community/blocks',
        method: 'GET',
        query: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          final data = responseData['data'] as Map<String, dynamic>;
          debugPrint('BlockedUsersRepository: Successfully fetched ${data['total']} blocked users');
          return BlockedUsersResponseEntity.fromJson(data);
        } else {
          throw Exception('API returned success: false - ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to get blocked users: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('BlockedUsersRepository: Error fetching blocked users: $e');
      rethrow;
    }
  }

  @override
  Future<bool> unblockUser({
    required String token,
    required String userId,
  }) async {
    try {
      debugPrint('BlockedUsersRepository: Unblocking user: $userId');
      
      final response = await _apiBase.request(
        path: '/community/block/$userId',
        method: 'DELETE',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          debugPrint('BlockedUsersRepository: Successfully unblocked user: $userId');
          return true;
        } else {
          debugPrint('BlockedUsersRepository: Failed to unblock user: ${responseData['message']}');
          return false;
        }
      } else {
        debugPrint('BlockedUsersRepository: Unblock failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('BlockedUsersRepository: Error unblocking user: $e');
      return false;
    }
  }

  @override
  Future<bool> blockUser({
    required String token,
    required String userId,
  }) async {
    try {
      debugPrint('BlockedUsersRepository: Blocking user: $userId');
      
      final response = await _apiBase.request(
        path: '/community/block',
        method: 'POST',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: {
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          debugPrint('BlockedUsersRepository: Successfully blocked user: $userId');
          return true;
        } else {
          debugPrint('BlockedUsersRepository: Failed to block user: ${responseData['message']}');
          return false;
        }
      } else {
        debugPrint('BlockedUsersRepository: Block failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('BlockedUsersRepository: Error blocking user: $e');
      return false;
    }
  }

  @override
  Future<bool> isUserBlocked({
    required String token,
    required String userId,
  }) async {
    try {
      debugPrint('BlockedUsersRepository: Checking block status for user: $userId');
      
      final response = await _apiBase.request(
        path: '/community/block/status/$userId',
        method: 'GET',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true) {
          final isBlocked = responseData['data']?['is_blocked'] == true;
          debugPrint('BlockedUsersRepository: User $userId is ${isBlocked ? 'blocked' : 'not blocked'}');
          return isBlocked;
        }
      }
      return false;
    } catch (e) {
      debugPrint('BlockedUsersRepository: Error checking block status: $e');
      return false;
    }
  }
}