import 'package:dio/dio.dart';
import '../../core/config/env.dart';

class ApiBase {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  Future<Response> request({
    String path = Env.baseUrl,
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    print('🚀🚀  Requesting: $method ${Env.baseUrl}/$path 🚀🚀');
    final mergedHeaders = {
      ..._dio.options.headers,
      if (headers != null) ...headers,
    };
    print('Headers: $mergedHeaders');
    try { 
      final response = await _dio.request(
        path,
        data: body,
        queryParameters: query, 
        options: Options(
          method: method.toUpperCase(),
          headers: mergedHeaders,
        ),
      );
      print('✅✅ Response [${response.statusCode}]: ${response.data} ✅✅');
      return response;
    } on DioException catch (e) {
      print('❌❌ Dio error: ${e.response?.statusCode} - ${e.message} ❌❌');
      rethrow;
    } catch (e) {
      print('❌❌ Unexpected error: $e ❌❌');
      rethrow;
    }
  }
}
