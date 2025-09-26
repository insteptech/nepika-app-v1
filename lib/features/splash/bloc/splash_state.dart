abstract class SplashState {}

class SplashInitial extends SplashState {}

class SplashAnimating extends SplashState {}

class SplashCheckingAuth extends SplashState {}

class SplashNavigateToWelcome extends SplashState {}

class SplashNavigateToOnboarding extends SplashState {
  final int? activeStep;
  
  SplashNavigateToOnboarding({this.activeStep});
}

class SplashError extends SplashState {
  final String message;
  
  SplashError(this.message);
}