import '../../../core/utils/either.dart';
import '../../../core/error/failures.dart';
import '../entities/delete_account_entities.dart';
import '../repositories/delete_account_repository.dart';

/// Use case for deleting user account
class DeleteAccountUseCase {
  final DeleteAccountRepository _repository;

  DeleteAccountUseCase(this._repository);

  Future<Either<Failure, DeleteAccountResponseEntity>> call({
    required String token,
    required DeleteAccountRequestEntity request,
  }) async {
    return await _repository.deleteAccount(
      token: token,
      request: request,
    );
  }
}