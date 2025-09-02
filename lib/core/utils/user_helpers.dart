import 'package:nepika/data/auth/models/user_model.dart';

import 'secure_storage.dart';

final SecureStorage _secureStorage = SecureStorage();

/// One-liner helper to get saved user
Future<UserModel?> getSavedUserInfo() async {
  return await _secureStorage.getUser();
}

/// One-liner helper to get saved userId
Future<String?> getSavedUserId() async {
  return await _secureStorage.getUserId();
}
