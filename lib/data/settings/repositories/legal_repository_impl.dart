import '../../../../core/error/failures.dart';
import '../../../../core/utils/either.dart';
import '../../../../domain/settings/entities/legal_document_entity.dart';
import '../../../../domain/settings/repositories/legal_repository.dart';
import '../datasources/legal_remote_data_source.dart';

class LegalRepositoryImpl implements LegalRepository {
  final LegalRemoteDataSource remoteDataSource;

  LegalRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<LegalDocumentEntity>> getActiveLegalDocument(String type) async {
    try {
      final result = await remoteDataSource.getActiveLegalDocument(type);
      return success(result);
    } catch (e) {
      return failure(ServerFailure(message: 'Failed to fetch $type: ${e.toString()}'));
    }
  }
}
