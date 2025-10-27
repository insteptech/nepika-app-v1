import '../entities/community_entities.dart';
import '../repositories/community_repository.dart';

class AcceptFollowRequestUseCase {
  final CommunityRepository repository;

  AcceptFollowRequestUseCase(this.repository);

  Future<FollowRequestActionEntity> call({
    required String token,
    required String requestId,
  }) async {
    return await repository.acceptFollowRequest(
      token: token,
      requestId: requestId,
    );
  }
}