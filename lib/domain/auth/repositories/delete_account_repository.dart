import '../../../core/utils/either.dart';
import '../../../core/error/failures.dart';
import '../entities/delete_account_entities.dart';

/// Repository interface for account deletion operations
abstract class DeleteAccountRepository {
  /// Get list of available delete reasons
  /// Returns either a list of reasons or an error
  Future<Either<Failure, List<DeleteReasonEntity>>> getDeleteReasons();
  
  /// Submit delete account request
  /// Returns either success response or an error
  Future<Either<Failure, DeleteAccountResponseEntity>> deleteAccount({
    required String token,
    required DeleteAccountRequestEntity request,
  });
}