import 'package:dio/dio.dart';
import 'package:nepika/core/config/env.dart';
import 'package:nepika/core/error/exceptions.dart';
import 'package:injectable/injectable.dart';

@singleton
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(_createLoggingInterceptor());
    _dio.interceptors.add(_createErrorInterceptor());
  }

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? token,
  }) async {
    try {
      final options = Options(
        headers: {
          ...?headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? token,
  }) async {
    try {
      final options = Options(
        headers: {
          ...?headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? token,
  }) async {
    try {
      final options = Options(
        headers: {
          ...?headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? token,
  }) async {
    try {
      final options = Options(
        headers: {
          ...?headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const NetworkException(
            message: 'Connection timeout',
            code: 1002,
          );
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode ?? 500;
          final message = _extractErrorMessage(error.response?.data);
          return ServerException(
            message: message,
            code: statusCode,
          );
        case DioExceptionType.cancel:
          return const NetworkException(
            message: 'Request cancelled',
            code: 1003,
          );
        case DioExceptionType.connectionError:
          return const NetworkException(
            message: 'Connection error',
            code: 1004,
          );
        default:
          return const ServerException(
            message: 'Unknown error occurred',
            code: 9999,
          );
      }
    }
    return ServerException(
      message: error.toString(),
      code: 9999,
    );
  }

  String _extractErrorMessage(dynamic responseData) {
    try {
      if (responseData is Map<String, dynamic>) {
        return responseData['message'] ?? 
               responseData['error'] ?? 
               'An error occurred';
      }
      return 'An error occurred';
    } catch (e) {
      return 'An error occurred';
    }
  }

  Interceptor _createLoggingInterceptor() {
    return LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      requestHeader: false,
      responseHeader: false,
    );
  }

  Interceptor _createErrorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        // You can add global error handling here
        // For example, logout user on 401, show global error messages, etc.
        handler.next(error);
      },
    );
  }
}
