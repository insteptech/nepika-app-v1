import 'package:injectable/injectable.dart';
import 'package:nepika/core/api_base.dart';
import '../../../core/constants/api_endpoints.dart';
// import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

@Injectable(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiBase apiBase;
  
  const AuthRemoteDataSourceImpl(this.apiBase);
  
  @override
  Future<void> sendOtp({
    String? email,
    String? phone,
  }) async {
    final data = <String, dynamic>{};
    
    if (email != null) {
      data['email'] = email;
    }
    
    if (phone != null) {
      data['phone'] = phone;
    }
    
    await apiBase.request(
      path: ApiEndpoints.sendOtp,
      method: 'POST',
      body: data,
    );
  }
  
  @override
  Future<Map<String, dynamic>> verifyOtp({
    String? email,
    String? phone,
    required String otp,
  }) async {
    final data = <String, dynamic>{
      'otp': otp,
      'phoneNumber': phone ?? '',
    };
    
    if (email != null) {
      data['email'] = email;
    }
    
    if (phone != null) {
      data['phone'] = phone;
    }
    
    final response = await apiBase.request(
      path: ApiEndpoints.verifyOtp,
      method: 'POST',
      body: data,
    );
    
    if (response.data['status'] == 200 && (response.data['success'] == true || response.data['sucsess'] == true)) {
      return Map<String, dynamic>.from(response.data);
    } else {
      throw Exception(response.data['message'] ?? 'OTP verification failed');
    }
  }
}
