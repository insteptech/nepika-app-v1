import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/blocs/posts_bloc.dart';
import '../bloc/blocs/user_search_bloc.dart';
import '../bloc/blocs/profile_bloc.dart';
import '../bloc/states/posts_state.dart';
import '../bloc/states/user_search_state.dart';
import '../bloc/states/profile_state.dart';
import '../../../domain/community/entities/community_entities.dart';

/// Mixin that provides state recovery functionality for community screens
/// Solves the race condition where BLoC emits states before listeners are ready
mixin CommunityStateRecoveryMixin<T extends StatefulWidget> on State<T> {
  
  /// Recovers PostDetailState if available for a specific post ID
  bool recoverPostDetailState(String postId, Function(PostDetailEntity) onPostLoaded) {
    try {
      debugPrint('StateRecovery: Checking for existing PostDetailState for post $postId');
      final currentState = context.read<PostsBloc>().state;
      debugPrint('StateRecovery: Current PostsBloc state: ${currentState.runtimeType}');
      
      if (currentState is PostDetailLoaded && currentState.post.id == postId) {
        debugPrint('StateRecovery: Found existing PostDetailLoaded state, recovering');
        onPostLoaded(currentState.post);
        return true;
      }
      
      debugPrint('StateRecovery: No existing PostDetailLoaded state found');
      return false;
    } catch (e) {
      debugPrint('StateRecovery: Error checking PostDetailState: $e');
      return false;
    }
  }
  
  /// Recovers UserSearchState if available
  bool recoverUserSearchState(Function(List<dynamic>) onUsersLoaded) {
    try {
      debugPrint('StateRecovery: Checking for existing UserSearchState');
      final currentState = context.read<UserSearchBloc>().state;
      debugPrint('StateRecovery: Current UserSearchBloc state: ${currentState.runtimeType}');
      
      if (currentState is UserSearchLoaded) {
        debugPrint('StateRecovery: Found existing UserSearchLoaded state, recovering');
        onUsersLoaded(currentState.users);
        return true;
      }
      
      debugPrint('StateRecovery: No existing UserSearchLoaded state found');
      return false;
    } catch (e) {
      debugPrint('StateRecovery: Error checking UserSearchState: $e');
      return false;
    }
  }
  
  /// Recovers ProfileState if available for a specific user ID
  bool recoverProfileState(String userId, Function(CommunityProfileEntity) onProfileLoaded) {
    try {
      debugPrint('StateRecovery: Checking for existing ProfileState for user $userId');
      final currentState = context.read<ProfileBloc>().state;
      debugPrint('StateRecovery: Current ProfileBloc state: ${currentState.runtimeType}');
      
      if (currentState is CommunityProfileLoaded && currentState.profile.id == userId) {
        debugPrint('StateRecovery: Found existing CommunityProfileLoaded state, recovering');
        onProfileLoaded(currentState.profile);
        return true;
      }
      
      debugPrint('StateRecovery: No existing CommunityProfileLoaded state found');
      return false;
    } catch (e) {
      debugPrint('StateRecovery: Error checking ProfileState: $e');
      return false;
    }
  }
  
  /// Recovers PostsState if available (for community feed)
  bool recoverPostsState(Function(List<PostEntity>) onPostsLoaded) {
    try {
      debugPrint('StateRecovery: Checking for existing PostsState');
      final currentState = context.read<PostsBloc>().state;
      debugPrint('StateRecovery: Current PostsBloc state: ${currentState.runtimeType}');
      
      if (currentState is PostsLoaded && currentState.posts.isNotEmpty) {
        debugPrint('StateRecovery: Found existing PostsLoaded state with ${currentState.posts.length} posts, recovering');
        onPostsLoaded(currentState.posts);
        return true;
      }
      
      debugPrint('StateRecovery: No existing PostsLoaded state found');
      return false;
    } catch (e) {
      debugPrint('StateRecovery: Error checking PostsState: $e');
      return false;
    }
  }
  
  /// Generic state recovery that tries after a frame callback
  void recoverStateAfterBuild(VoidCallback recoveryCallback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('StateRecovery: Attempting state recovery after frame callback');
        recoveryCallback();
      }
    });
  }
  
  /// Ensures BLoC events are dispatched after listeners are ready
  void dispatchAfterListeners(VoidCallback eventDispatcher) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('StateRecovery: Dispatching BLoC events after listeners are ready');
        eventDispatcher();
      }
    });
  }
  
  /// Helper to check if a BLoC is available in the context
  bool isBlocAvailable<B extends StateStreamable>() {
    try {
      context.read<B>();
      return true;
    } catch (e) {
      debugPrint('StateRecovery: BLoC ${B.toString()} not available: $e');
      return false;
    }
  }
  
  /// Helper to safely access BLoC state
  S? safeGetBlocState<B extends StateStreamable<S>, S>() {
    try {
      return context.read<B>().state;
    } catch (e) {
      debugPrint('StateRecovery: Error getting state for ${B.toString()}: $e');
      return null;
    }
  }
}