import '../models/legal_document_model.dart';
import '../../../../core/network/secure_api_client.dart';

abstract class LegalRemoteDataSource {
  Future<LegalDocumentModel> getActiveLegalDocument(String type);
}

class LegalRemoteDataSourceImpl implements LegalRemoteDataSource {
  final SecureApiClient _apiClient;

  LegalRemoteDataSourceImpl() : _apiClient = SecureApiClient.instance;

  @override
  Future<LegalDocumentModel> getActiveLegalDocument(String type) async {
    final result = await _apiClient.request(
        path: '/legal/public/$type',
        method: 'GET',
        skipAuth: true,
    );
    
    if (result.statusCode != 200 || result.data['success'] != true) {
      throw Exception(result.data['message'] ?? 'Failed to get legal document');
    }
    
    return LegalDocumentModel.fromJson(result.data['data']);
  }
}
