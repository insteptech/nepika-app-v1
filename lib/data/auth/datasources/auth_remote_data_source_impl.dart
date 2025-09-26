import 'package:injectable/injectable.dart';
import 'package:nepika/core/network/secure_api_client.dart';
import '../../../core/config/constants/api_endpoints.dart';
// import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

@Injectable(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SecureApiClient _apiClient;
  
  AuthRemoteDataSourceImpl() : _apiClient = SecureApiClient.instance;
  
  @override
  Future<Map<String, dynamic>> sendOtp({
    String? phone,
    String? otpId,
    String? email,
  }) async {
    final data = <String, dynamic>{
      'mobile_number': phone,
    };
    final result = await _apiClient.request(
      path: ApiEndpoints.sendOtp,
      method: 'POST',
      body: data,
    );
    if (result.statusCode != 200 || result.data['success'] != true) {
      throw Exception(result.data['message'] ?? 'Failed to send OTP');
    }
    return result.data['data'] as Map<String, dynamic>;
  }

  // For resend OTP, call sendOtp with otpId present
  @override
  Future<Map<String, dynamic>> resendOtp({
    required String phone,
    required String otpId,
  }) async {
    if (phone.isEmpty || otpId.isEmpty) {
      throw Exception('Phone number and OTP ID must be provided');
    }


    final data = <String, dynamic>{
      'mobile_number': phone,
      'otp_id': otpId,
    };

    final result = await _apiClient.request(
      path: ApiEndpoints.resendOtp,
      method: 'POST',
      body: data,
    );
    if (result.statusCode != 200 || result.data['success'] != true) {
      throw Exception(result.data['message'] ?? 'Failed to resend OTP');
    }
    return result.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({
    String? phone,
    required String otp,
    required String otpId,
    String? email,
  }) async {
    final data = <String, dynamic>{
      'mobile_number': phone,
      'otp_code': otp,
      'otp_id': otpId,
    };
    final response = await _apiClient.request(
      path: ApiEndpoints.verifyOtp,
      method: 'POST',
      body: data,
    );
    if (response.data == null) {
      throw Exception('Server returned null response');
    }
    final responseData = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};

    final status = responseData['status_code'];
    final success = responseData['success'] ?? responseData['sucsess'];
    if ((status == 200 || status == '200') && (success == true || success == 'true')) {
      if (responseData['data'] is Map<String, dynamic>) {
        return responseData['data'] as Map<String, dynamic>;
      } else {
        return responseData;
      }
    } else {
      final errorMessage = responseData['message'] ?? 'OTP verification failed';
      throw Exception(errorMessage);
    }
  }
}
