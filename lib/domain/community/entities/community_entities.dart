class CommunityPostEntity {
  final List<Map<String, dynamic>> posts;

  CommunityPostEntity({required this.posts});
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
  final DateTime updatedAt;
  final AuthorEntity author;
  final List<LikeEntity> likes;
  final List<String>? mediaUrls;
  final List<String>? tags;

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
    required this.updatedAt,
    required this.author,
    required this.likes,
    this.mediaUrls,
    this.tags,
  });

  // Convenience getters for backward compatibility
  String get postId => id;
  String get fullName => author.fullName;
  String? get avatarUrl => null; // Will be handled by avatar service

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
          : DateTime.now(),
      author: AuthorEntity.fromJson(json['author'] ?? {}),
      likes: json['likes'] != null
          ? List<LikeEntity>.from(
              json['likes'].map((like) => LikeEntity.fromJson(like))
            )
          : [],
      mediaUrls: json['media_urls'] != null 
          ? List<String>.from(json['media_urls']) 
          : null,
      tags: json['tags'] != null 
          ? List<String>.from(json['tags']) 
          : null,
    );
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
      userId: json['user_id'] ?? '',
      fullName: json['full_name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      isFollowing: json['is_following'] ?? false,
    );
  }
}

class CreatePostEntity {
  final String userId;
  final String communityId;
  final String content;
  final List<String>? mediaUrls;
  final List<String>? tags;

  CreatePostEntity({
    required this.userId,
    required this.communityId,
    required this.content,
    this.mediaUrls,
    this.tags,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'community_id': communityId,
      'content': content,
      if (mediaUrls != null) 'media_urls': mediaUrls,
      if (tags != null) 'tags': tags,
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
      author: AuthorEntity.fromJson(json['author'] ?? {}),
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
