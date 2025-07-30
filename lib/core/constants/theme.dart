import 'package:flutter/material.dart';
import 'fonts.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF4A90E2);
  static const Color primaryDark = Color(0xFF357ABD);
  static const Color secondaryColor = Color(0xFF00C896);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFFFD748);
  static const Color successColor = Color(0xFF88FF48);

  // Light Theme Colors
  static const Color backgroundColorLight = Color(0xFFF0F9FF);
  static const Color surfaceColorLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF07223B);
  static const Color textSecondaryLight = Color(0xFF7F7F7F);
  static const Color textTertiaryLight = Color(0xFFABB3BF);

  // Dark Theme Colors
  static const Color backgroundColorDark = Color(0xFF0B111E);
  static const Color surfaceColorDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFE5E7EB);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textTertiaryDark = Color(0xFF6B7280);


  static const Color blackWhite = Color(0xFF000000);
  static const Color whiteBlack = Color(0xFFFFFFFF);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: AppFonts.primary,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      surface: backgroundColorLight,
      onSurface: blackWhite,
      onPrimary: primaryColor,
      onSecondary: Color(0xFFFFFFFF),
      onTertiary: Color(0xFFFFFFFF),
    ),
    scaffoldBackgroundColor: backgroundColorLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColorLight,
      foregroundColor: textPrimaryLight,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: _textTheme(isDark: false),
    elevatedButtonTheme: _elevatedButtonTheme(),
    outlinedButtonTheme: _outlinedButtonTheme(),
    inputDecorationTheme: _inputDecorationTheme(isDark: false),
    iconTheme: _iconTheme(isDark: false),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: AppFonts.primary,
    colorScheme: const ColorScheme.dark(
      primary: primaryDark,
      onPrimary: backgroundColorDark,
      secondary: secondaryColor,
      error: errorColor,
      surface: backgroundColorDark,
      onSurface: whiteBlack,
      onSecondary: Color(0xFFFFFFFF),
      onTertiary: textTertiaryDark,
    ),
    scaffoldBackgroundColor: backgroundColorDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColorDark,
      foregroundColor: textPrimaryDark,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: _textTheme(isDark: true),
    elevatedButtonTheme: _elevatedButtonTheme(),
    outlinedButtonTheme: _outlinedButtonTheme(),
    inputDecorationTheme: _inputDecorationTheme(isDark: true),
    iconTheme: _iconTheme(isDark: true),
  );

static TextTheme _textTheme({required bool isDark}) {
  final primary = isDark ? textPrimaryDark : textPrimaryLight;

  return TextTheme(
    displayLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      color: primary,
    ),
    displayMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w400,
      color: primary,
    ),
    displaySmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w400,
      color: primary,
    ),
    headlineLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      color: primary,
    ),
    headlineMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: primary,
    ),
    bodyLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: primary,
    ),
    bodyMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: primary,
    ),
    bodySmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      color: primary,
    ),
  ).apply(fontFamily: AppFonts.primary);
}




  static ElevatedButtonThemeData _elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({required bool isDark}) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? surfaceColorDark : surfaceColorLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[600]! : const Color(0xFFE5E7EB),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[600]! : const Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  static IconThemeData _iconTheme({required bool isDark}) {
    return IconThemeData(
      color: isDark ? textPrimaryDark : textPrimaryLight,
      size: 24,
    );
  }
}

extension TextStyleColorShortcut on TextStyle {
  TextStyle primary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    return copyWith(color: color);
  }

  TextStyle secondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? AppTheme.textTertiaryLight
        : AppTheme.textTertiaryDark;
    return copyWith(color: color);
  }

  TextStyle hint(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppTheme.primaryDark : AppTheme.primaryColor;
    return copyWith(color: color);
  }
}
