import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/blocs/posts_bloc.dart';
import '../bloc/blocs/user_search_bloc.dart';
import '../bloc/blocs/profile_bloc.dart';
import '../screens/user_profile_screen.dart';
import '../screens/community_search_screen.dart';
import '../screens/post_detail_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/edit_profile_screen.dart';

/// Optimized navigation utilities with proper BLoC availability checks
class CommunityNavigation {
  /// Initialize the navigation (kept for compatibility)
  static void initialize() {
    // Navigation now uses existing providers from context
    // No separate BLoC manager needed
  }
  
  /// Check if required BLoCs are available in context
  static bool _areBlocsAvailable(BuildContext context) {
    try {
      context.read<PostsBloc>();
      context.read<UserSearchBloc>();
      context.read<ProfileBloc>();
      return true;
    } catch (e) {
      debugPrint('CommunityNavigation: Required BLoCs not available: $e');
      return false;
    }
  }
  
  /// Show error dialog when BLoCs are not available
  static void _showBlocError(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Navigation Error'),
        content: const Text('Unable to navigate. Please try restarting the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  /// Navigate to user profile screen with proper BLoC providers
  static Future<void> navigateToUserProfile(
    BuildContext context, {
    String? userId,
  }) async {
    if (!_areBlocsAvailable(context)) {
      _showBlocError(context);
      return;
    }
    
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid user ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (newContext) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<PostsBloc>()),
              BlocProvider.value(value: context.read<UserSearchBloc>()),
              BlocProvider.value(value: context.read<ProfileBloc>()),
            ],
            child: UserProfileScreen(userId: userId),
          ),
          settings: RouteSettings(
            name: '/community/profile',
            arguments: {'userId': userId},
          ),
        ),
      );
    } catch (e) {
      debugPrint('CommunityNavigation: Error navigating to profile: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Navigate to search screen with proper BLoC providers
  static Future<void> navigateToSearch(BuildContext context) async {
    if (!_areBlocsAvailable(context)) {
      _showBlocError(context);
      return;
    }
    
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (newContext) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<PostsBloc>()),
              BlocProvider.value(value: context.read<UserSearchBloc>()),
              BlocProvider.value(value: context.read<ProfileBloc>()),
            ],
            child: const CommunitySearchScreen(),
          ),
          settings: const RouteSettings(name: '/community/search'),
        ),
      );
    } catch (e) {
      debugPrint('CommunityNavigation: Error navigating to search: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search unavailable: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Navigate to post detail screen with proper BLoC providers
  static Future<void> navigateToPostDetail(
    BuildContext context, {
    required String postId,
    String? token,
    String? userId,
    bool? currentLikeStatus,
    int? currentLikeCount,
  }) async {
    if (!_areBlocsAvailable(context)) {
      _showBlocError(context);
      return;
    }
    
    if (postId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid post ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (newContext) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<PostsBloc>()),
              BlocProvider.value(value: context.read<UserSearchBloc>()),
              BlocProvider.value(value: context.read<ProfileBloc>()),
            ],
            child: PostDetailScreen(
              postId: postId,
              token: token,
              userId: userId,
              currentLikeStatus: currentLikeStatus,
              currentLikeCount: currentLikeCount,
            ),
          ),
          settings: RouteSettings(
            name: '/community/post',
            arguments: {'postId': postId},
          ),
        ),
      );
    } catch (e) {
      debugPrint('CommunityNavigation: Error navigating to post detail: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open post: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Navigate to create post screen with proper BLoC providers
  static Future<void> navigateToCreatePost(
    BuildContext context, {
    String? token,
    String? userId,
  }) async {
    if (!_areBlocsAvailable(context)) {
      _showBlocError(context);
      return;
    }
    
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (newContext) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<PostsBloc>()),
              BlocProvider.value(value: context.read<UserSearchBloc>()),
              BlocProvider.value(value: context.read<ProfileBloc>()),
            ],
            child: CreatePostScreen(
              token: token,
              userId: userId,
            ),
          ),
          settings: const RouteSettings(name: '/community/create-post'),
        ),
      );
    } catch (e) {
      debugPrint('CommunityNavigation: Error navigating to create post: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Create post unavailable: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Navigate to edit profile screen
  static Future<Map<String, dynamic>?> navigateToEditProfile(
    BuildContext context, {
    required String token,
    String? currentUsername,
    String? currentBio,
    String? currentProfileImage,
  }) async {
    try {
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (newContext) {
            // Try to get ProfileBloc from the original context, handle gracefully if not available
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
              // Fallback: Return screen without ProfileBloc provider (limited functionality)
              debugPrint('CommunityNavigation: ProfileBloc not available for EditProfileScreen: $e');
              return EditProfileScreen(
                token: token,
                currentUsername: currentUsername,
                currentBio: currentBio,
                currentProfileImage: currentProfileImage,
              );
            }
          },
          settings: const RouteSettings(name: '/community/edit-profile'),
        ),
      );
      return result;
    } catch (e) {
      debugPrint('CommunityNavigation: Error navigating to edit profile: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Edit profile unavailable: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Dispose resources (kept for compatibility)
  static void dispose() {
    // No resources to dispose as we use existing providers
  }
}

/// Mixin to provide easy access to community navigation from widgets
/// with built-in error handling
mixin CommunityNavigationMixin {
  Future<void> navigateToUserProfile(
    BuildContext context, {
    String? userId,
  }) async {
    try {
      await CommunityNavigation.navigateToUserProfile(context, userId: userId);
    } catch (e) {
      debugPrint('CommunityNavigationMixin: Profile navigation error: $e');
    }
  }
  
  Future<void> navigateToSearch(BuildContext context) async {
    try {
      await CommunityNavigation.navigateToSearch(context);
    } catch (e) {
      debugPrint('CommunityNavigationMixin: Search navigation error: $e');
    }
  }
  
  Future<void> navigateToPostDetail(
    BuildContext context, {
    required String postId,
    String? token,
    String? userId,
    bool? currentLikeStatus,
    int? currentLikeCount,
  }) async {
    try {
      await CommunityNavigation.navigateToPostDetail(
        context,
        postId: postId,
        token: token,
        userId: userId,
        currentLikeStatus: currentLikeStatus,
        currentLikeCount: currentLikeCount,
      );
    } catch (e) {
      debugPrint('CommunityNavigationMixin: Post detail navigation error: $e');
    }
  }
  
  Future<void> navigateToCreatePost(
    BuildContext context, {
    String? token,
    String? userId,
  }) async {
    try {
      await CommunityNavigation.navigateToCreatePost(
        context,
        token: token,
        userId: userId,
      );
    } catch (e) {
      debugPrint('CommunityNavigationMixin: Create post navigation error: $e');
    }
  }
  
  Future<Map<String, dynamic>?> navigateToEditProfile(
    BuildContext context, {
    required String token,
    String? currentUsername,
    String? currentBio,
    String? currentProfileImage,
  }) async {
    try {
      return await CommunityNavigation.navigateToEditProfile(
        context,
        token: token,
        currentUsername: currentUsername,
        currentBio: currentBio,
        currentProfileImage: currentProfileImage,
      );
    } catch (e) {
      debugPrint('CommunityNavigationMixin: Edit profile navigation error: $e');
      return null;
    }
  }
}