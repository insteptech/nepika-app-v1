
import 'package:injectable/injectable.dart';
import 'package:nepika/data/auth/repositories/auth_repository.dart';

import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';


@injectable
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  const AuthRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<void> sendOtp({String? phone, String? email}) async {
    await remoteDataSource.sendOtp(phone: phone, email: email);
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    return await remoteDataSource.verifyOtp(phone: phone, otp: otp);
  }
}
