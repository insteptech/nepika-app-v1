import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/community/entities/community_entities.dart';
import '../../../domain/community/repositories/community_repository.dart';
import 'community_event.dart';
import 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityRepository repository;
  List<PostEntity> _allPosts = [];
  int _currentPage = 1;
  bool _hasMorePosts = true;

  // Like/Unlike debouncing
  final Map<String, Timer?> _likeDebounceTimers = {};
  final Map<String, bool> _pendingLikeStates = {};
  final Map<String, bool> _currentLikeStates = {};

  CommunityBloc(this.repository) : super(CommunityInitial()) {
    
    on<FetchCommunityPosts>((event, emit) async {
      emit(CommunityPostsLoading());
      try {
        _currentPage = event.page;
        final data = await repository.fetchCommunityPosts(
          token: event.token,
          page: event.page,
          limit: event.limit,
        );
        
        _allPosts = data.posts.map((post) => PostEntity.fromJson(post)).toList();
        _hasMorePosts = data.posts.length >= event.limit;
        
        emit(CommunityPostsLoaded(
          posts: _allPosts,
          hasMorePosts: _hasMorePosts,
          currentPage: _currentPage,
        ));
      } catch (e) {
        emit(CommunityPostsError(e.toString()));
      }
    });

    on<LoadMoreCommunityPosts>((event, emit) async {
      if (state is CommunityPostsLoaded && _hasMorePosts) {
        final currentState = state as CommunityPostsLoaded;
        emit(CommunityPostsLoadingMore(
          currentPosts: currentState.posts,
          currentPage: currentState.currentPage,
        ));
        
        try {
          final data = await repository.fetchCommunityPosts(
            token: event.token,
            page: event.page,
            limit: event.limit,
          );
          
          final newPosts = data.posts.map((post) => PostEntity.fromJson(post)).toList();
          _allPosts.addAll(newPosts);
          _currentPage = event.page;
          _hasMorePosts = newPosts.length >= event.limit;
          
          emit(CommunityPostsLoaded(
            posts: _allPosts,
            hasMorePosts: _hasMorePosts,
            currentPage: _currentPage,
          ));
        } catch (e) {
          emit(CommunityPostsError(e.toString()));
        }
      }
    });

    on<RefreshCommunityPosts>((event, emit) async {
      try {
        _currentPage = 1;
        final data = await repository.fetchCommunityPosts(
          token: event.token,
          page: 1,
          limit: event.limit,
        );
        
        _allPosts = data.posts.map((post) => PostEntity.fromJson(post)).toList();
        _hasMorePosts = data.posts.length >= event.limit;
        
        emit(CommunityPostsLoaded(
          posts: _allPosts,
          hasMorePosts: _hasMorePosts,
          currentPage: _currentPage,
        ));
      } catch (e) {
        emit(CommunityPostsError(e.toString()));
      }
    });

    on<SearchUsers>((event, emit) async {
      if (event.query.isEmpty) {
        emit(UserSearchEmpty());
        return;
      }
      
      emit(UserSearchLoading());
      try {
        final data = await repository.searchUsers(
          token: event.token,
          query: event.query,
        );
        
        final users = data.users.map((user) => SearchUserEntity.fromJson(user)).toList();
        emit(UserSearchLoaded(users: users));
      } catch (e) {
        emit(UserSearchError(e.toString()));
      }
    });

    on<ClearUserSearch>((event, emit) async {
      emit(UserSearchEmpty());
    });

    on<CreatePost>((event, emit) async {
      emit(CreatePostLoading());
      try {
        final response = await repository.createPost(
          token: event.token,
          postData: event.postData,
        );
        
        emit(CreatePostSuccess(response: response.response));
        
        // Optionally refresh posts after creating a new one
        add(RefreshCommunityPosts(token: event.token));
      } catch (e) {
        emit(CreatePostError(e.toString()));
      }
    });

    on<FetchSinglePost>((event, emit) async {
      emit(PostDetailLoading());
      try {
        print('CommunityBloc: Fetching single post with ID: ${event.postId}');
        final post = await repository.fetchSinglePost(
          token: event.token,
          postId: event.postId,
        );
        
        print('CommunityBloc: Successfully fetched post: ${post.postId}');
        emit(PostDetailLoaded(post: post));
      } catch (e, stackTrace) {
        print('CommunityBloc: Error fetching single post: $e');
        print('CommunityBloc: Stack trace: $stackTrace');
        emit(PostDetailError(e.toString()));
      }
    });

    on<ToggleLikePost>((event, emit) async {
      final postId = event.postId;
      final currentStatus = event.currentLikeStatus;
      final newStatus = !currentStatus;
      
      // Store current like state for this post
      _currentLikeStates[postId] = newStatus;
      
      // Emit immediate UI update
      emit(PostLikeToggled(postId: postId, isLiked: newStatus));
      
      // Cancel any existing timer for this post
      _likeDebounceTimers[postId]?.cancel();
      
      // Store the pending state
      _pendingLikeStates[postId] = newStatus;
      
      // Start new debounce timer
      _likeDebounceTimers[postId] = Timer(const Duration(seconds: 1), () async {
        final finalState = _pendingLikeStates[postId] ?? newStatus;
        
        try {
          if (finalState) {
            // User wants to like the post
            emit(PostLikeLoading(postId: postId, isLiking: true));
            final response = await repository.likePost(
              token: event.token,
              postId: postId,
            );
            emit(PostLikeSuccess(
              postId: postId,
              isLiked: true,
              likeResponse: response,
            ));
          } else {
            // User wants to unlike the post
            emit(PostLikeLoading(postId: postId, isLiking: false));
            final response = await repository.unlikePost(
              token: event.token,
              postId: postId,
            );
            emit(PostLikeSuccess(
              postId: postId,
              isLiked: false,
              unlikeResponse: response,
            ));
          }
        } catch (e) {
          // Revert the UI state on error
          _currentLikeStates[postId] = currentStatus;
          emit(PostLikeError(
            postId: postId,
            message: e.toString(),
            wasLiking: finalState,
          ));
          // Emit the reverted state
          emit(PostLikeToggled(postId: postId, isLiked: currentStatus));
        } finally {
          // Clean up
          _likeDebounceTimers.remove(postId);
          _pendingLikeStates.remove(postId);
        }
      });
    });

    on<LikePost>((event, emit) async {
      emit(PostLikeLoading(postId: event.postId, isLiking: true));
      try {
        final response = await repository.likePost(
          token: event.token,
          postId: event.postId,
        );
        emit(PostLikeSuccess(
          postId: event.postId,
          isLiked: true,
          likeResponse: response,
        ));
      } catch (e) {
        emit(PostLikeError(
          postId: event.postId,
          message: e.toString(),
          wasLiking: true,
        ));
      }
    });

    on<UnlikePost>((event, emit) async {
      emit(PostLikeLoading(postId: event.postId, isLiking: false));
      try {
        final response = await repository.unlikePost(
          token: event.token,
          postId: event.postId,
        );
        emit(PostLikeSuccess(
          postId: event.postId,
          isLiked: false,
          unlikeResponse: response,
        ));
      } catch (e) {
        emit(PostLikeError(
          postId: event.postId,
          message: e.toString(),
          wasLiking: false,
        ));
      }
    });

    on<FetchUserProfile>((event, emit) async {
      print('BLoC: Received FetchUserProfile event for userId: ${event.userId}');
      emit(UserProfileLoading());
      try {
        print('BLoC: Calling repository.fetchUserProfile...');
        final response = await repository.fetchUserProfile(
          token: event.token,
          userId: event.userId,
        );
        print('BLoC: Repository call successful, emitting UserProfileLoaded');
        emit(UserProfileLoaded(profileData: response));
      } catch (e) {
        print('BLoC: Error in fetchUserProfile: $e');
        emit(UserProfileError(e.toString()));
      }
    });
  }

  @override
  Future<void> close() {
    // Cancel all pending timers
    for (final timer in _likeDebounceTimers.values) {
      timer?.cancel();
    }
    _likeDebounceTimers.clear();
    _pendingLikeStates.clear();
    _currentLikeStates.clear();
    return super.close();
  }

  bool getCurrentLikeState(String postId) {
    return _currentLikeStates[postId] ?? false;
  }
}
