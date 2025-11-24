import '../../../core/utils/either.dart';
import '../../../core/error/failures.dart';
import '../entities/delete_account_entities.dart';
import '../repositories/delete_account_repository.dart';

/// Use case for getting delete account reasons
class GetDeleteReasonsUseCase {
  final DeleteAccountRepository _repository;

  GetDeleteReasonsUseCase(this._repository);

  Future<Either<Failure, List<DeleteReasonEntity>>> call() async {
    return await _repository.getDeleteReasons();
  }
}