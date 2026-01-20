import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:nepika/core/utils/secure_storage.dart';
import '../../../core/utils/either.dart';
import '../../../core/error/failures.dart';
import '../../../domain/auth/entities/user.dart';
import '../models/user_model.dart';
import 'package:nepika/domain/auth/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

@injectable
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  // ✅ initialize normally (not const)
  final SecureStorage secureStorage = SecureStorage();

  AuthRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<Result<Map<String, dynamic>>> sendOtp({
    String? phone,
    String? email,
    String? otpId,
    String? appSignature,
  }) async {
    try {
      final response = await remoteDataSource.sendOtp(
        phone: phone,
        email: email,
        otpId: otpId,
        appSignature: appSignature,
      );
      return success(response);
    } catch (e) {
      return failure(
        ServerFailure(message: 'Failed to send OTP: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> resendOtp({
    required String phone,
    required String otpId,
    String? appSignature,
  }) async {
    try {
      final response = await remoteDataSource.resendOtp(
        phone: phone,
        otpId: otpId,
        appSignature: appSignature,
      );
      return success(response);
    } catch (e) {
      String errorMessage = 'Failed to resend OTP';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['detail'] != null) {
          errorMessage = data['detail'].toString();
        } else if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Endpoint not found (404)';
        } else {
          errorMessage = e.message ?? errorMessage;
        }
      }
      return failure(ServerFailure(message: errorMessage));
    }
  }

  @override
  Future<Result<AuthResponse>> verifyOtp({
    String? phone,
    required String otp,
    required String otpId,
  }) async {
    try {
      final result = await remoteDataSource.verifyOtp(
        phone: phone,
        otp: otp,
        otpId: otpId,
      );

      Map<String, dynamic> wrappedResult;
      if (result.containsKey('token')) {
        wrappedResult = {'data': result};
      } else {
        wrappedResult = result;
      }

      if ((wrappedResult['data']?['token'] ?? wrappedResult['token']) != null) {
        final authResponse = AuthResponse.fromJson(wrappedResult);

        // ✅ Save tokens locally
        debugPrint('🔑 AuthRepository: Saving access token: ${authResponse.token.substring(0, 20)}...');
        debugPrint('🔑 AuthRepository: Saving refresh token: ${authResponse.refreshToken.substring(0, 20)}...');
        await localDataSource.storeToken(authResponse.token);
        await localDataSource.storeRefreshToken(authResponse.refreshToken);
        
        // Verify token was saved
        final savedToken = await localDataSource.getToken();
        debugPrint('Token saved verification: ${savedToken != null ? "SUCCESS" : "FAILED"}');

        // ✅ Convert to UserModel & save locally
        final userModel = UserModel.fromEntity(authResponse.user);
        await localDataSource.saveUser(userModel);
        await localDataSource.saveOnboardingStatus(
          authResponse.user.onboardingCompleted,
        );

        // ✅ Also save in SecureStorage
        await secureStorage.saveUser(userModel);
        if (authResponse.user.id.isNotEmpty) {
          await secureStorage.saveUserId(authResponse.user.id);
        }

        return success(authResponse);
      } else {
        String errorMessage =
            wrappedResult['data']?['message']?.toString() ??
            wrappedResult['message']?.toString() ??
            'OTP verification failed';
        return failure(AuthFailure(message: errorMessage));
      }
    } catch (e) {
      debugPrint('========================================');
      debugPrint('AuthRepository: Error during OTP verification');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');

      String errorMessage = 'Failed to verify OTP';
      if (e is DioException) {
        debugPrint('DioException status code: ${e.response?.statusCode}');
        debugPrint('DioException response data: ${e.response?.data}');

        final data = e.response?.data;
        if (data is Map && data['detail'] != null) {
          errorMessage = data['detail'].toString();
        } else if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
        } else if (e.response?.statusCode == 400) {
          errorMessage = 'Invalid OTP. Please check and try again.';
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'OTP has expired. Please request a new one.';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'OTP session not found. Please restart the verification process.';
        } else {
          errorMessage = e.message ?? errorMessage;
        }
      } else if (e is Exception) {
        errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.replaceFirst('Exception: ', '');
        }
      }

      debugPrint('Final error message: $errorMessage');
      debugPrint('========================================');
      return failure(AuthFailure(message: errorMessage));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> verifyEmailOtp({
    required String email,
    required String otpCode,
    required String otpId,
  }) async {
    try {
      final response = await remoteDataSource.verifyEmailOtp(
        email: email,
        otpCode: otpCode,
        otpId: otpId,
      );
      return success(response);
    } catch (e) {
      debugPrint('========================================');
      debugPrint('AuthRepository: Error during Email OTP verification');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');

      String errorMessage = 'Failed to verify OTP';
      if (e is DioException) {
        debugPrint('DioException status code: ${e.response?.statusCode}');
        debugPrint('DioException response data: ${e.response?.data}');

        final data = e.response?.data;
        if (data is Map && data['detail'] != null) {
          errorMessage = data['detail'].toString();
        } else if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
        } else if (e.response?.statusCode == 400) {
          errorMessage = 'Invalid OTP. Please check and try again.';
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'OTP has expired. Please request a new one.';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'OTP session not found. Please restart the verification process.';
        } else {
          errorMessage = e.message ?? errorMessage;
        }
      } else if (e is Exception) {
        errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.replaceFirst('Exception: ', '');
        }
      }

      debugPrint('Final error message: $errorMessage');
      debugPrint('========================================');
      return failure(AuthFailure(message: errorMessage));
    }
  }
  @override
  Future<Result<Map<String, dynamic>>> sendUpdateMobileOtp({
    required String newMobileNumber,
    String? recoveryToken,
  }) async {
    try {
      final response = await remoteDataSource.sendUpdateMobileOtp(
        newMobileNumber: newMobileNumber,
        recoveryToken: recoveryToken,
      );
      return success(response);
    } catch (e) {
      debugPrint('AuthRepository: Error sending update mobile OTP');
      
      String errorMessage = 'Failed to send OTP';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['detail'] != null) {
          errorMessage = data['detail'].toString();
        } else if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
        } else {
          errorMessage = e.message ?? errorMessage;
        }
      } else if (e is Exception) {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      
      return failure(ServerFailure(message: errorMessage));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> verifyUpdateMobileOtp({
    required String newMobileNumber,
    required String otpCode,
    required String otpId,
    String? recoveryToken,
  }) async {
    try {
      final response = await remoteDataSource.verifyUpdateMobileOtp(
        newMobileNumber: newMobileNumber,
        otpCode: otpCode,
        otpId: otpId,
        recoveryToken: recoveryToken,
      );
      return success(response);
    } catch (e) {
      debugPrint('========================================');
      debugPrint('AuthRepository: Error during Mobile Update OTP verification');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');

      String errorMessage = 'Failed to verify OTP';
      if (e is DioException) {
        debugPrint('DioException status code: ${e.response?.statusCode}');
        debugPrint('DioException response data: ${e.response?.data}');

        final data = e.response?.data;
        if (data is Map && data['detail'] != null) {
          errorMessage = data['detail'].toString();
        } else if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
        } else if (e.response?.statusCode == 400) {
          errorMessage = 'Invalid OTP. Please check and try again.';
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'OTP has expired. Please request a new one.';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'OTP session not found. Please restart the verification process.';
        } else {
          errorMessage = e.message ?? errorMessage;
        }
      } else if (e is Exception) {
        errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.replaceFirst('Exception: ', '');
        }
      }

      debugPrint('Final error message: $errorMessage');
      debugPrint('========================================');
      return failure(AuthFailure(message: errorMessage));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> recoverSendEmailOtp({
    required String email,
  }) async {
    try {
      final response = await remoteDataSource.recoverSendEmailOtp(
        email: email,
      );
      return success(response);
    } catch (e) {
      debugPrint('AuthRepository: Error sending recovery email OTP');
      return failure(ServerFailure(message: _getErrorMessage(e)));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> recoverVerifyEmailOtp({
    required String email,
    required String otpCode,
    required String otpId,
  }) async {
    try {
      final response = await remoteDataSource.recoverVerifyEmailOtp(
        email: email,
        otpCode: otpCode,
        otpId: otpId,
      );
      return success(response);
    } catch (e) {
      debugPrint('AuthRepository: Error verifying recovery email OTP');
      return failure(ServerFailure(message: _getErrorMessage(e)));
    }
  }

  String _getErrorMessage(dynamic e) {
    String errorMessage = 'An error occurred';
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['detail'] != null) {
        errorMessage = data['detail'].toString();
      } else if (data is Map && data['message'] != null) {
        errorMessage = data['message'].toString();
      } else {
        errorMessage = e.message ?? errorMessage;
      }
    } else if (e is Exception) {
      errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
    }
    return errorMessage;
  }
}
