class OnboardingSteps {
  static const String userInfo = 'user_info';
  static const String userDetail = 'user_detail';
  static const String lifestyle = 'lifestyle';
  static const String skinType = 'skin_type';
  static const String cycleDetail = 'cycle_detail';
  static const String cycleInfo = 'cycle_info';
  static const String menopauseStatus = 'menopause_status';
  static const String skinGoal = 'skin_goal';
  static const String naturalRhythm = 'natural_rhythm';

  static List<String> get orderedSteps => [
    userInfo,
    userDetail,
    lifestyle,
    skinType,
    cycleDetail,
    cycleInfo,
    menopauseStatus,
    skinGoal,
    naturalRhythm,
  ];

  static String getRouteForStep(String step) {
    switch (step) {
      case userInfo:
        return '/onboarding/user-info';
      case userDetail:
        return '/onboarding/user-detail';
      case lifestyle:
        return '/onboarding/lifestyle';
      case skinType:
        return '/onboarding/skin-type';
      case cycleDetail:
        return '/onboarding/cycle-detail';
      case cycleInfo:
        return '/onboarding/cycle-info';
      case menopauseStatus:
        return '/onboarding/menopause-status';
      case skinGoal:
        return '/onboarding/skin-goal';
      case naturalRhythm:
        return '/onboarding/natural-rhythm';
      default:
        return '/onboarding/user-info';
    }
  }
}