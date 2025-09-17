// Updated to match API response format
class CommunityPostEntity {
  final List<PostEntity> posts;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  CommunityPostEntity({
    required this.posts,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory CommunityPostEntity.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return CommunityPostEntity(
      posts: (data['posts'] as List<dynamic>?)
          ?.map((post) => PostEntity.fromJson(post as Map<String, dynamic>))
          .toList() ?? [],
      total: data['total'] as int? ?? 0,
      page: data['page'] as int? ?? 1,
      pageSize: data['page_size'] as int? ?? 20,
      hasMore: data['has_more'] as bool? ?? false,
    );
  }
}

class AuthorEntity {
  final String id;
  final String fullName;
  final String avatarUrl;

  AuthorEntity({
    required this.id,
    required this.fullName,
    required this.avatarUrl,  
  });

  factory AuthorEntity.fromJson(Map<String, dynamic> json) {
    return AuthorEntity(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString() ?? '',
    );
  }
}

class LikeEntity {
  final String id;
  final String userId;
  final String postId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AuthorEntity author;

  LikeEntity({
    required this.id,
    required this.userId,
    required this.postId,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
  });

  factory LikeEntity.fromJson(Map<String, dynamic> json) {
    return LikeEntity(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
      author: AuthorEntity.fromJson(json['author'] ?? {}),
    );
  }
}

class PostEntity {
  final String id;
  final String userId;
  final String? tenantId;
  final String content;
  final String? parentPostId;
  final int likeCount;
  final int commentCount;
  final bool isEdited;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String username; // Direct from API
  final String? userAvatar; // Direct from API
  final bool isLikedByUser; // Direct from API

  PostEntity({
    required this.id,
    required this.userId,
    this.tenantId,
    required this.content,
    this.parentPostId,
    required this.likeCount,
    required this.commentCount,
    required this.isEdited,
    required this.isDeleted,
    required this.createdAt,
    this.updatedAt,
    required this.username,
    this.userAvatar,
    required this.isLikedByUser,
  });

  // Convenience getters for backward compatibility
  String get postId => id;
  String get fullName => username;
  String? get avatarUrl => userAvatar;

