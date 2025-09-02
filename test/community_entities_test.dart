import 'package:flutter_test/flutter_test.dart';
import 'package:nepika/domain/community/entities/community_entities.dart';

void main() {
  group('Community Entities Tests', () {
    test('PostEntity.fromJson should create a valid PostEntity', () {
      final json = {
        'post_id': 'd1f45f58-1234-4b87-8fa4-d34f989cfd12',
        'user_id': 'user_001',
        'full_name': 'Kemm Choo',
        'avatar_url': 'https://img.freepik.com/...',
        'content': 'Feeling refreshed after today\'s skincare routine...',
        'like_count': 12,
        'comment_count': 3,
        'is_edited': false,
        'created_at': '2025-08-08T09:30:00.000Z',
        'media_urls': ['https://image1.jpg', 'https://image2.jpg'],
        'tags': ['skincare', 'routine']
      };

      final post = PostEntity.fromJson(json);

      expect(post.postId, 'd1f45f58-1234-4b87-8fa4-d34f989cfd12');
      expect(post.userId, 'user_001');
      expect(post.fullName, 'Kemm Choo');
      expect(post.avatarUrl, 'https://img.freepik.com/...');
      expect(post.content, 'Feeling refreshed after today\'s skincare routine...');
      expect(post.likeCount, 12);
      expect(post.commentCount, 3);
      expect(post.isEdited, false);
      expect(post.mediaUrls, ['https://image1.jpg', 'https://image2.jpg']);
      expect(post.tags, ['skincare', 'routine']);
    });

    test('SearchUserEntity.fromJson should create a valid SearchUserEntity', () {
      final json = {
        'user_id': 'user_001',
        'full_name': 'Kemm Choo',
        'username': 'kemm_choo',
        'email': 'kemm@example.com',
        'avatar_url': 'https://img.freepik.com/...',
        'bio': 'Skincare enthusiast | Always glowing 🌟',
        'is_following': false
      };

      final user = SearchUserEntity.fromJson(json);

      expect(user.userId, 'user_001');
      expect(user.fullName, 'Kemm Choo');
      expect(user.username, 'kemm_choo');
      expect(user.email, 'kemm@example.com');
      expect(user.avatarUrl, 'https://img.freepik.com/...');
      expect(user.bio, 'Skincare enthusiast | Always glowing 🌟');
      expect(user.isFollowing, false);
    });

    test('CreatePostEntity.toJson should create a valid JSON', () {
      final postData = CreatePostEntity(
        userId: 'user_001',
        communityId: 'community_01',
        content: 'Here\'s my morning skincare routine!',
        mediaUrls: ['https://image1.jpg', 'https://image2.jpg'],
        tags: ['skincare', 'routine'],
      );

      final json = postData.toJson();

      expect(json['user_id'], 'user_001');
      expect(json['community_id'], 'community_01');
      expect(json['content'], 'Here\'s my morning skincare routine!');
      expect(json['media_urls'], ['https://image1.jpg', 'https://image2.jpg']);
      expect(json['tags'], ['skincare', 'routine']);
    });
  });
}
