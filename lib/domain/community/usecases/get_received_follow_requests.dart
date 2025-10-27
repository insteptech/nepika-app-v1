import '../entities/community_entities.dart';
import '../repositories/community_repository.dart';

class GetReceivedFollowRequestsUseCase {
  final CommunityRepository repository;

  GetReceivedFollowRequestsUseCase(this.repository);

  Future<FollowRequestsListEntity> call({
    required String token,
    int page = 1,
    int pageSize = 20,
  }) async {
    return await repository.getReceivedFollowRequests(
      token: token,
      page: page,
      pageSize: pageSize,
    );
  }
}