import 'package:flutter/material.dart';
import 'package:nepika/core/utils/shared_prefs_helper.dart';

class ThemeNotifier extends ChangeNotifier {
  static const String _themeKey = 'dark_mode_enabled';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeNotifier() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    await SharedPrefsHelper.init();
    final isDark = await SharedPrefsHelper().getBool(_themeKey);
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.system;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDarkMode) async {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    await SharedPrefsHelper().setBool(_themeKey, isDarkMode);
    notifyListeners();
  }
}
