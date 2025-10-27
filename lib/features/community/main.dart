import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/community/repositories/community_repository_impl.dart';
import '../../../data/community/datasources/community_local_datasource.dart';
import '../../core/api_base.dart';
import 'bloc/blocs/community_bloc_manager.dart';
import 'bloc/blocs/profile_bloc.dart';
import 'screens/community_home_screen.dart';
import 'screens/community_search_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/community_settings_screen.dart';
import 'utils/community_navigation.dart';

/// Main entry point for the Community feature
/// Follows Dependency Injection and Factory patterns
/// Integrates with existing data/domain layers while maintaining clean separation
class CommunityFeature extends StatelessWidget {
  const CommunityFeature({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const CommunityProviders(
      child: CommunityHomeScreen(),
    );
  }

  /// Static method to create the community feature with proper DI
  static Widget create() {
    return const CommunityFeature();
  }
}

/// Community providers wrapper that sets up all necessary BLoCs
/// Follows Provider pattern for dependency injection
class CommunityProviders extends StatefulWidget {
  final Widget child;

  const CommunityProviders({
    super.key,
    required this.child,
  });

  @override
  State<CommunityProviders> createState() => _CommunityProvidersState();
}

class _CommunityProvidersState extends State<CommunityProviders> {
  late final CommunityBlocManager _blocManager;

  @override
  void initState() {
    super.initState();
    _initializeBlocManager();
  }

  void _initializeBlocManager() {
    // Create repository with dependencies
    final repository = CommunityRepositoryImpl(
      ApiBase(),
      CommunityLocalDataSourceImpl(),
    );

    // Initialize BLoC manager
    _blocManager = CommunityBlocManager.create(repository);
    
    // Initialize navigation helper
    CommunityNavigation.initialize();
  }

  @override
  void dispose() {
    _blocManager.dispose();
    CommunityNavigation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: _blocManager.blocProviders,
      child: widget.child,
    );
  }
}

/// Extension to provide easy access to community BLoCs
extension CommunityBlocAccess on BuildContext {
  T readCommunityBloc<T>() => read<T>();
  T watchCommunityBloc<T>() => watch<T>();
}

/// Factory class for creating community-related screens and widgets
/// Follows Factory pattern for consistent object creation
class CommunityFactory {
  /// Create community home screen with proper setup
  static Widget createHomeScreen() {
    return CommunityFeature.create();
  }

  /// Create community search screen with proper BLoC providers
  static Widget createSearchScreen() {
    return const CommunityProviders(
      child: CommunitySearchScreen(),
    );
  }

  /// Create user profile screen with proper BLoC providers
  static Widget createUserProfileScreen() {
    return const CommunityProviders(
      child: UserProfileScreen(),
    );
  }

  /// Create post creation screen
  static Widget createPostScreen({
    required BuildContext context,
    required String token,
    required String userId,
  }) {
    // Use existing BLoC providers from context
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read()),
        // Add other BLoCs as needed
      ],
      child: const Placeholder(), // Replace with actual create post screen
    );
  }

  /// Create edit profile screen with proper BLoC providers
  static Widget createEditProfileScreen({
    required BuildContext context,
    required String token,
    String? currentUsername,
    String? currentBio,
    String? currentProfileImage,
  }) {
    // Use existing BLoC providers from context
    try {
      final profileBloc = context.read<ProfileBloc>();
      return BlocProvider<ProfileBloc>.value(
        value: profileBloc,
        child: EditProfileScreen(
          token: token,
          currentUsername: currentUsername,
          currentBio: currentBio,
          currentProfileImage: currentProfileImage,
        ),
      );
    } catch (e) {
      debugPrint('CommunityFactory: ProfileBloc not available, creating EditProfileScreen without full BLoC support: $e');
      // Fallback: Return screen without ProfileBloc provider (limited functionality)
      return EditProfileScreen(
        token: token,
        currentUsername: currentUsername,
        currentBio: currentBio,
        currentProfileImage: currentProfileImage,
      );
    }
  }

  /// Create community settings screen
  static Widget createCommunitySettingsScreen() {
    debugPrint('🏗️ CommunityFactory: Creating Community Settings Screen');
    return const CommunitySettingsScreen();
  }
}

/// Constants for the community feature
class CommunityConstants {
  static const String featureName = 'Community';
  static const String defaultErrorMessage = 'Something went wrong in the community feature';
  
  // Page sizes
  static const int defaultPostsPageSize = 20;
  static const int defaultCommentsPageSize = 20;
  static const int defaultUsersPageSize = 10;
  
  // Limits
  static const int maxPostContentWords = 50;
  static const int maxCommentContentWords = 30;
  
  // Timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration likeDebounceTimeout = Duration(seconds: 1);
  static const Duration followDebounceTimeout = Duration(milliseconds: 800);
}

/// Configuration class for community feature settings
class CommunityConfig {
  final bool enableCaching;
  final bool enableOptimisticUpdates;
  final bool enableDebugLogging;
  final Duration networkTimeout;

  const CommunityConfig({
    this.enableCaching = true,
    this.enableOptimisticUpdates = true,
    this.enableDebugLogging = false,
    this.networkTimeout = CommunityConstants.defaultTimeout,
  });

  /// Default production configuration
  static const CommunityConfig production = CommunityConfig(
    enableCaching: true,
    enableOptimisticUpdates: true,
    enableDebugLogging: false,
  );

  /// Default development configuration
  static const CommunityConfig development = CommunityConfig(
    enableCaching: true,
    enableOptimisticUpdates: true,
    enableDebugLogging: true,
  );
}