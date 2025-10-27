import '../entities/community_entities.dart';
import '../repositories/community_repository.dart';

class GetSentFollowRequestsUseCase {
  final CommunityRepository repository;

  GetSentFollowRequestsUseCase(this.repository);

  Future<FollowRequestsListEntity> call({
    required String token,
    int page = 1,
    int pageSize = 20,
  }) async {
    return await repository.getSentFollowRequests(
      token: token,
      page: page,
      pageSize: pageSize,
    );
  }
}