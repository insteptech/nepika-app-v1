import '../../../../domain/community/entities/community_entities.dart';

abstract class ProfileEvent {}

// Profile Management Events
class CreateProfile extends ProfileEvent {
  final String token;
  final CreateProfileEntity profileData;

  CreateProfile({
    required this.token,
    required this.profileData,
  });
}

class FetchMyProfile extends ProfileEvent {
  final String token;
  final String userId;

  FetchMyProfile({
    required this.token,
    required this.userId,
  });
}

class UpdateProfile extends ProfileEvent {
  final String token;
  final UpdateProfileEntity profileData;

  UpdateProfile({
    required this.token,
    required this.profileData,
  });
}

class UpdateProfileWithImageUpload extends ProfileEvent {
  final String token;
  final UpdateProfileEntity profileData;
  final String? imagePath;
  final String? userId;

  UpdateProfileWithImageUpload({
    required this.token,
    required this.profileData,
    this.imagePath,
    this.userId,
  });
}

class UploadProfileImage extends ProfileEvent {
  final String token;
  final String imagePath;
  final String? userId;

  UploadProfileImage({
    required this.token,
    required this.imagePath,
    this.userId,
  });
}

class FetchUserProfile extends ProfileEvent {
  final String token;
  final String userId;

  FetchUserProfile({
    required this.token,
    required this.userId,
  });
}

class GetCommunityProfile extends ProfileEvent {
  final String token;
  final String userId;

  GetCommunityProfile({
    required this.token,
    required this.userId,
  });
}

// Follow System Events
class FollowUser extends ProfileEvent {
  final String token;
  final String userId;

  FollowUser({
    required this.token,
    required this.userId,
  });
}

class UnfollowUser extends ProfileEvent {
  final String token;
  final String userId;

  UnfollowUser({
    required this.token,
    required this.userId,
  });
}

class CheckFollowStatus extends ProfileEvent {
  final String token;
  final String userId;

  CheckFollowStatus({
    required this.token,
    required this.userId,
  });
}

class FetchFollowers extends ProfileEvent {
  final String token;
  final String userId;
  final int page;
  final int pageSize;

  FetchFollowers({
    required this.token,
    required this.userId,
    this.page = 1,
    this.pageSize = 20,
  });
}

class FetchFollowing extends ProfileEvent {
  final String token;
  final String userId;
  final int page;
  final int pageSize;

  FetchFollowing({
    required this.token,
    required this.userId,
    this.page = 1,
    this.pageSize = 20,
  });
}

// User Posts Events
class FetchUserThreads extends ProfileEvent {
  final String token;
  final String userId;
  final int page;
  final int pageSize;

  FetchUserThreads({
    required this.token,
    required this.userId,
    this.page = 1,
    this.pageSize = 20,
  });
}

class FetchUserReplies extends ProfileEvent {
  final String token;
  final String userId;
  final int page;
  final int pageSize;

  FetchUserReplies({
    required this.token,
    required this.userId,
    this.page = 1,
    this.pageSize = 20,
  });
}

class LoadMoreUserThreads extends ProfileEvent {
  final String token;
  final String userId;
  final int page;
  final int pageSize;

  LoadMoreUserThreads({
    required this.token,
    required this.userId,
    required this.page,
    this.pageSize = 20,
  });
}

class LoadMoreUserReplies extends ProfileEvent {
  final String token;
  final String userId;
  final int page;
  final int pageSize;

  LoadMoreUserReplies({
    required this.token,
    required this.userId,
    required this.page,
    this.pageSize = 20,
  });
}

// Block System Events
class BlockUser extends ProfileEvent {
  final String token;
  final BlockUserEntity blockData;

  BlockUser({
    required this.token,
    required this.blockData,
  });
}

class UnblockUser extends ProfileEvent {
  final String token;
  final String userId;

  UnblockUser({
    required this.token,
    required this.userId,
  });
}

class CheckBlockStatus extends ProfileEvent {
  final String token;
  final String userId;

  CheckBlockStatus({
    required this.token,
    required this.userId,
  });
}