import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: 'accessToken', value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'accessToken');
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: 'accessToken');
  }
}
