import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/community/entities/community_entities.dart';
import '../../../../domain/community/repositories/community_repository.dart';
import '../events/profile_event.dart';
import '../states/profile_state.dart';

/// Profile BLoC responsible for profile management, follow system, and user content
/// Follows Single Responsibility Principle - handles profile-related operations
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final CommunityRepository repository;

  ProfileBloc({required this.repository}) : super(ProfileInitial()) {
    // Profile management events
    on<CreateProfile>(_onCreateProfile);
    on<FetchMyProfile>(_onFetchMyProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<UpdateProfileWithImageUpload>(_onUpdateProfileWithImageUpload);
    on<UploadProfileImage>(_onUploadProfileImage);
    on<FetchUserProfile>(_onFetchUserProfile);
    on<GetCommunityProfile>(_onGetCommunityProfile);

    // Follow system events
    on<FollowUser>(_onFollowUser);
    on<UnfollowUser>(_onUnfollowUser);
    on<CheckFollowStatus>(_onCheckFollowStatus);
    on<FetchFollowers>(_onFetchFollowers);
    on<FetchFollowing>(_onFetchFollowing);

    // User posts events
    on<FetchUserThreads>(_onFetchUserThreads);
    on<FetchUserReplies>(_onFetchUserReplies);
    on<LoadMoreUserThreads>(_onLoadMoreUserThreads);
    on<LoadMoreUserReplies>(_onLoadMoreUserReplies);

    // Block system events
    on<BlockUser>(_onBlockUser);
    on<UnblockUser>(_onUnblockUser);
    on<CheckBlockStatus>(_onCheckBlockStatus);
  }

  // Profile Management Handlers
  Future<void> _onCreateProfile(
    CreateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    debugPrint('ProfileBloc: _onCreateProfile called');
    debugPrint('ProfileBloc: Token: ${event.token}');
    debugPrint('ProfileBloc: Profile data: ${event.profileData.toJson()}');
    
    // Emit optimistic state first
    emit(ProfileCreateStarted(profileData: event.profileData));
    debugPrint('ProfileBloc: Emitted ProfileCreateStarted');
    
    // Then emit loading state
    emit(ProfileCreateLoading());
    debugPrint('ProfileBloc: Emitted ProfileCreateLoading');
    
    try {
      debugPrint('ProfileBloc: Calling repository.createProfile');
      final profile = await repository.createProfile(
        token: event.token,
        profileData: event.profileData,
      );
      debugPrint('ProfileBloc: Profile created successfully: ${profile.toString()}');
      emit(ProfileCreateSuccess(profile: profile));
      debugPrint('ProfileBloc: Emitted ProfileCreateSuccess');
    } catch (e, stackTrace) {
      debugPrint('ProfileBloc: Error in _onCreateProfile: $e');
      debugPrint('ProfileBloc: Stack trace: $stackTrace');
      emit(ProfileCreateError(e.toString()));
      debugPrint('ProfileBloc: Emitted ProfileCreateError');
    }
  }

  Future<void> _onFetchMyProfile(
    FetchMyProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(MyProfileLoading());
    try {
      final profile = await repository.getMyProfile(
        token: event.token,
        userId: event.userId,
      );
      emit(MyProfileLoaded(profile: profile));
    } catch (e, stackTrace) {
      debugPrint('ProfileBloc: Error in _onFetchMyProfile: $e');
      debugPrint('ProfileBloc: Stack trace: $stackTrace');
      emit(MyProfileError(e.toString()));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    // Emit optimistic state first
    emit(ProfileUpdateStarted(profileData: event.profileData));
    debugPrint('ProfileBloc: Emitted ProfileUpdateStarted');
    
    emit(ProfileUpdateLoading());
    try {
      final updatedProfile = await repository.updateProfile(
        token: event.token,
        profileData: event.profileData,
      );
      emit(ProfileUpdateSuccess(updatedProfile: updatedProfile));
    } catch (e, stackTrace) {
      debugPrint('ProfileBloc: Error in _onUpdateProfile: $e');
      debugPrint('ProfileBloc: Stack trace: $stackTrace');
      emit(ProfileUpdateError(e.toString()));
    }
  }

  Future<void> _onUpdateProfileWithImageUpload(
    UpdateProfileWithImageUpload event,
    Emitter<ProfileState> emit,
  ) async {
    debugPrint('ProfileBloc: _onUpdateProfileWithImageUpload called');
    debugPrint('ProfileBloc: Image path: ${event.imagePath}');
    
    try {
      // Emit optimistic state first
      emit(ProfileUpdateStarted(profileData: event.profileData));
      
      String? s3ImageUrl;
      
      // If there's an image to upload, upload it first
      if (event.imagePath != null) {
        debugPrint('ProfileBloc: Uploading image...');
        emit(ImageUploadInProgress(progress: 'Uploading image...'));
        
        final uploadResult = await repository.uploadProfileImage(
          token: event.token,
          imagePath: event.imagePath!,
          userId: event.userId,
        );
        
        s3ImageUrl = uploadResult['s3_url'] as String?;
        debugPrint('ProfileBloc: Image uploaded successfully, S3 URL: $s3ImageUrl');
        
        if (s3ImageUrl != null) {
          emit(ImageUploadSuccess(s3Url: s3ImageUrl));
        }
      }
      
      // Create updated profile data with S3 URL
      final updatedProfileData = UpdateProfileEntity(
        username: event.profileData.username,
        bio: event.profileData.bio,
        profileImageUrl: s3ImageUrl ?? event.profileData.profileImageUrl,
        bannerImageUrl: event.profileData.bannerImageUrl,
        isPrivate: event.profileData.isPrivate,
        settings: event.profileData.settings,
      );
      
      debugPrint('ProfileBloc: Updating profile with image URL...');
      final updatedProfile = await repository.updateProfile(
        token: event.token,
        profileData: updatedProfileData,
      );
      
      emit(ProfileUpdateSuccess(updatedProfile: updatedProfile));
    } catch (e, stackTrace) {
      debugPrint('ProfileBloc: Error in _onUpdateProfileWithImageUpload: $e');
      debugPrint('ProfileBloc: Stack trace: $stackTrace');
      
      if (e.toString().contains('upload')) {
        emit(ImageUploadError(e.toString()));
      } else {
        emit(ProfileUpdateError(e.toString()));
      }
    }
  }

  Future<void> _onUploadProfileImage(
    UploadProfileImage event,
    Emitter<ProfileState> emit,
  ) async {
    debugPrint('ProfileBloc: _onUploadProfileImage called');
    debugPrint('ProfileBloc: Image path: ${event.imagePath}');
    
    try {
      emit(ImageUploadInProgress(progress: 'Uploading image...'));
      
      final uploadResult = await repository.uploadProfileImage(
        token: event.token,
        imagePath: event.imagePath,
        userId: event.userId,
      );
      
      final s3ImageUrl = uploadResult['s3_url'] as String?;
      debugPrint('ProfileBloc: Image uploaded successfully, S3 URL: $s3ImageUrl');
      
      if (s3ImageUrl != null) {
        emit(ImageUploadSuccess(s3Url: s3ImageUrl));
      } else {
        throw Exception('Image upload succeeded but no S3 URL returned');
      }
    } catch (e, stackTrace) {
      debugPrint('ProfileBloc: Error in _onUploadProfileImage: $e');
      debugPrint('ProfileBloc: Stack trace: $stackTrace');
      emit(ImageUploadError(e.toString()));
    }
  }

  Future<void> _onFetchUserProfile(
    FetchUserProfile event,
    Emitter<ProfileState> emit,
  ) async {
    debugPrint('ProfileBloc: Received FetchUserProfile event for userId: ${event.userId}');
    emit(UserProfileLoading());
    try {
      debugPrint('ProfileBloc: Calling repository.fetchUserProfile...');
      final response = await repository.fetchUserProfile(
        token: event.token,
        userId: event.userId,
      );
      debugPrint('ProfileBloc: Repository call successful, emitting UserProfileLoaded');
      emit(UserProfileLoaded(profileData: response));
    } catch (e, stackTrace) {
      debugPrint('ProfileBloc: Error in fetchUserProfile: $e');
      debugPrint('ProfileBloc: Stack trace: $stackTrace');
      emit(UserProfileError(e.toString()));
    }
  }

  Future<void> _onGetCommunityProfile(
    GetCommunityProfile event,
    Emitter<ProfileState> emit,
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

  // Follow System Handlers
  Future<void> _onFollowUser(
    FollowUser event,
    Emitter<ProfileState> emit,
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
      debugPrint('ProfileBloc: Error in _onFollowUser: $e');
      debugPrint('ProfileBloc: Stack trace: $stackTrace');
      emit(FollowError(
        userId: event.userId,
        message: e.toString(),
        wasFollowing: true,
      ));
    }
  }

  Future<void> _onUnfollowUser(
    UnfollowUser event,
    Emitter<ProfileState> emit,
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
      debugPrint('ProfileBloc: Error in _onUnfollowUser: $e');
      debugPrint('ProfileBloc: Stack trace: $stackTrace');
      emit(FollowError(
        userId: event.userId,
        message: e.toString(),
        wasFollowing: false,
      ));
    }
  }

  Future<void> _onCheckFollowStatus(
    CheckFollowStatus event,
    Emitter<ProfileState> emit,
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
      debugPrint('ProfileBloc: Error in _onCheckFollowStatus: $e');
      debugPrint('ProfileBloc: Stack trace: $stackTrace');
      emit(FollowStatusError(e.toString()));
    }
  }

  Future<void> _onFetchFollowers(
    FetchFollowers event,
    Emitter<ProfileState> emit,
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
      debugPrint('ProfileBloc: Error in _onFetchFollowers: $e');
      debugPrint('ProfileBloc: Stack trace: $stackTrace');
      emit(FollowersError(e.toString()));
    }
  }

  Future<void> _onFetchFollowing(
    FetchFollowing event,
    Emitter<ProfileState> emit,
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
      debugPrint('ProfileBloc: Error in _onFetchFollowing: $e');
      debugPrint('ProfileBloc: Stack trace: $stackTrace');
      emit(FollowingError(e.toString()));
    }
  }

  // User Posts Handlers
  Future<void> _onFetchUserThreads(
    FetchUserThreads event,
    Emitter<ProfileState> emit,
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
    Emitter<ProfileState> emit,
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
    Emitter<ProfileState> emit,
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
    Emitter<ProfileState> emit,
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

  // Block System Handlers
  Future<void> _onBlockUser(
    BlockUser event,
    Emitter<ProfileState> emit,
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
      debugPrint('ProfileBloc: Error in _onBlockUser: $e');
      debugPrint('ProfileBloc: Stack trace: $stackTrace');
      emit(BlockUserError(
        userId: event.blockData.userId,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onUnblockUser(
    UnblockUser event,
    Emitter<ProfileState> emit,
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
      debugPrint('ProfileBloc: Error in _onUnblockUser: $e');
      debugPrint('ProfileBloc: Stack trace: $stackTrace');
      emit(UnblockUserError(
        userId: event.userId,
        message: e.toString(),
      ));
    }
  }

  Future<void> _onCheckBlockStatus(
    CheckBlockStatus event,
    Emitter<ProfileState> emit,
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
      debugPrint('ProfileBloc: Error in _onCheckBlockStatus: $e');
      debugPrint('ProfileBloc: Stack trace: $stackTrace');
      emit(BlockStatusError(e.toString()));
    }
  }
}