import 'package:dio/dio.dart';
import '../../../core/utils/either.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/error/failures.dart';
import '../../../domain/auth/entities/delete_account_entities.dart';
import '../../../domain/auth/repositories/delete_account_repository.dart';
import '../datasources/delete_account_remote_data_source.dart';
import '../models/delete_account_models.dart';

/// Implementation of DeleteAccountRepository
class DeleteAccountRepositoryImpl implements DeleteAccountRepository {
  final DeleteAccountRemoteDataSource _remoteDataSource;

  DeleteAccountRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<DeleteReasonEntity>>> getDeleteReasons() async {
    try {
      final List<DeleteReasonModel> reasons = await _remoteDataSource.getDeleteReasons();
      return Right(reasons);
    } catch (e) {
      final failure = ErrorHandler.handleError(e);
      return Left(failure);
    }
  }

  @override
  Future<Either<Failure, DeleteAccountResponseEntity>> deleteAccount({
    required String token,
    required DeleteAccountRequestEntity request,
  }) async {
    try {
      final DeleteAccountRequestModel requestModel = 
          DeleteAccountRequestModel.fromEntity(request);
      
      final DeleteAccountResponseModel response = 
          await _remoteDataSource.deleteAccount(
        token: token,
        request: requestModel,
      );
      
      return Right(response);
    } catch (e) {
      final failure = ErrorHandler.handleError(e);
      return Left(failure);
    }
  }
}