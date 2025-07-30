class AppRoutes {
  // Authentication Routes
  static const String notFound = '/not-found';
  static const String splash = '/';
  static const String login = '/login';
  static const String phoneEntry = '/phone-entry';
  static const String otpVerification = '/otp-verification';
  static const String userInfo = '/user-info';
  
  // Onboarding Routes
  static const String onboarding = '/onboarding';
  static const String faceScanOnboarding = '/face-scan-onboarding';
  
  // Main App Routes
  static const String home = '/home';
  static const String faceScan = '/face-scan';
  static const String scanResult = '/scan-result';
  static const String questionnaire = '/questionnaire';
  static const String products = '/products';
  static const String productDetail = '/product-detail';
  static const String settings = '/settings';

  // Dashboard Routes
// Dashboard Entry
  static const  String dashboard = '/dashboard';

  // Dashboard Internal Routes (with navbar)
  static const String dashboardHome = '/dashboard/home';
  static const String dashboardExplore = '/dashboard/explore';
  static const String dashboardScan = '/dashboard/scan';
  static const String dashboardProfile = '/dashboard/profile';

  static const String dashboardTodaysRoutine = '/dashboard/routine';
  static const String dashboardEditRoutine = '/dashboard/routine/edit';
  static const String dashboardAddRoutine = '/dashboard/routine/add';
  static const String dashboardReminderSettings = '/dashboard/routine/reminder';

  static const String dashboardAllProducts = '/dashboard/products/all';
  static const String dashboardSpecificProduct = '/dashboard/products/info';


  static const String dashboardSettings = '/dashboard/settings';
  static const String notificationsAndSettings = '/dashboard/settings/notifications-and-settings';
  static const String helpAndSupport = '/dashboard/settings/help-and-support';
  static const String communityAndEngagement = '/dashboard/settings/community-and-engagement';



  static const String todaysRoutine = '/todays-routine';
  static const String cameraScan = '/camera-scan';
  static const String faceScanResult = '/face-scan-result-page';

  
  // Profile Routes
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  
  // Subscription Routes
  static const String subscription = '/subscription';
  static const String paymentMethod = '/payment-method';
  
  // History Routes
  static const String scanHistory = '/scan-history';
  static const String healthHistory = '/health-history';
  
  // Settings Routes
  static const String notifications = '/notifications';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfUse = '/terms-of-use';
  static const String about = '/about';
}
