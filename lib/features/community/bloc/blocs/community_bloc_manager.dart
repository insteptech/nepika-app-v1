import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/community/repositories/community_repository.dart';
import '../../managers/like_state_manager.dart';
import 'posts_bloc.dart';
import 'user_search_bloc.dart';
import 'profile_bloc.dart';
import 'followers_bloc.dart';

/// Community BLoC Manager that coordinates multiple BLoCs
/// Follows Facade Pattern to provide a simplified interface to complex subsystems
/// Implements Dependency Inversion Principle by depending on abstract CommunityRepository
class CommunityBlocManager {
  final CommunityRepository repository;
  late final LikeStateManager _likeStateManager;
  
  late final PostsBloc _postsBloc;
  late final UserSearchBloc _userSearchBloc;
  late final ProfileBloc _profileBloc;
  late final FollowersBloc _followersBloc;

  CommunityBlocManager({required this.repository}) {
    _likeStateManager = LikeStateManager();
    _likeStateManager.initialize(repository);
    _postsBloc = PostsBloc(repository: repository, likeStateManager: _likeStateManager);
    _userSearchBloc = UserSearchBloc(repository: repository);
    _profileBloc = ProfileBloc(repository: repository);
    _followersBloc = FollowersBloc(repository: repository);
  }

  // Getters for accessing individual BLoCs
  PostsBloc get postsBloc => _postsBloc;
  UserSearchBloc get userSearchBloc => _userSearchBloc;
  ProfileBloc get profileBloc => _profileBloc;
  FollowersBloc get followersBloc => _followersBloc;
  LikeStateManager get likeStateManager => _likeStateManager;

  /// Provides a list of all BLoCs for easy injection into the widget tree
  List<BlocProvider> get blocProviders => [
    BlocProvider<PostsBloc>.value(value: _postsBloc),
    BlocProvider<UserSearchBloc>.value(value: _userSearchBloc),
    BlocProvider<ProfileBloc>.value(value: _profileBloc),
    BlocProvider<FollowersBloc>.value(value: _followersBloc),
  ];

  /// Closes all BLoCs
  void dispose() {
    _postsBloc.close();
    _userSearchBloc.close();
    _profileBloc.close();
    _followersBloc.close();
    _likeStateManager.dispose();
  }

  /// Factory constructor for easy instantiation with repository
  factory CommunityBlocManager.create(CommunityRepository repository) {
    return CommunityBlocManager(repository: repository);
  }
}