import 'package:dio/dio.dart';
import '../../../../core/api_base.dart';
import '../../../../core/config/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/faq_model.dart';
import '../../../../core/utils/app_logger.dart';

abstract class FaqRemoteDataSource {
  Future<List<FaqModel>> getFaqs();
}

class FaqRemoteDataSourceImpl implements FaqRemoteDataSource {
  final ApiBase apiBase;

  FaqRemoteDataSourceImpl(this.apiBase);

  @override
  Future<List<FaqModel>> getFaqs() async {
    try {
      final response = await apiBase.request(
        path: ApiEndpoints.faqs,
        method: 'GET',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> faqsJson = response.data['data']['faqs'];
        return faqsJson.map((json) => FaqModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to load FAQs',
          code: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('FAQ Fetch Error', error: e);
      throw ServerException(
        message: e.response?.data['message'] ?? e.message ?? 'Network Error',
        code: e.response?.statusCode,
      );
    } catch (e) {
      AppLogger.error('FAQ Unexpected Error', error: e);
      throw const ServerException(message: 'Unexpected error occurred');
    }
  }
}
