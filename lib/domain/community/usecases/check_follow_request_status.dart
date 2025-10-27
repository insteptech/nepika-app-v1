import '../entities/community_entities.dart';
import '../repositories/community_repository.dart';

class CheckFollowRequestStatusUseCase {
  final CommunityRepository repository;

  CheckFollowRequestStatusUseCase(this.repository);

  Future<FollowRequestStatusEntity> call({
    required String token,
    required String targetUserId,
  }) async {
    return await repository.checkFollowRequestStatus(
      token: token,
      targetUserId: targetUserId,
    );
  }
}