import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants/theme_notifier.dart';

class ThemeHelper {
  static bool isDarkMode(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    
    switch (themeNotifier.themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }
}