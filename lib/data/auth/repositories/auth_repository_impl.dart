
import 'package:injectable/injectable.dart';
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

  const AuthRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<Result<void>> sendOtp({String? phone, String? email}) async {
    try {
      await remoteDataSource.sendOtp(phone: phone, email: email);
      return success(null);
    } catch (e) {
      return failure(ServerFailure(message: 'Failed to send OTP: ${e.toString()}'));
    }
  }

  @override
  Future<Result<AuthResponse>> verifyOtp({String? phone, required String otp}) async {
    try {
      final result = await remoteDataSource.verifyOtp(phone: phone, otp: otp);
      
      // Debug logging to see the actual API response structure
      print('Raw API Response in Repository: $result');
      print('Response keys: ${result.keys.toList()}');
      
      final authResponse = AuthResponse.fromJson(result);
      
      // Store tokens securely
      await localDataSource.storeToken(authResponse.token);
      await localDataSource.storeRefreshToken(authResponse.refreshToken);
      
      // Store user data and onboarding status
      final userModel = UserModel.fromEntity(authResponse.user);
      await localDataSource.saveUser(userModel);
      await localDataSource.saveOnboardingStatus(authResponse.user.onboardingCompleted);
      
      return success(authResponse);
    } catch (e) {
      print('Repository Error: $e');
      return failure(AuthFailure(message: 'Failed to verify OTP: ${e.toString()}'));
    }
  }
}
