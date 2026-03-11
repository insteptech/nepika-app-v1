import '../../../core/error/failures.dart';
import '../../../core/utils/either.dart';
import '../entities/legal_document_entity.dart';

abstract class LegalRepository {
  Future<Result<LegalDocumentEntity>> getActiveLegalDocument(String type);
}
