import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static SharedPreferences? _prefs;

  static final SharedPrefsHelper _instance = SharedPrefsHelper._internal();
  factory SharedPrefsHelper() => _instance;
  SharedPrefsHelper._internal();

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save data
  Future<void> setBool(String baseKey, bool value) async {
    final key = _transformKey(baseKey);
    await _prefs?.setBool(key, value);
  }

  Future<bool> getBool(String baseKey) async {
    final key = _transformKey(baseKey);
    return _prefs?.getBool(key) ?? false;
  }

  String _transformKey(String key) {
    final normalized = key.trim().toLowerCase().replaceAll(' ', '-');
    final suffix = key.hashCode.abs().toString().substring(0, 4);
    return '$normalized-$suffix';
  }
}
