import 'package:dio/dio.dart';
import '../../../../core/api_base.dart';
import '../../../../core/config/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/app_logger.dart';

abstract class FeedbackRemoteDataSource {
  Future<void> submitFeedback({
    required String text,
    int? rating,
  });
}

class FeedbackRemoteDataSourceImpl implements FeedbackRemoteDataSource {
  final ApiBase apiBase;

  FeedbackRemoteDataSourceImpl(this.apiBase);

  @override
  Future<void> submitFeedback({
    required String text,
    int? rating,
  }) async {
    try {
      final response = await apiBase.request(
        path: ApiEndpoints.feedback,
        method: 'POST',
        body: {
          'feedback_text': text,
          if (rating != null) 'rating': rating,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return;
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to submit feedback',
          code: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Feedback Submission Error', error: e);
      throw ServerException(
        message: e.response?.data['message'] ?? e.message ?? 'Network Error',
        code: e.response?.statusCode,
      );
    } catch (e) {
      AppLogger.error('Feedback Unexpected Error', error: e);
      throw const ServerException(message: 'Unexpected error occurred');
    }
  }
}
