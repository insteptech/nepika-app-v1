import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nepika/data/auth/models/user_model.dart';

class SecureStorage {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ----------------- TOKEN -----------------
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: 'accessToken', value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'accessToken');
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: 'accessToken');
  }

  // ----------------- USER ID -----------------
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: 'userId', value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'userId');
  }

  Future<void> deleteUserId() async {
    await _storage.delete(key: 'userId');
  }

  // ----------------- FULL USER INFO -----------------
  Future<void> saveUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _storage.write(key: 'userInfo', value: userJson);
  }

  Future<UserModel?> getUser() async {
    final userJson = await _storage.read(key: 'userInfo');
    if (userJson == null) return null;
    return UserModel.fromJson(jsonDecode(userJson));
  }

  Future<void> deleteUser() async {
    await _storage.delete(key: 'userInfo');
  }

  // ----------------- CLEAR ALL -----------------
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
