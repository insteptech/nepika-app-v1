class ApiEndpoints {
  static const String onboardingUserNaturalRhythm = '/user/onboarding/natural_rhythm';
  static const String onboardingQuestionnaire = '/onboarding/user';
  static const String onboardingUserInfo = '/user/onboarding/user_info';
  static const String onboardingUserDetail = '/user/onboarding/user_detail';
  static const String onboardingLifestyle = '/user/onboarding/lifestyle';
  static const String onboardingSkinType = '/user/onboarding/skin_type';
  static const String onboardingCycleDetail = '/user/onboarding/cycle_detail';
  static const String onboardingCycleInfo = '/user/onboarding/cycle_info';
  static const String onboardingMenopauseStatus = '/user/onboarding/menopause_status';
  static const String onboardingSkinGoal = '/user/onboarding/skin_goal';
  // Authentication Endpoints
  static const String sendOtp = '/auth/users/send-otp';
  static const String verifyOtp = '/auth/users/verify-otp';
  static const String resendOtp = '/auth/users/resend-otp';

  static const String userOnboarding = '/user/onboarding';

  static const String userDailyRoutine = '/routines';
  static const String userMyProducts = '/user/my-products';
  static const String userDetails = '/user/details';
  // static const String lifestyle = '/user/lifestyle';
  // static const String skinGoals = '/user/skin-goals';
  // static const String skinType = '/user/skin-type';

  static const String dashboard = '/dashboard/welcome';
  static const String subscriptionPlanInfo = '/subscription/plans/info';
  
  // Community Endpoints
  static const String communityPosts = '/community/posts';
  static const String userSearch = '/user/search';
  static const String createCommunityPost = '/community/post';
  static const String getSinglePost = '/community/posts'; // GET with postId parameter
  static const String likePost = '/community/posts'; // POST /:id/like
  static const String unlikePost = '/community/posts'; // DELETE /:id/unlike
  static const String userProfile = '/community/user/profile'; // GET /:id
  
  // Question Endpoints
}
