import '../../data/auth/datasources/auth_local_data_source.dart';
import '../../data/auth/models/user_model.dart';

class AuthService {
  final AuthLocalDataSource localDataSource;

  AuthService(this.localDataSource);

  /// Check if user is authenticated (has valid token)
  Future<bool> isAuthenticated() async {
    final token = await localDataSource.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    return await localDataSource.getOnboardingStatus();
  }

  /// Get user data
  Future<UserModel?> getCurrentUser() async {
    return await localDataSource.getUser();
  }

  /// Get user's active onboarding step
  Future<String?> getActiveStep() async {
    final user = await getCurrentUser();
    return user?.activeStep.toString();
  }

  /// Clear all authentication data (logout)
  Future<void> logout() async {
    await localDataSource.clearTokens();
    await localDataSource.clearUserData();
    await localDataSource.clearAuthData();
  }

  /// Get authentication status for app initialization
  Future<AuthStatus> getAuthStatus() async {
    final isAuth = await isAuthenticated();
    
    if (!isAuth) {
      return const AuthStatusUnauthenticated();
    }

    final hasOnboarding = await hasCompletedOnboarding();
    if (hasOnboarding) {
      return const AuthStatusAuthenticated();
    } else {
      final activeStep = await getActiveStep();
      return AuthStatusNeedsOnboarding(activeStep ?? 'user_info');
    }
  }
}

/// Represents the authentication status of the user
sealed class AuthStatus {
  const AuthStatus();
}

class AuthStatusUnauthenticated extends AuthStatus {
  const AuthStatusUnauthenticated();
}

class AuthStatusAuthenticated extends AuthStatus {
  const AuthStatusAuthenticated();
}

class AuthStatusNeedsOnboarding extends AuthStatus {
  final String activeStep;
  const AuthStatusNeedsOnboarding(this.activeStep);
}