  factory PostEntity.fromJson(Map<String, dynamic> json) {
    return PostEntity(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString(),
      content: json['content']?.toString() ?? '',
      parentPostId: json['parent_post_id']?.toString(),
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      isEdited: json['is_edited'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'].toString())
          : null,
      username: json['username']?.toString() ?? '',
      userAvatar: json['user_avatar']?.toString(),
      isLikedByUser: json['is_liked_by_user'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'tenant_id': tenantId,
      'content': content,
      'parent_post_id': parentPostId,
      'like_count': likeCount,
      'comment_count': commentCount,
      'is_edited': isEdited,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'username': username,
      'user_avatar': userAvatar,
      'is_liked_by_user': isLikedByUser,
    };
  }
}

class UserSearchEntity {
  final List<Map<String, dynamic>> users;

  UserSearchEntity({required this.users});
}

class SearchUserEntity {
  final String userId;
  final String fullName;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final bool isFollowing;

  SearchUserEntity({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.bio,
    required this.isFollowing,
  });

  factory SearchUserEntity.fromJson(Map<String, dynamic> json) {
    return SearchUserEntity(
      userId: json['user_id'] ?? json['id'] ?? '',
      fullName: json['full_name'] ?? json['username'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'] ?? json['profile_image_url'],
      bio: json['bio'],
      isFollowing: json['is_following'] ?? false,
    );
  }
}

class CreatePostEntity {
  final String content;
  final String? parentPostId;

  CreatePostEntity({
    required this.content,
    this.parentPostId,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      if (parentPostId != null) 'parent_post_id': parentPostId,
    };
  }
}

class CreatePostResponseEntity {
  final Map<String, dynamic> response;

  CreatePostResponseEntity({required this.response});
}

class CommentEntity {
  final String id;
  final String userId;
  final String? tenantId;
  final String content;
  final String parentPostId;
  final int likeCount;
  final int commentCount;
  final bool isEdited;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AuthorEntity author;

  CommentEntity({
    required this.id,
    required this.userId,
    this.tenantId,
    required this.content,
    required this.parentPostId,
    required this.likeCount,
    required this.commentCount,
    required this.isEdited,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
  });

  // Convenience getters for backward compatibility
  String get commentId => id;
  String get fullName => author.fullName;
  String? get avatarUrl => null; // Will be handled by avatar service

  factory CommentEntity.fromJson(Map<String, dynamic> json) {
    return CommentEntity(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString(),
      content: json['content']?.toString() ?? '',
      parentPostId: json['parent_post_id']?.toString() ?? '',
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      isEdited: json['is_edited'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
      author: AuthorEntity.fromJson(json['author'] ?? {}),
    );
  }
}

class PostDetailEntity {
  final String id;
  final String userId;
  final String? tenantId;
  final String content;
  final String? parentPostId;
  final int likeCount;
  final int commentCount;
  final bool isEdited;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AuthorEntity author;
  final List<LikeEntity> likes;
  final List<PostEntity> comments;
  final List<String>? mediaUrls;
  final List<String>? tags;
  final bool isLikedByUser;

  PostDetailEntity({
    required this.id,
    required this.userId,
    this.tenantId,
    required this.content,
    this.parentPostId,
    required this.likeCount,
    required this.commentCount,
    required this.isEdited,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    required this.likes,
    required this.comments,
    this.mediaUrls,
    this.tags,
    required this.isLikedByUser,
  });

  // Convenience getters for backward compatibility
  String get postId => id;
  String get fullName => author.fullName;
  String? get avatarUrl => null; // Will be handled by avatar service

  factory PostDetailEntity.fromJson(Map<String, dynamic> json) {
    return PostDetailEntity(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString(),
      content: json['content']?.toString() ?? '',
      parentPostId: json['parent_post_id']?.toString(),
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      isEdited: json['is_edited'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
      author: json['author'] != null 
          ? AuthorEntity.fromJson(json['author'])
          : AuthorEntity(
              id: json['user_id']?.toString() ?? '',
              fullName: json['username']?.toString() ?? '',
              avatarUrl: json['user_avatar']?.toString() ?? '',
            ),
      likes: json['likes'] != null
          ? List<LikeEntity>.from(
              json['likes'].map((like) => LikeEntity.fromJson(like))
            )
          : [],
      comments: json['comments'] != null
          ? List<PostEntity>.from(
              json['comments'].map((comment) => PostEntity.fromJson(comment))
            )
          : [],
      mediaUrls: json['media_urls'] != null 
          ? List<String>.from(json['media_urls']) 
          : null,
      tags: json['tags'] != null 
          ? List<String>.from(json['tags']) 
          : null,
      isLikedByUser: json['is_liked_by_user'] as bool? ?? false,
    );
  }
}

class LikePostEntity {
  final String postId;

  LikePostEntity({required this.postId});

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
    };
  }
}

class LikePostResponseEntity {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  LikePostResponseEntity({
    required this.success,
    required this.message,
    this.data,
  });

  factory LikePostResponseEntity.fromJson(Map<String, dynamic> json) {
    return LikePostResponseEntity(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

class UnlikePostEntity {
  final String postId;

  UnlikePostEntity({required this.postId});

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
    };
  }
}

class UnlikePostResponseEntity {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  UnlikePostResponseEntity({
    required this.success,
    required this.message,
    this.data,
  });

  factory UnlikePostResponseEntity.fromJson(Map<String, dynamic> json) {
    return UnlikePostResponseEntity(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

// User Profile Entities
class UserProfileEntity {
  final String id;
  final String full_name;
  final String username;
  final String? profilePicture;
  final String? bio;
  final bool isVerified;
  final int followersCount;
  final int followingCount;
  final String? location;
  final String? website;
  final DateTime createdAt;

  UserProfileEntity({
    required this.id,
    required this.full_name,
    required this.username,
    this.profilePicture,
    this.bio,
    required this.isVerified,
    required this.followersCount,
    required this.followingCount,
    this.location,
    this.website,
    required this.createdAt,
  });

  factory UserProfileEntity.fromJson(Map<String, dynamic> json) {
    return UserProfileEntity(
      id: json['id']?.toString() ?? '',
      full_name: json['full_name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      profilePicture: json['profile_picture']?.toString(),
      bio: json['bio']?.toString(),
      isVerified: json['is_verified'] as bool? ?? false,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      location: json['location']?.toString(),
      website: json['website']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class ReplyEntity {
  final String id;
  final String content;
  final String userId;
  final String userName;
  final String? userProfilePicture;
  final bool userIsVerified;
  final DateTime createdAt;
  final int likesCount;

  ReplyEntity({
    required this.id,
    required this.content,
    required this.userId,
    required this.userName,
    this.userProfilePicture,
    required this.userIsVerified,
    required this.createdAt,
    required this.likesCount,
  });

  factory ReplyEntity.fromJson(Map<String, dynamic> json) {
    return ReplyEntity(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      userProfilePicture: json['user_profile_picture']?.toString(),
      userIsVerified: json['user_is_verified'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      likesCount: json['likes_count'] as int? ?? 0,
    );
  }
}

class ThreadEntity {
  final String id;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final List<ReplyEntity> replies;

  ThreadEntity({
    required this.id,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.replies,
  });

  factory ThreadEntity.fromJson(Map<String, dynamic> json) {
    return ThreadEntity(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      mediaUrl: json['media_url']?.toString(),
      mediaType: json['media_type']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      replies: (json['replies'] as List<dynamic>?)
          ?.map((reply) => ReplyEntity.fromJson(reply as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class UserProfileResponseEntity {
  final SearchUserEntity profile;
  final List<PostDetailEntity> threads;
  final List<ReplyEntity> replies;

  UserProfileResponseEntity({
    required this.profile,
    required this.threads,
    required this.replies,
  });


  factory UserProfileResponseEntity.fromJson(Map<String, dynamic> json) {
    // Handle case where json is the profile data directly
    if (json.containsKey('username') || json.containsKey('id')) {
      return UserProfileResponseEntity(
        profile: SearchUserEntity.fromJson(json),
        threads: [],
        replies: [],
      );
    }
    
    // Handle structured response with profile, threads, replies
    return UserProfileResponseEntity(
      profile: SearchUserEntity.fromJson(json['profile'] as Map<String, dynamic>),
      threads: (json['threads'] as List<dynamic>?)
          ?.map((thread) => PostDetailEntity.fromJson(thread as Map<String, dynamic>))
          .toList() ?? [],
      replies: (json['replies'] as List<dynamic>?)
          ?.map((reply) => ReplyEntity.fromJson(reply as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

// New entities for profile management
class CommunityProfileEntity {
  final String id;
  final String userId;
  final String? tenantId;
  final String username;
  final String? bio;
  final String? profileImageUrl;
  final String? bannerImageUrl;
  final bool isPrivate;
  final bool isVerified;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final Map<String, dynamic>? settings;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CommunityProfileEntity({
    required this.id,
    required this.userId,
    this.tenantId,
    required this.username,
    this.bio,
    this.profileImageUrl,
    this.bannerImageUrl,
    required this.isPrivate,
    required this.isVerified,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    this.settings,
    required this.createdAt,
    this.updatedAt,
  });

  factory CommunityProfileEntity.fromJson(Map<String, dynamic> json) {
    return CommunityProfileEntity(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString(),
      username: json['username']?.toString() ?? '',
      bio: json['bio']?.toString(),
      profileImageUrl: json['profile_image_url']?.toString(),
      bannerImageUrl: json['banner_image_url']?.toString(),
      isPrivate: json['is_private'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      postsCount: (json['posts_count'] as num?)?.toInt() ?? 0,
      settings: json['settings'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'tenant_id': tenantId,
      'username': username,
      'bio': bio,
      'profile_image_url': profileImageUrl,
      'banner_image_url': bannerImageUrl,
      'is_private': isPrivate,
      'is_verified': isVerified,
      'followers_count': followersCount,
      'following_count': followingCount,
      'posts_count': postsCount,
      'settings': settings,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class CreateProfileEntity {
  final String username;
  final String? bio;
  final String? profileImageUrl;
  final String? bannerImageUrl;
  final bool isPrivate;

  CreateProfileEntity({
    required this.username,
    this.bio,
    this.profileImageUrl,
    this.bannerImageUrl,
    required this.isPrivate,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      if (bio != null) 'bio': bio,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      if (bannerImageUrl != null) 'banner_image_url': bannerImageUrl,
      'is_private': isPrivate,
    };
  }
}

class UpdateProfileEntity {
  final String? username;
  final String? bio;
  final String? profileImageUrl;
  final String? bannerImageUrl;
  final bool? isPrivate;
  final Map<String, dynamic>? settings;

  UpdateProfileEntity({
    this.username,
    this.bio,
    this.profileImageUrl,
    this.bannerImageUrl,
    this.isPrivate,
    this.settings,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    if (username != null) json['username'] = username;
    if (bio != null) json['bio'] = bio;
    if (profileImageUrl != null) json['profile_image_url'] = profileImageUrl;
    if (bannerImageUrl != null) json['banner_image_url'] = bannerImageUrl;
    if (isPrivate != null) json['is_private'] = isPrivate;
    if (settings != null) json['settings'] = settings;
    return json;
  }
}

class FollowUserEntity {
  final String userId;

  FollowUserEntity({required this.userId});

  Map<String, dynamic> toJson() {
    return {'user_id': userId};
  }
}

class FollowResponseEntity {
  final bool isFollowing;
  final String message;

  FollowResponseEntity({
    required this.isFollowing,
    required this.message,
  });

  factory FollowResponseEntity.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return FollowResponseEntity(
      isFollowing: data['is_following'] as bool? ?? false,
      message: data['message']?.toString() ?? json['message']?.toString() ?? '',
    );
  }
}

class FollowStatusEntity {
  final bool isFollowing;

  FollowStatusEntity({required this.isFollowing});

  factory FollowStatusEntity.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return FollowStatusEntity(
      isFollowing: data['is_following'] as bool? ?? false,
    );
  }
}

class UserListEntity {
  final List<CommunityProfileEntity> users;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  UserListEntity({
    required this.users,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory UserListEntity.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return UserListEntity(
      users: (data['users'] as List<dynamic>?)
          ?.map((user) => CommunityProfileEntity.fromJson(user as Map<String, dynamic>))
          .toList() ?? [],
      total: data['total'] as int? ?? 0,
      page: data['page'] as int? ?? 1,
      pageSize: data['page_size'] as int? ?? 20,
      hasMore: data['has_more'] as bool? ?? false,
    );
  }
}

class CommentListEntity {
  final List<PostEntity> comments;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;
  final String parentPostId;

  CommentListEntity({
    required this.comments,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    required this.parentPostId,
  });

  factory CommentListEntity.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return CommentListEntity(
      comments: (data['comments'] as List<dynamic>?)
          ?.map((comment) => PostEntity.fromJson(comment as Map<String, dynamic>))
          .toList() ?? [],
      total: data['total'] as int? ?? 0,
      page: data['page'] as int? ?? 1,
      pageSize: data['page_size'] as int? ?? 20,
      hasMore: data['has_more'] as bool? ?? false,
      parentPostId: data['parent_post_id']?.toString() ?? '',
    );
  }
}

// Block System Entities
class BlockUserEntity {
  final String userId;
  final String reason;

  BlockUserEntity({
    required this.userId,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'reason': reason,
    };
  }
}

class BlockResponseEntity {
  final bool isBlocked;
  final String message;

  BlockResponseEntity({
    required this.isBlocked,
    required this.message,
  });

  factory BlockResponseEntity.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return BlockResponseEntity(
      isBlocked: data['is_blocked'] as bool? ?? false,
      message: data['message']?.toString() ?? json['message']?.toString() ?? '',
    );
  }
}

class BlockStatusEntity {
  final bool isBlocked;

  BlockStatusEntity({required this.isBlocked});

  factory BlockStatusEntity.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return BlockStatusEntity(
      isBlocked: data['is_blocked'] as bool? ?? false,
    );
  }
}

// New entity for the updated user search API response
class UserSearchResultEntity {
  final String id;
  final String username;
  final String? profileImageUrl;
  final bool isVerified;
  final int followersCount;
  final DateTime createdAt;
  final bool isFollowing;
  final bool isBlocked;

  UserSearchResultEntity({
    required this.id,
    required this.username,
    this.profileImageUrl,
    required this.isVerified,
    required this.followersCount,
    required this.createdAt,
    this.isFollowing = false,
    this.isBlocked = false,
  });

  factory UserSearchResultEntity.fromJson(Map<String, dynamic> json) {
    return UserSearchResultEntity(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      profileImageUrl: json['profile_image_url'],
      isVerified: json['is_verified'] ?? false,
      followersCount: json['followers_count'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isFollowing: json['is_following'] ?? false,
      isBlocked: json['is_blocked'] ?? false,
    );
  }

  UserSearchResultEntity copyWith({
    String? id,
    String? username,
    String? profileImageUrl,
    bool? isVerified,
    int? followersCount,
    DateTime? createdAt,
    bool? isFollowing,
    bool? isBlocked,
  }) {
    return UserSearchResultEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isVerified: isVerified ?? this.isVerified,
      followersCount: followersCount ?? this.followersCount,
      createdAt: createdAt ?? this.createdAt,
      isFollowing: isFollowing ?? this.isFollowing,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}

class UserSearchResponseEntity {
  final List<UserSearchResultEntity> users;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  UserSearchResponseEntity({
    required this.users,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory UserSearchResponseEntity.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return UserSearchResponseEntity(
      users: (data['users'] as List<dynamic>?)
          ?.map((user) => UserSearchResultEntity.fromJson(user as Map<String, dynamic>))
          .toList() ?? [],
      total: data['total'] ?? 0,
      page: data['page'] ?? 1,
      pageSize: data['page_size'] ?? 10,
      hasMore: data['has_more'] ?? false,
    );
  }
}
