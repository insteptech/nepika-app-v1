import '../entities/community_entities.dart';
import '../repositories/community_repository.dart';

class DeclineFollowRequestUseCase {
  final CommunityRepository repository;

  DeclineFollowRequestUseCase(this.repository);

  Future<FollowRequestActionEntity> call({
    required String token,
    required String requestId,
  }) async {
    return await repository.declineFollowRequest(
      token: token,
      requestId: requestId,
    );
  }
}