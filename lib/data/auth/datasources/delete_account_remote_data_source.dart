import 'package:dio/dio.dart';
import 'package:nepika/features/settings/bloc/delete_account_state.dart';
import '../../../core/api_base.dart';
import '../models/delete_account_models.dart';

/// Remote data source for account deletion API calls
abstract class DeleteAccountRemoteDataSource {
  Future<List<DeleteReasonModel>> getDeleteReasons();
  Future<DeleteAccountResponseModel> deleteAccount({
    required String token,
    required DeleteAccountRequestModel request,
  });
}

/// Implementation of DeleteAccountRemoteDataSource
class DeleteAccountRemoteDataSourceImpl implements DeleteAccountRemoteDataSource {
  final ApiBase _apiBase;

  DeleteAccountRemoteDataSourceImpl(this._apiBase);

  @override
  Future<List<DeleteReasonModel>> getDeleteReasons() async {
    try {
      final Response response = await _apiBase.request(
        path: '/auth/users/account-delete-reasons',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        final List<dynamic> reasons = responseData['data']['reasons'];
        
        return reasons
            .map((reason) => DeleteReasonModel.fromJson(reason))
            .toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to fetch delete reasons',
        );
      }
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/account-delete-reasons'),
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  @override
  Future<DeleteAccountResponseModel> deleteAccount({
    required String token,
    required DeleteAccountRequestModel request,
  }) async {
    try {
      final Response response = await _apiBase.request(
        path: '/auth/users/delete-account-request',
        method: 'POST',
        body: request.toJson(),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        return DeleteAccountResponseModel.fromJson(responseData['data']);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to delete account',
        );
      }
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/delete-account-request'),
        message: 'Network error: ${e.toString()}',
      );
    }
  }
}