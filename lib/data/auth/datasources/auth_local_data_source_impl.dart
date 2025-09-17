import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import '../../core/constants/app_constants.dart';
import '../../../core/config/constants/app_constants.dart';
import '../models/auth_token_model.dart';
import '../models/user_model.dart';
import 'auth_local_data_source.dart';

@Injectable(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  const AuthLocalDataSourceImpl(this.sharedPreferences);
  
  @override
  Future<void> saveAuthToken(AuthTokenModel token) async {
    final tokenJson = jsonEncode(token.toJson());
    await sharedPreferences.setString(AppConstants.userTokenKey, tokenJson);
  }
  
  @override
  Future<AuthTokenModel?> getAuthToken() async {
    final tokenJson = sharedPreferences.getString(AppConstants.userTokenKey);
    
    if (tokenJson != null) {
      try {
        final tokenMap = jsonDecode(tokenJson) as Map<String, dynamic>;
        return AuthTokenModel.fromJson(tokenMap);
      } catch (e) {
        // If token is corrupted, clear it
        await clearAuthData();
        return null;
      }
    }
    
    return null;
  }
  
  @override
  Future<void> saveUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await sharedPreferences.setString(AppConstants.userDataKey, userJson);
  }
  
  @override
  Future<UserModel?> getUser() async {
    final userJson = sharedPreferences.getString(AppConstants.userDataKey);
    
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(userMap);
      } catch (e) {
        // If user data is corrupted, clear it
        await clearUserData();
        return null;
      }
    }
    
    return null;
  }
  
  @override
  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    
    if (token == null) {
      return false;
    }
    
    // Check if token is expired
    if (token.isExpired) {
      await clearAuthData();
      return false;
    }
    
    return true;
  }
  
  @override
  Future<void> clearAuthData() async {
    await sharedPreferences.remove(AppConstants.userTokenKey);
  }
  
  @override
  Future<void> clearUserData() async {
    await sharedPreferences.remove(AppConstants.userDataKey);
  }
  
  @override
  Future<void> saveOnboardingStatus(bool completed) async {
    await sharedPreferences.setBool(AppConstants.onboardingKey, completed);
  }
  
  @override
  Future<bool> getOnboardingStatus() async {
    return sharedPreferences.getBool(AppConstants.onboardingKey) ?? false;
  }

  @override
  Future<void> storeToken(String token) async {
    // Store in both SharedPreferences and SecureStorage for compatibility
    await sharedPreferences.setString(AppConstants.accessTokenKey, token);
    await _secureStorage.write(key: "access_token", value: token);
    print('✅ AuthLocalDataSource: Access token saved successfully (${token.substring(0, 20)}...)');
  }

  @override
  Future<void> storeRefreshToken(String refreshToken) async {
    // Store in both SharedPreferences and SecureStorage for compatibility  
    await sharedPreferences.setString(AppConstants.refreshTokenKey, refreshToken);
    await _secureStorage.write(key: "refresh_token", value: refreshToken);
    print('✅ AuthLocalDataSource: Refresh token saved successfully (${refreshToken.substring(0, 20)}...)');
  }

  @override
  Future<String?> getToken() async {
    return sharedPreferences.getString(AppConstants.accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return sharedPreferences.getString(AppConstants.refreshTokenKey);
  }

  @override
  Future<void> clearTokens() async {
    await sharedPreferences.remove(AppConstants.accessTokenKey);
    await sharedPreferences.remove(AppConstants.refreshTokenKey);
  }
}
