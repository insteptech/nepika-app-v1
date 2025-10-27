import '../entities/community_entities.dart';
import '../repositories/community_repository.dart';

class CancelFollowRequestUseCase {
  final CommunityRepository repository;

  CancelFollowRequestUseCase(this.repository);

  Future<FollowRequestActionEntity> call({
    required String token,
    required String targetUserId,
  }) async {
    return await repository.cancelFollowRequest(
      token: token,
      targetUserId: targetUserId,
    );
  }
}