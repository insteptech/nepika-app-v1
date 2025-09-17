import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/community/entities/community_entities.dart';
import '../../../domain/community/repositories/community_repository.dart';
import 'community_event.dart';
import 'community_state.dart';
import 'package:flutter/foundation.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityRepository repository;
  
  // Posts state management
  List<PostEntity> _allPosts = [];
  int _currentPage = 1;
  bool _hasMorePosts = true;

  // Comments state management
  final Map<String, List<PostEntity>> _postComments = {};
  final Map<String, int> _commentPages = {};
  final Map<String, bool> _hasMoreComments = {};

  // Like/Unlike debouncing
  final Map<String, Timer?> _likeDebounceTimers = {};
  final Map<String, bool> _pendingLikeStates = {};
  final Map<String, bool> _currentLikeStates = {};

  // Follow/Unfollow debouncing
  final Map<String, Timer?> _followDebounceTimers = {};
  final Map<String, bool> _pendingFollowStates = {};
  final Map<String, bool> _currentFollowStates = {};

  CommunityBloc(this.repository) : super(CommunityInitial()) {
    
    // Post Management Events
    on<FetchCommunityPosts>(_onFetchCommunityPosts);
    on<LoadMoreCommunityPosts>(_onLoadMoreCommunityPosts);
    on<RefreshCommunityPosts>(_onRefreshCommunityPosts);
    on<CreatePost>(_onCreatePost);
    on<FetchSinglePost>(_onFetchSinglePost);
    on<UpdatePost>(_onUpdatePost);
    on<DeletePost>(_onDeletePost);

    // Comments Events
    on<FetchPostComments>(_onFetchPostComments);
    on<LoadMoreComments>(_onLoadMoreComments);

    // Like Events
    on<ToggleLikePost>(_onToggleLikePost);
    on<LikePost>(_onLikePost);
    on<UnlikePost>(_onUnlikePost);

    // Profile Management Events
    on<CreateProfile>(_onCreateProfile);
    on<FetchMyProfile>(_onFetchMyProfile);
    on<UpdateProfile>(_onUpdateProfile);

    // Follow System Events
    on<FollowUser>(_onFollowUser);
    on<UnfollowUser>(_onUnfollowUser);
    on<CheckFollowStatus>(_onCheckFollowStatus);
    on<FetchFollowers>(_onFetchFollowers);
    on<FetchFollowing>(_onFetchFollowing);

    // Block System Events
    on<BlockUser>(_onBlockUser);
    on<UnblockUser>(_onUnblockUser);
    on<CheckBlockStatus>(_onCheckBlockStatus);

    // Legacy Events
    on<SearchUsers>(_onSearchUsers);
    on<ClearUserSearch>(_onClearUserSearch);
    on<FetchUserProfile>(_onFetchUserProfile);

    // User Posts Events
    on<FetchUserThreads>(_onFetchUserThreads);
    on<FetchUserReplies>(_onFetchUserReplies);
    on<LoadMoreUserThreads>(_onLoadMoreUserThreads);
    on<LoadMoreUserReplies>(_onLoadMoreUserReplies);

    // Community Profile Events
    on<GetCommunityProfile>(_onGetCommunityProfile);
    
    // New User Search Events
    on<SearchUsersV2>(_onSearchUsersV2);
    on<ToggleUserFollow>(_onToggleUserFollow);
  }

  // Post Management Event Handlers
  Future<void> _onFetchCommunityPosts(
    FetchCommunityPosts event,
    Emitter<CommunityState> emit,
  ) async {
    emit(CommunityPostsLoading());
    try {
      _currentPage = event.page;
      final data = await repository.fetchCommunityPosts(
        token: event.token,
        page: event.page,
        pageSize: event.pageSize,
        userId: event.userId,
        followingOnly: event.followingOnly,
      );
      
      _allPosts = data.posts;
      _hasMorePosts = data.hasMore;
      
      emit(CommunityPostsLoaded(
        posts: _allPosts,
        hasMorePosts: _hasMorePosts,
        currentPage: _currentPage,
      ));
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onFetchCommunityPosts: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(CommunityPostsError(e.toString()));
    }
  }

  Future<void> _onLoadMoreCommunityPosts(
    LoadMoreCommunityPosts event,
    Emitter<CommunityState> emit,
  ) async {
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
          pageSize: event.pageSize,
          userId: event.userId,
          followingOnly: event.followingOnly,
        );
        
        _allPosts.addAll(data.posts);
        _currentPage = event.page;
        _hasMorePosts = data.hasMore;
        
        emit(CommunityPostsLoaded(
          posts: _allPosts,
          hasMorePosts: _hasMorePosts,
          currentPage: _currentPage,
        ));
      } catch (e, stackTrace) {
        debugPrint('CommunityBloc: Error in _onLoadMoreCommunityPosts: $e');
        debugPrint('CommunityBloc: Stack trace: $stackTrace');
        emit(CommunityPostsError(e.toString()));
      }
    }
  }

  Future<void> _onRefreshCommunityPosts(
    RefreshCommunityPosts event,
    Emitter<CommunityState> emit,
  ) async {
    try {
      _currentPage = 1;
      final data = await repository.fetchCommunityPosts(
        token: event.token,
        page: 1,
        pageSize: event.pageSize,
        userId: event.userId,
        followingOnly: event.followingOnly,
      );
      
      _allPosts = data.posts;
      _hasMorePosts = data.hasMore;
      
      emit(CommunityPostsLoaded(
        posts: _allPosts,
        hasMorePosts: _hasMorePosts,
        currentPage: _currentPage,
      ));
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onRefreshCommunityPosts: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(CommunityPostsError(e.toString()));
    }
  }

  Future<void> _onCreatePost(
    CreatePost event,
    Emitter<CommunityState> emit,
  ) async {
    emit(CreatePostLoading());
    try {
      final newPost = await repository.createPost(
        token: event.token,
        postData: event.postData,
      );
      
      emit(CreatePostSuccess(response: {'post': newPost}));
      
      // Optionally refresh posts after creating a new one
      add(RefreshCommunityPosts(token: event.token));
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onCreatePost: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(CreatePostError(e.toString()));
    }
  }

  Future<void> _onFetchSinglePost(
    FetchSinglePost event,
    Emitter<CommunityState> emit,
  ) async {
    emit(PostDetailLoading());
    try {
      debugPrint('CommunityBloc: Fetching single post with ID: ${event.postId}');
      final post = await repository.fetchSinglePost(
        token: event.token,
        postId: event.postId,
      );
      
      debugPrint('CommunityBloc: Successfully fetched post: ${post.id}');
      
      // Convert PostEntity to PostDetailEntity for backward compatibility
      final postDetail = PostDetailEntity(
        id: post.id,
        userId: post.userId,
        tenantId: post.tenantId,
        content: post.content,
        parentPostId: post.parentPostId,
        likeCount: post.likeCount,
        commentCount: post.commentCount,
        isEdited: post.isEdited,
        isDeleted: post.isDeleted,
        createdAt: post.createdAt,
        updatedAt: post.updatedAt ?? post.createdAt,
        author: AuthorEntity(
          id: post.userId,
          fullName: post.username,
          avatarUrl: post.userAvatar ?? '',
        ),
        likes: [],
        comments: [],
        isLikedByUser: post.isLikedByUser,
      );
      
      emit(PostDetailLoaded(post: postDetail));
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onFetchSinglePost: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(PostDetailError(e.toString()));
    }
  }

  Future<void> _onUpdatePost(
    UpdatePost event,
    Emitter<CommunityState> emit,
  ) async {
    emit(PostUpdateLoading());
    try {
      final updatedPost = await repository.updatePost(
        token: event.token,
        postId: event.postId,
        content: event.content,
      );
      
      emit(PostUpdateSuccess(updatedPost: updatedPost));
      
      // Update the post in the local list if it exists
      final postIndex = _allPosts.indexWhere((p) => p.id == event.postId);
      if (postIndex != -1) {
        _allPosts[postIndex] = updatedPost;
        if (state is CommunityPostsLoaded) {
          emit(CommunityPostsLoaded(
            posts: _allPosts,
            hasMorePosts: _hasMorePosts,
            currentPage: _currentPage,
          ));
        }
      }
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onUpdatePost: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(PostUpdateError(e.toString()));
    }
  }

  Future<void> _onDeletePost(
    DeletePost event,
    Emitter<CommunityState> emit,
  ) async {
    emit(PostDeleteLoading());
    try {
      await repository.deletePost(
        token: event.token,
        postId: event.postId,
      );
      
      emit(PostDeleteSuccess(deletedPostId: event.postId));
      
      // Remove the post from the local list
      _allPosts.removeWhere((post) => post.id == event.postId);
      if (state is CommunityPostsLoaded) {
        emit(CommunityPostsLoaded(
          posts: _allPosts,
          hasMorePosts: _hasMorePosts,
          currentPage: _currentPage,
        ));
      }
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onDeletePost: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(PostDeleteError(e.toString()));
    }
  }

  // Comments Event Handlers
  Future<void> _onFetchPostComments(
    FetchPostComments event,
    Emitter<CommunityState> emit,
  ) async {
    emit(CommentsLoading());
    try {
      final data = await repository.getPostComments(
        token: event.token,
        postId: event.postId,
        page: event.page,
        pageSize: event.pageSize,
      );
      
      _postComments[event.postId] = data.comments;
      _commentPages[event.postId] = event.page;
      _hasMoreComments[event.postId] = data.hasMore;
      
      emit(CommentsLoaded(
        comments: data.comments,
        parentPostId: event.postId,
        hasMoreComments: data.hasMore,
        currentPage: event.page,
        total: data.total,
      ));
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onFetchPostComments: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(CommentsError(e.toString()));
    }
  }

  Future<void> _onLoadMoreComments(
    LoadMoreComments event,
    Emitter<CommunityState> emit,
  ) async {
    final hasMore = _hasMoreComments[event.postId] ?? false;
    final currentComments = _postComments[event.postId] ?? [];
    final currentPage = _commentPages[event.postId] ?? 1;

    if (hasMore) {
      emit(CommentsLoadingMore(
        currentComments: currentComments,
        parentPostId: event.postId,
        currentPage: currentPage,
      ));
      
      try {
        final data = await repository.getPostComments(
          token: event.token,
          postId: event.postId,
          page: event.page,
          pageSize: event.pageSize,
        );
        
        currentComments.addAll(data.comments);
        _postComments[event.postId] = currentComments;
        _commentPages[event.postId] = event.page;
        _hasMoreComments[event.postId] = data.hasMore;
        
        emit(CommentsLoaded(
          comments: currentComments,
          parentPostId: event.postId,
          hasMoreComments: data.hasMore,
          currentPage: event.page,
          total: data.total,
        ));
      } catch (e, stackTrace) {
        debugPrint('CommunityBloc: Error in _onLoadMoreComments: $e');
        debugPrint('CommunityBloc: Stack trace: $stackTrace');
        emit(CommentsError(e.toString()));
      }
    }
  }

  // Like Event Handlers
  Future<void> _onToggleLikePost(
    ToggleLikePost event,
    Emitter<CommunityState> emit,
  ) async {
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
        emit(PostLikeLoading(postId: postId, isLiking: finalState));
        
        final response = await repository.toggleLikePost(
          token: event.token,
          postId: postId,
        );
        
        emit(PostLikeToggleSuccess(
          postId: postId,
          isLiked: response['is_liked'] as bool,
          likeCount: response['like_count'] as int,
          message: response['message'] as String,
        ));
        
        // Update the post in the local list
        final postIndex = _allPosts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          // Create updated post with new like state
          final updatedPost = PostEntity(
            id: _allPosts[postIndex].id,
            userId: _allPosts[postIndex].userId,
            tenantId: _allPosts[postIndex].tenantId,
            content: _allPosts[postIndex].content,
            parentPostId: _allPosts[postIndex].parentPostId,
            likeCount: response['like_count'] as int,
            commentCount: _allPosts[postIndex].commentCount,
            isEdited: _allPosts[postIndex].isEdited,
            isDeleted: _allPosts[postIndex].isDeleted,
            createdAt: _allPosts[postIndex].createdAt,
            updatedAt: _allPosts[postIndex].updatedAt,
            username: _allPosts[postIndex].username,
            userAvatar: _allPosts[postIndex].userAvatar,
            isLikedByUser: response['is_liked'] as bool,
          );
          _allPosts[postIndex] = updatedPost;
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
  }

  Future<void> _onLikePost(
    LikePost event,
    Emitter<CommunityState> emit,
  ) async {
    emit(PostLikeLoading(postId: event.postId, isLiking: true));
    try {
      final response = await repository.toggleLikePost(
        token: event.token,
        postId: event.postId,
      );
      emit(PostLikeToggleSuccess(
        postId: event.postId,
        isLiked: response['is_liked'] as bool,
        likeCount: response['like_count'] as int,
        message: response['message'] as String,
      ));
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onLikePost: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      
      String errorMessage = 'Failed to like post';
      if (e.toString().contains('500')) {
        errorMessage = 'Server error: You may need to create your community profile first';
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        errorMessage = 'Authentication error: Please log in again';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Post not found';
      }
      
      emit(PostLikeError(
        postId: event.postId,
        message: errorMessage,
        wasLiking: true,
      ));
    }
  }

  Future<void> _onUnlikePost(
    UnlikePost event,
    Emitter<CommunityState> emit,
  ) async {
    emit(PostLikeLoading(postId: event.postId, isLiking: false));
    try {
      final response = await repository.toggleLikePost(
        token: event.token,
        postId: event.postId,
      );
      emit(PostLikeToggleSuccess(
        postId: event.postId,
        isLiked: response['is_liked'] as bool,
        likeCount: response['like_count'] as int,
        message: response['message'] as String,
      ));
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onUnlikePost: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      
      String errorMessage = 'Failed to unlike post';
      if (e.toString().contains('500')) {
        errorMessage = 'Server error: You may need to create your community profile first';
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        errorMessage = 'Authentication error: Please log in again';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Post not found';
      }
      
      emit(PostLikeError(
        postId: event.postId,
        message: errorMessage,
        wasLiking: false,
      ));
    }
  }

  // Profile Management Event Handlers
  Future<void> _onCreateProfile(
    CreateProfile event,
    Emitter<CommunityState> emit,
  ) async {
    debugPrint('CommunityBloc: _onCreateProfile called');
    debugPrint('CommunityBloc: Token: ${event.token}');
    debugPrint('CommunityBloc: Profile data: ${event.profileData.toJson()}');
    
    emit(ProfileCreateLoading());
    debugPrint('CommunityBloc: Emitted ProfileCreateLoading');
    
    try {
      debugPrint('CommunityBloc: Calling repository.createProfile');
      final profile = await repository.createProfile(
        token: event.token,
        profileData: event.profileData,
      );
      debugPrint('CommunityBloc: Profile created successfully: ${profile.toString()}');
      emit(ProfileCreateSuccess(profile: profile));
      debugPrint('CommunityBloc: Emitted ProfileCreateSuccess');
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onCreateProfile: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(ProfileCreateError(e.toString()));
      debugPrint('CommunityBloc: Emitted ProfileCreateError');
    }
  }

  Future<void> _onFetchMyProfile(
    FetchMyProfile event,
    Emitter<CommunityState> emit,
  ) async {
    emit(MyProfileLoading());
    try {
      final profile = await repository.getMyProfile(
        token: event.token,
        userId: event.userId,
      );
      emit(MyProfileLoaded(profile: profile));
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onFetchMyProfile: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(MyProfileError(e.toString()));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<CommunityState> emit,
  ) async {
    emit(ProfileUpdateLoading());
    try {
      final updatedProfile = await repository.updateProfile(
        token: event.token,
        profileData: event.profileData,
      );
      emit(ProfileUpdateSuccess(updatedProfile: updatedProfile));
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onUpdateProfile: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(ProfileUpdateError(e.toString()));
    }
  }

  // Follow System Event Handlers
  Future<void> _onFollowUser(
    FollowUser event,
    Emitter<CommunityState> emit,
  ) async {
    emit(FollowLoading(userId: event.userId, isFollowing: true));
    try {
      final response = await repository.followUser(
        token: event.token,
        userId: event.userId,
      );
      emit(FollowSuccess(
        userId: event.userId,
        isFollowing: response.isFollowing,
        message: response.message,
      ));
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onFollowUser: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(FollowError(
        userId: event.userId,
        message: e.toString(),
        wasFollowing: true,
      ));
    }
  }

  Future<void> _onUnfollowUser(
    UnfollowUser event,
    Emitter<CommunityState> emit,
  ) async {
    emit(FollowLoading(userId: event.userId, isFollowing: false));
    try {
      final response = await repository.unfollowUser(
        token: event.token,
        userId: event.userId,
      );
      emit(FollowSuccess(
        userId: event.userId,
        isFollowing: response.isFollowing,
        message: response.message,
      ));
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onUnfollowUser: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(FollowError(
        userId: event.userId,
        message: e.toString(),
        wasFollowing: false,
      ));
    }
  }

  Future<void> _onCheckFollowStatus(
    CheckFollowStatus event,
    Emitter<CommunityState> emit,
  ) async {
    emit(FollowStatusLoading());
    try {
      final status = await repository.checkFollowStatus(
        token: event.token,
        userId: event.userId,
      );
      emit(FollowStatusLoaded(
        userId: event.userId,
        isFollowing: status.isFollowing,
      ));
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onCheckFollowStatus: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(FollowStatusError(e.toString()));
    }
  }

  Future<void> _onFetchFollowers(
    FetchFollowers event,
    Emitter<CommunityState> emit,
  ) async {
    emit(FollowersLoading());
    try {
      final data = await repository.getFollowers(
        token: event.token,
        userId: event.userId,
        page: event.page,
        pageSize: event.pageSize,
      );
      
      emit(FollowersLoaded(
        followers: data.users,
        userId: event.userId,
        hasMoreFollowers: data.hasMore,
        currentPage: event.page,
        total: data.total,
      ));
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onFetchFollowers: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(FollowersError(e.toString()));
    }
  }

  Future<void> _onFetchFollowing(
    FetchFollowing event,
    Emitter<CommunityState> emit,
  ) async {
    emit(FollowingLoading());
    try {
      final data = await repository.getFollowing(
        token: event.token,
        userId: event.userId,
        page: event.page,
        pageSize: event.pageSize,
      );
      
      emit(FollowingLoaded(
        following: data.users,
        userId: event.userId,
        hasMoreFollowing: data.hasMore,
        currentPage: event.page,
        total: data.total,
      ));
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onFetchFollowing: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(FollowingError(e.toString()));
    }
  }

  // Legacy Event Handlers
  Future<void> _onSearchUsers(
    SearchUsers event,
    Emitter<CommunityState> emit,
  ) async {
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
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onSearchUsers: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(UserSearchError(e.toString()));
    }
  }

  Future<void> _onClearUserSearch(
    ClearUserSearch event,
    Emitter<CommunityState> emit,
  ) async {
    emit(UserSearchEmpty());
  }

  Future<void> _onFetchUserProfile(
    FetchUserProfile event,
    Emitter<CommunityState> emit,
  ) async {
    debugPrint('BLoC: Received FetchUserProfile event for userId: ${event.userId}');
    emit(UserProfileLoading());
    try {
      debugPrint('BLoC: Calling repository.fetchUserProfile...');
      final response = await repository.fetchUserProfile(
        token: event.token,
        userId: event.userId,
      );
      debugPrint('BLoC: Repository call successful, emitting UserProfileLoaded');
      emit(UserProfileLoaded(profileData: response));
    } catch (e, stackTrace) {
      debugPrint('BLoC: Error in fetchUserProfile: $e');
      debugPrint('BLoC: Stack trace: $stackTrace');
      emit(UserProfileError(e.toString()));
    }
  }

  // Block System Event Handlers
  Future<void> _onBlockUser(
    BlockUser event,
    Emitter<CommunityState> emit,
  ) async {
    emit(BlockUserLoading(userId: event.blockData.userId));
    try {
      final response = await repository.blockUser(
        token: event.token,
        blockData: event.blockData,
      );
      emit(BlockUserSuccess(
        userId: event.blockData.userId,
        isBlocked: response.isBlocked,
        message: response.message,
      ));
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onBlockUser: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(BlockUserError(
        userId: event.blockData.userId,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onUnblockUser(
    UnblockUser event,
    Emitter<CommunityState> emit,
  ) async {
    emit(UnblockUserLoading(userId: event.userId));
    try {
      final response = await repository.unblockUser(
        token: event.token,
        userId: event.userId,
      );
      emit(UnblockUserSuccess(
        userId: event.userId,
        isBlocked: response.isBlocked,
        message: response.message,
      ));
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onUnblockUser: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(UnblockUserError(
        userId: event.userId,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onCheckBlockStatus(
    CheckBlockStatus event,
    Emitter<CommunityState> emit,
  ) async {
    emit(BlockStatusLoading());
    try {
      final status = await repository.checkBlockStatus(
        token: event.token,
        userId: event.userId,
      );
      emit(BlockStatusLoaded(
        userId: event.userId,
        isBlocked: status.isBlocked,
      ));
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onCheckBlockStatus: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(BlockStatusError(e.toString()));
    }
  }

  // User Posts Event Handlers
  Future<void> _onFetchUserThreads(
    FetchUserThreads event,
    Emitter<CommunityState> emit,
  ) async {
    emit(UserThreadsLoading(userId: event.userId));
    try {
      final response = await repository.getUserThreads(
        token: event.token,
        userId: event.userId,
        page: event.page,
        pageSize: event.pageSize,
      );
      
      emit(UserThreadsLoaded(
        userId: event.userId,
        threads: response.posts,
        hasMoreThreads: response.hasMore,
        currentPage: response.page,
        total: response.total,
      ));
    } catch (e) {
      emit(UserThreadsError(
        userId: event.userId,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onFetchUserReplies(
    FetchUserReplies event,
    Emitter<CommunityState> emit,
  ) async {
    emit(UserRepliesLoading(userId: event.userId));
    try {
      final response = await repository.getUserReplies(
        token: event.token,
        userId: event.userId,
        page: event.page,
        pageSize: event.pageSize,
      );
      
      emit(UserRepliesLoaded(
        userId: event.userId,
        replies: response.posts,
        hasMoreReplies: response.hasMore,
        currentPage: response.page,
        total: response.total,
      ));
    } catch (e) {
      emit(UserRepliesError(
        userId: event.userId,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreUserThreads(
    LoadMoreUserThreads event,
    Emitter<CommunityState> emit,
  ) async {
    // Get current state to preserve existing threads
    final currentState = state;
    if (currentState is UserThreadsLoaded && currentState.userId == event.userId) {
      emit(UserThreadsLoadingMore(userId: event.userId));
      
      try {
        final response = await repository.getUserThreads(
          token: event.token,
          userId: event.userId,
          page: event.page,
          pageSize: event.pageSize,
        );
        
        final updatedThreads = List<PostEntity>.from(currentState.threads);
        updatedThreads.addAll(response.posts);
        
        emit(UserThreadsLoaded(
          userId: event.userId,
          threads: updatedThreads,
          hasMoreThreads: response.hasMore,
          currentPage: response.page,
          total: response.total,
        ));
      } catch (e) {
        // Revert to previous state on error
        emit(currentState);
        emit(UserThreadsError(
          userId: event.userId,
          message: e.toString(),
        ));
      }
    }
  }

  Future<void> _onLoadMoreUserReplies(
    LoadMoreUserReplies event,
    Emitter<CommunityState> emit,
  ) async {
    // Get current state to preserve existing replies
    final currentState = state;
    if (currentState is UserRepliesLoaded && currentState.userId == event.userId) {
      emit(UserRepliesLoadingMore(userId: event.userId));
      
      try {
        final response = await repository.getUserReplies(
          token: event.token,
          userId: event.userId,
          page: event.page,
          pageSize: event.pageSize,
        );
        
        final updatedReplies = List<PostEntity>.from(currentState.replies);
        updatedReplies.addAll(response.posts);
        
        emit(UserRepliesLoaded(
          userId: event.userId,
          replies: updatedReplies,
          hasMoreReplies: response.hasMore,
          currentPage: response.page,
          total: response.total,
        ));
      } catch (e) {
        // Revert to previous state on error
        emit(currentState);
        emit(UserRepliesError(
          userId: event.userId,
          message: e.toString(),
        ));
      }
    }
  }

  Future<void> _onGetCommunityProfile(
    GetCommunityProfile event,
    Emitter<CommunityState> emit,
  ) async {
    emit(CommunityProfileLoading(userId: event.userId));
    try {
      final profile = await repository.getUserProfile(
        token: event.token,
        userId: event.userId,
      );
      
      emit(CommunityProfileLoaded(profile: profile));
    } catch (e) {
      emit(CommunityProfileError(
        userId: event.userId,
        message: e.toString(),
      ));
    }
  }

  // New User Search Event Handlers
  Future<void> _onSearchUsersV2(
    SearchUsersV2 event,
    Emitter<CommunityState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(UserSearchV2Empty());
      return;
    }
    
    emit(UserSearchV2Loading(query: event.query));
    try {
      final response = await repository.searchUsersV2(
        token: event.token,
        query: event.query,
        page: event.page,
        pageSize: event.pageSize,
      );
      
      emit(UserSearchV2Loaded(
        response: response,
        users: response.users,
      ));
    } catch (e, stackTrace) {
      debugPrint('CommunityBloc: Error in _onSearchUsersV2: $e');
      debugPrint('CommunityBloc: Stack trace: $stackTrace');
      emit(UserSearchV2Error(
        query: event.query,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onToggleUserFollow(
    ToggleUserFollow event,
    Emitter<CommunityState> emit,
  ) async {
    final userId = event.userId;
    final currentlyFollowing = event.currentlyFollowing;
    final newFollowingState = !currentlyFollowing;
    
    // Store current follow state for this user
    _currentFollowStates[userId] = newFollowingState;
    
    // Emit immediate UI update
    emit(UserFollowToggled(
      userId: userId,
      isFollowing: newFollowingState,
      message: newFollowingState ? 'Following' : 'Unfollowing',
    ));
    
    // Cancel any existing timer for this user
    _followDebounceTimers[userId]?.cancel();
    
    // Store the pending state
    _pendingFollowStates[userId] = newFollowingState;
    
    // Start new debounce timer
    _followDebounceTimers[userId] = Timer(const Duration(milliseconds: 800), () async {
      final finalState = _pendingFollowStates[userId] ?? newFollowingState;
      
      try {
        emit(UserFollowToggling(userId: userId));
        
        if (finalState) {
          // Follow user
          final response = await repository.followUser(
            token: event.token,
            userId: userId,
          );
          emit(UserFollowToggled(
            userId: userId,
            isFollowing: response.isFollowing,
            message: response.message,
          ));
        } else {
          // Unfollow user
          final response = await repository.unfollowUser(
            token: event.token,
            userId: userId,
          );
          emit(UserFollowToggled(
            userId: userId,
            isFollowing: response.isFollowing,
            message: response.message,
          ));
        }
        
        // Update the current state
        _currentFollowStates[userId] = finalState;
        
      } catch (e) {
        // Revert the UI state on error
        _currentFollowStates[userId] = currentlyFollowing;
        emit(UserFollowError(
          userId: userId,
          message: e.toString(),
        ));
        // Emit the reverted state
        emit(UserFollowToggled(
          userId: userId,
          isFollowing: currentlyFollowing,
          message: currentlyFollowing ? 'Following' : 'Follow',
        ));
      } finally {
        // Clean up
        _followDebounceTimers.remove(userId);
        _pendingFollowStates.remove(userId);
      }
    });
  }

  @override
  Future<void> close() {
    // Cancel all pending timers
    for (final timer in _likeDebounceTimers.values) {
      timer?.cancel();
    }
    for (final timer in _followDebounceTimers.values) {
      timer?.cancel();
    }
    _likeDebounceTimers.clear();
    _followDebounceTimers.clear();
    _pendingLikeStates.clear();
    _currentLikeStates.clear();
    _pendingFollowStates.clear();
    _currentFollowStates.clear();
    _postComments.clear();
    _commentPages.clear();
    _hasMoreComments.clear();
    return super.close();
  }

  // Helper methods
  bool getCurrentLikeState(String postId) {
    return _currentLikeStates[postId] ?? false;
  }

  bool getCurrentFollowState(String userId) {
    return _currentFollowStates[userId] ?? false;
  }

  List<PostEntity> getCommentsForPost(String postId) {
    return _postComments[postId] ?? [];
  }

  bool hasMoreCommentsForPost(String postId) {
    return _hasMoreComments[postId] ?? false;
  }
}