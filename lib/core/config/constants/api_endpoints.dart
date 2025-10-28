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
  static const String refreshToken = '/auth/users/refresh-token';

  static const String userOnboarding = '/user/onboarding';

  static const String userDailyRoutine = '/routines';
  static const String userMyProducts = '/products/recomendations';
  static const String userDetails = '/user/details';
  // static const String lifestyle = '/user/lifestyle';
  // static const String skinGoals = '/user/skin-goals';
  // static const String skinType = '/user/skin-type';

  static const String dashboard = '/dashboard/welcome';
  static const String subscriptionPlanInfo = '/subscription/plans/info';
  static const String paymentPlans = '/payments/plans';
  static const String stripeConfig = '/payments/config';
  static const String createCheckoutSession = '/payments/create-checkout-session';
  static const String subscriptionStatus = '/payments/subscription/status';
  static const String subscriptionDetails = '/payments/subscription';
  static const String cancelSubscription = '/payments/subscription/cancel';
  static const String reactivateSubscription = '/payments/subscription/reactivate';


  // # it need condition slug at end of this endpoint
  static const String fetchSkinConditionDetails = '/dashboard/skin-condition';
  
  // Community Endpoints - Updated to match API specification
  static const String communityPosts = '/community/posts';
  static const String userSearch = '/community/search/users';
  static const String createCommunityPost = '/community/posts';
  static const String getSinglePost = '/community/posts'; // GET with postId parameter
  static const String likePost = '/community/posts'; // PUT /:id/like (changed to PUT)
  static const String getPostComments = '/community/posts'; // GET /:id/comments
  static const String updatePost = '/community/posts'; // PUT /:id
  static const String deletePost = '/community/posts'; // DELETE /:id
  
  // Profile Management Endpoints
  static const String createProfile = '/community/profiles';
  static const String getMyProfile = '/community/profiles';
  static const String getUserProfile = '/community/profiles'; // GET /:user_id
  static const String updateProfile = '/community/profiles';
  
  // Image Management Endpoints
  static const String uploadProfileImage = '/community/profiles/upload-picture';
  static const String getSecureImageUrl = '/community/images/secure-url';
  
  // Follow System Endpoints
  static const String followUser = '/community/follow';
  static const String unfollowUser = '/community/follow'; // DELETE /:user_id
  static const String getFollowers = '/community/users'; // GET /:user_id/followers
  static const String getFollowing = '/community/users'; // GET /:user_id/following
  static const String checkFollowStatus = '/community/follow/status'; // GET /:user_id
  
  // Block System Endpoints
  static const String blockUser = '/community/block';
  static const String unblockUser = '/community/block'; // DELETE /:user_id
  static const String getBlockedUsers = '/community/blocks'; // GET
  static const String checkBlockStatus = '/community/block/status'; // GET /:user_id
  
  // User Posts Endpoints
  static const String getUserMainPosts = '/community/users/posts'; // GET /:user_id or query param
  static const String getUserCommentPosts = '/community/users/posts'; // GET /:user_id/comments
  
  // Question Endpoints
  
  // Notification Endpoints (SSE)
  static const String notificationStream = '/community/notifications/stream';
  static const String unreadCount = '/community/notifications/unread-count';
  static const String markSeen = '/community/notifications/mark-seen';
}
