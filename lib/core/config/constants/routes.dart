class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String phoneEntry = '/phone-entry';
  static const String otpVerification = '/otp-verification';


  static const String userInfo = '/user-info';
  static const String onboarding = '/onboarding';




  static const String todaysRoutine = '/todays-routine';
  static const String cameraScanGuidence = '/camera-scan';
  static const String faceScanResult = '/face-scan-result-page';
  // Authentication Routes
  static const String notFound = '/not-found';
  
  // Onboarding Routes
  static const String faceScanOnboarding = '/face-scan-onboarding';
  
  // Main App Routes
  static const String home = '/home';
  static const String faceScan = '/face-scan--optimized';
  static const String scanResult = '/scan-result';
  static const String questionnaire = '/questionnaire';
  static const String products = '/products';
  static const String productDetail = '/product-detail';
  static const String settings = '/settings';

  // Dashboard Routes
  // static const  String dashboardSlash = '/dashboard';
  static const String communityHome = '/community/home';
  static const String communitySearch = '/community/search';
  static const String communityUserProfile = '/community/user-profile';

  // Dashboard Internal Routes (with navbar)
  static const String dashboardHome = '/dashboard/home';
  static const String dashboardExplore = '/dashboard/explore';
  static const String dashboardScan = '/dashboard/scan';
  static const String dashboardProfile = '/dashboard/profile';


  static const String conditionDetailsPage = '/skin/condition/info';

  static const String dashboardTodaysRoutine = '/dashboard/routine';
  static const String dashboardEditRoutine = '/dashboard/routine/edit';
  static const String dashboardAddRoutine = '/dashboard/routine/add';
  static const String dashboardReminderSettings = '/dashboard/routine/reminder';

  static const String dashboardAllProducts = '/dashboard/products/all';
  static const String dashboardSpecificProduct = '/dashboard/products/info';
  static const String dashboardImageGallery = '/dashboard/image-gallery';
  static const String dashboardHistory = '/dashboard/history';

  static const String dashboardSettings = '/dashboard/settings';
  static const String notificationsAndSettings = '/dashboard/settings/notifications-and-settings';
  static const String helpAndSupport = '/dashboard/settings/help-and-support';
  static const String communityAndEngagement = '/dashboard/settings/community-and-engagement';
  static const String setupNotifications = '/dashboard/settings/setup_notifications';
  
  // Face scan routes
  static const String dashboardScanResultDetails = '/dashboard/scan-result-details';
  static const String scanResultDetails = '/scan-result-details';



  
  // Profile Routes
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  
  // Subscription Routes
  static const String subscription = '/subscription';
  static const String subscriptionPlans = '/subscription-plans';
  static const String subscriptionManagement = '/subscription-management';
  static const String pricing = '/pricing';
  static const String paymentMethod = '/payment-method';
  
  // History Routes
  static const String scanHistory = '/scan-history';
  static const String healthHistory = '/health-history';
  
  // Settings Routes
  static const String notifications = '/notifications';
  static const String notificationDebug = '/notification-debug';
  static const String androidNotificationDebug = '/android-notification-debug';
  static const String blockedUsers = '/blocked-users';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfUse = '/terms-of-use';
  static const String faceScanInfo = '/face-scan-info';
  static const String about = '/about';


  CommunityRoutes get community => CommunityRoutes();

  // static const DashboardRoutes dashboard = DashboardRoutes();
}



class DashboardRoutes {
  const DashboardRoutes();

  static const String slash = '/';
  static const String home = '/home';
  static const String explore = '/explore';
  static const String scan = '/scan';
  static const String profile = '/profile';
  static const String todaysRoutine = '/routine';
  static const String editRoutine = '/routine/edit';
  static const String addRoutine = '/routine/add';
  static const String reminderSettings = '/routine/reminder';
  static const String allProducts = '/products/all';
  static const String specificProduct = '/products/info';


  static const SettingsRoutes settings = SettingsRoutes();
}

class OnboardingRoutes {
  const OnboardingRoutes();

  static const String userInfo = '/onboarding/user_info';
  static const String userDetails = '/onboarding/user_detail';
  static const String skinType = '/onboarding/skin_type';
  static const String naturalRhythm = '/onboarding/natural_rhythm';
  static const String skinGoals = '/onboarding/skin_goals';
  static const String lifestyle = '/onboarding/lifestyle';
  static const String cycleInfo = '/onboarding/cycle_info';
  static const String cycleDetails = '/onboarding/cycle_details';
  static const String menopause = '/onboarding/menopause_status';
}


class SettingsRoutes{
  const SettingsRoutes();

  static const String slash = '/';
  static const String notificationsAndSettings = '/notifications-and-settings';
  static const String helpAndSupport = '/help-and-support';
  static const String communityAndEngagement = '/community-and-engagement';
  static const String setupNotifications = '/setup_notifications';
}


class CommunityRoutes {
  const CommunityRoutes();

  static const String home = '/community/home';
  static const String postDetail = '/community/post-detail';
  static const String createPost = '/community/create-post';
  static const String userProfile = '/community/user-profile';
  static const String searchUsers = '/community/search-users';
  static const String createProfile = '/community/create-profile';
  static const String communitySettings = '/community/settings';
}