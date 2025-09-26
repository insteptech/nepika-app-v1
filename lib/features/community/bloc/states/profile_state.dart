import '../../../../domain/community/entities/community_entities.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

// Profile Management States
class ProfileCreateLoading extends ProfileState {}

class ProfileCreateStarted extends ProfileState {
  final CreateProfileEntity profileData;

  ProfileCreateStarted({required this.profileData});
}

class ProfileCreateSuccess extends ProfileState {
  final CommunityProfileEntity profile;

  ProfileCreateSuccess({required this.profile});
}

class ProfileCreateError extends ProfileState {
  final String message;

  ProfileCreateError(this.message);
}

class MyProfileLoading extends ProfileState {}

class MyProfileLoaded extends ProfileState {
  final CommunityProfileEntity profile;

  MyProfileLoaded({required this.profile});
}

class MyProfileError extends ProfileState {
  final String message;

  MyProfileError(this.message);
}

class ProfileUpdateLoading extends ProfileState {}

class ProfileUpdateStarted extends ProfileState {
  final UpdateProfileEntity profileData;

  ProfileUpdateStarted({required this.profileData});
}

class ProfileUpdateSuccess extends ProfileState {
  final CommunityProfileEntity updatedProfile;

  ProfileUpdateSuccess({required this.updatedProfile});
}

class ProfileUpdateError extends ProfileState {
  final String message;

  ProfileUpdateError(this.message);
}

class ImageUploadInProgress extends ProfileState {
  final String? progress;

  ImageUploadInProgress({this.progress});
}

class ImageUploadSuccess extends ProfileState {
  final String s3Url;

  ImageUploadSuccess({required this.s3Url});
}

class ImageUploadError extends ProfileState {
  final String message;

  ImageUploadError(this.message);
}

// User Profile States
class UserProfileLoading extends ProfileState {}

class UserProfileLoaded extends ProfileState {
  final UserProfileResponseEntity profileData;

  UserProfileLoaded({required this.profileData});
}

class UserProfileError extends ProfileState {
  final String message;

  UserProfileError(this.message);
}

// Community Profile States
class CommunityProfileLoading extends ProfileState {
  final String userId;

  CommunityProfileLoading({required this.userId});
}

class CommunityProfileLoaded extends ProfileState {
  final CommunityProfileEntity profile;

  CommunityProfileLoaded({required this.profile});
}

class CommunityProfileError extends ProfileState {
  final String userId;
  final String message;
  
  CommunityProfileError({
    required this.userId,
    required this.message,
  });
}

// Follow System States
class FollowLoading extends ProfileState {
  final String userId;
  final bool isFollowing;
  
  FollowLoading({
    required this.userId,
    required this.isFollowing,
  });
}

class FollowSuccess extends ProfileState {
  final String userId;
  final bool isFollowing;
  final String message;

  FollowSuccess({
    required this.userId,
    required this.isFollowing,
    required this.message,
  });
}

class FollowError extends ProfileState {
  final String userId;
  final String message;
  final bool wasFollowing;

  FollowError({
    required this.userId,
    required this.message,
    required this.wasFollowing,
  });
}

class FollowStatusLoading extends ProfileState {}

class FollowStatusLoaded extends ProfileState {
  final String userId;
  final bool isFollowing;

  FollowStatusLoaded({
    required this.userId,
    required this.isFollowing,
  });
}

class FollowStatusError extends ProfileState {
  final String message;

  FollowStatusError(this.message);
}

// Followers/Following States
class FollowersLoading extends ProfileState {}

class FollowersLoaded extends ProfileState {
  final List<CommunityProfileEntity> followers;
  final String userId;
  final bool hasMoreFollowers;
  final int currentPage;
  final int total;

  FollowersLoaded({
    required this.followers,
    required this.userId,
    required this.hasMoreFollowers,
    required this.currentPage,
    required this.total,
  });

