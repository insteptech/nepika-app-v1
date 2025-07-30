import 'package:dio/dio.dart';
import 'package:nepika/core/error/exceptions.dart';
import 'package:nepika/core/error/failures.dart';
import 'dart:io';

class ErrorHandler {
  static Failure handleError(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is SocketException) {
      return const NetworkFailure(
        message: 'No internet connection',
        code: 1001,
      );
    } else if (error is ServerException) {
      return ServerFailure(
        message: error.message,
        code: error.code,
      );
    } else if (error is NetworkException) {
      return NetworkFailure(
        message: error.message,
        code: error.code,
      );
    } else if (error is CacheException) {
      return CacheFailure(
        message: error.message,
        code: error.code,
      );
    } else if (error is ValidationException) {
      return ValidationFailure(
        message: error.message,
      );
    } else if (error is AuthException) {
      return AuthFailure(
        message: error.message,
        code: error.code,
      );
    } else {
      return ServerFailure(
        message: error.toString(),
        code: 9999,
      );
    }
  }

  static Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure(
          message: 'Connection timeout. Please try again.',
          code: 1002,
        );
      
      case DioExceptionType.badResponse:
        if (error.response?.statusCode != null) {
          final statusCode = error.response!.statusCode!;
          final message = _getErrorMessage(statusCode, error.response?.data);
          
          if (statusCode >= 400 && statusCode < 500) {
            return AuthFailure(message: message, code: statusCode);
          } else {
            return ServerFailure(message: message, code: statusCode);
          }
        }
        return const ServerFailure(
          message: 'Server error occurred',
          code: 500,
        );
      
      case DioExceptionType.cancel:
        return const ServerFailure(
          message: 'Request was cancelled',
          code: 1003,
        );
      
      case DioExceptionType.connectionError:
        return const NetworkFailure(
          message: 'Connection error. Please check your internet.',
          code: 1004,
        );
      
      default:
        return const ServerFailure(
          message: 'Unexpected error occurred',
          code: 9999,
        );
    }
  }

  static String _getErrorMessage(int statusCode, dynamic responseData) {
    try {
      if (responseData is Map<String, dynamic>) {
        return responseData['message'] ?? 
               responseData['error'] ?? 
               _getDefaultErrorMessage(statusCode);
      }
      return _getDefaultErrorMessage(statusCode);
    } catch (e) {
      return _getDefaultErrorMessage(statusCode);
    }
  }

  static String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden.';
      case 404:
        return 'Resource not found.';
      case 422:
        return 'Validation error. Please check your input.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Bad gateway. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}

// Extension to convert Either to UI-friendly messages
extension FailureX on Failure {
  String get userFriendlyMessage {
    switch (this.runtimeType) {
      case NetworkFailure:
        return 'Please check your internet connection and try again.';
      case ServerFailure:
        return message.isNotEmpty ? message : 'Server error. Please try again later.';
      case AuthFailure:
        return message.isNotEmpty ? message : 'Authentication failed. Please login again.';
      case ValidationFailure:
        return message.isNotEmpty ? message : 'Please check your input and try again.';
      default:
        return message.isNotEmpty ? message : 'Something went wrong. Please try again.';
    }
  }
}
