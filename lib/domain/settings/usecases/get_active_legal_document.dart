import '../../../core/error/failures.dart';
import '../../../core/utils/either.dart';
import '../entities/legal_document_entity.dart';
import '../repositories/legal_repository.dart';

class GetActiveLegalDocumentUseCase {
  final LegalRepository repository;

  GetActiveLegalDocumentUseCase(this.repository);

  Future<Result<LegalDocumentEntity>> call(String type) async {
    return await repository.getActiveLegalDocument(type);
  }
}