  FollowersLoaded copyWith({
    List<CommunityProfileEntity>? followers,
    String? userId,
    bool? hasMoreFollowers,
    int? currentPage,
    int? total,
  }) {
    return FollowersLoaded(
      followers: followers ?? this.followers,
      userId: userId ?? this.userId,
      hasMoreFollowers: hasMoreFollowers ?? this.hasMoreFollowers,
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
    );
  }
}

class FollowersError extends ProfileState {
  final String message;

  FollowersError(this.message);
}

class FollowingLoading extends ProfileState {}

class FollowingLoaded extends ProfileState {
  final List<CommunityProfileEntity> following;
  final String userId;
  final bool hasMoreFollowing;
  final int currentPage;
  final int total;

  FollowingLoaded({
    required this.following,
    required this.userId,
    required this.hasMoreFollowing,
    required this.currentPage,
    required this.total,
  });

  FollowingLoaded copyWith({
    List<CommunityProfileEntity>? following,
    String? userId,
    bool? hasMoreFollowing,
    int? currentPage,
    int? total,
  }) {
    return FollowingLoaded(
      following: following ?? this.following,
      userId: userId ?? this.userId,
      hasMoreFollowing: hasMoreFollowing ?? this.hasMoreFollowing,
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
    );
  }
}

class FollowingError extends ProfileState {
  final String message;

  FollowingError(this.message);
}

// User Posts States
class UserThreadsLoading extends ProfileState {
  final String userId;

  UserThreadsLoading({required this.userId});
}

class UserThreadsLoaded extends ProfileState {
  final String userId;
  final List<PostEntity> threads;
  final bool hasMoreThreads;
  final int currentPage;
  final int total;

  UserThreadsLoaded({
    required this.userId,
    required this.threads,
    required this.hasMoreThreads,
    required this.currentPage,
    required this.total,
  });
}

class UserThreadsLoadingMore extends ProfileState {
  final String userId;

  UserThreadsLoadingMore({required this.userId});
}

class UserThreadsError extends ProfileState {
  final String userId;
  final String message;
  
  UserThreadsError({
    required this.userId,
    required this.message,
  });
}

class UserRepliesLoading extends ProfileState {
  final String userId;

  UserRepliesLoading({required this.userId});
}

class UserRepliesLoaded extends ProfileState {
  final String userId;
  final List<PostEntity> replies;
  final bool hasMoreReplies;
  final int currentPage;
  final int total;

  UserRepliesLoaded({
    required this.userId,
    required this.replies,
    required this.hasMoreReplies,
    required this.currentPage,
    required this.total,
  });
}

class UserRepliesLoadingMore extends ProfileState {
  final String userId;

  UserRepliesLoadingMore({required this.userId});
}

class UserRepliesError extends ProfileState {
  final String userId;
  final String message;
  
  UserRepliesError({
    required this.userId,
    required this.message,
  });
}

// Block System States
class BlockUserLoading extends ProfileState {
  final String userId;
  
  BlockUserLoading({required this.userId});
}

class BlockUserSuccess extends ProfileState {
  final String userId;
  final bool isBlocked;
  final String message;

  BlockUserSuccess({
    required this.userId,
    required this.isBlocked,
    required this.message,
  });
}

class BlockUserError extends ProfileState {
  final String userId;
  final String message;

  BlockUserError({
    required this.userId,
    required this.message,
  });
}

class UnblockUserLoading extends ProfileState {
  final String userId;
  
  UnblockUserLoading({required this.userId});
}

class UnblockUserSuccess extends ProfileState {
  final String userId;
  final bool isBlocked;
  final String message;

  UnblockUserSuccess({
    required this.userId,
    required this.isBlocked,
    required this.message,
  });
}

class UnblockUserError extends ProfileState {
  final String userId;
  final String message;

  UnblockUserError({
    required this.userId,
    required this.message,
  });
}

class BlockStatusLoading extends ProfileState {}

class BlockStatusLoaded extends ProfileState {
  final String userId;
  final bool isBlocked;

  BlockStatusLoaded({
    required this.userId,
    required this.isBlocked,
  });
}

class BlockStatusError extends ProfileState {
  final String message;

  BlockStatusError(this.message);
}