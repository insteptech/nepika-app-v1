import 'package:nepika/core/config/constants/app_constants.dart';
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

  Future<void> saveAppLanguage(String languageCode) async {
    await SharedPrefsHelper.init();
    final key = AppConstants.appLanguageKey;
    await _prefs?.setString(key, languageCode);
  }

  // Retrieve the app language
  Future<String> getAppLanguage() async {
    final key = AppConstants.appLanguageKey;
    return _prefs?.getString(key) ?? 'en';
  }

  // Notification permission tracking
  Future<void> setNotificationPermissionPrompted(bool prompted) async {
    await SharedPrefsHelper.init();
    await _prefs?.setBool(AppConstants.notificationPermissionPromptedKey, prompted);
  }

  Future<bool> hasNotificationPermissionBeenPrompted() async {
    await SharedPrefsHelper.init();
    return _prefs?.getBool(AppConstants.notificationPermissionPromptedKey) ?? false;
  }

  Future<void> setNotificationPermissionGranted(bool granted) async {
    await SharedPrefsHelper.init();
    await _prefs?.setBool(AppConstants.notificationPermissionGrantedKey, granted);
  }

  Future<bool> isNotificationPermissionGranted() async {
    await SharedPrefsHelper.init();
    return _prefs?.getBool(AppConstants.notificationPermissionGrantedKey) ?? false;
  }
}
