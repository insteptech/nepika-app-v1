import '../entities/blocked_user_entities.dart';

/// Repository interface for blocked users management
abstract class BlockedUsersRepository {
  /// Get paginated list of blocked users
  Future<BlockedUsersResponseEntity> getBlockedUsers({
    required String token,
    int page = 1,
    int pageSize = 20,
  });

  /// Unblock a user by their user ID
  Future<bool> unblockUser({
    required String token,
    required String userId,
  });

  /// Block a user by their user ID
  Future<bool> blockUser({
    required String token,
    required String userId,
  });

  /// Check if a user is blocked
  Future<bool> isUserBlocked({
    required String token,
    required String userId,
  });
}