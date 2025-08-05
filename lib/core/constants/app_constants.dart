class AppConstants {
  // App Information
  static const String appName = 'Nepika';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String onboardingKey = 'onboarding_completed';
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  
  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration scanAnimationDuration = Duration(seconds: 3);
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double buttonHeight = 56.0;
  static const double textFieldHeight = 52.0;
  
  // Camera Configuration
  static const Duration scanTimeout = Duration(seconds: 30);
  static const int maxScanAttempts = 3;
  
  // Health Metrics
  static const int maxHeartRate = 200;
  static const int minHeartRate = 40;
  static const int maxBloodPressure = 300;
  static const int minBloodPressure = 60;
}
