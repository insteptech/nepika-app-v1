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
    
    try {
      final response = await apiBase.request(
        path: ApiEndpoints.verifyOtp,
        method: 'POST',
        body: data,
      );
      
      // Debug logging
      print('OTP Verification Response: ${response.data}');
      print('Response type: ${response.data.runtimeType}');
      
      // Handle null response
      if (response.data == null) {
        throw Exception('Server returned null response');
      }
      
      // Convert response.data to Map<String, dynamic> safely
      final responseData = response.data is Map<String, dynamic> 
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      
      // Check for success in the response
      final status = responseData['status'];
      final success = responseData['success'] ?? responseData['sucsess']; // Handle typo in API
      
      if ((status == 200 || status == '200') && (success == true || success == 'true')) {
        return responseData;
      } else {
        final errorMessage = responseData['message'] ?? 'OTP verification failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('OTP Verification Error: $e');
      rethrow;
    }
  }
}
