import 'package:flutter/material.dart';
import '../../../../domain/community/entities/community_entities.dart';
import 'like_comment_share_row.dart';

/// Post actions widget handling like, comment, and share functionality
/// Follows Single Responsibility Principle - only handles post actions
class PostActions extends StatelessWidget {
  final PostEntity post;
  final String token;
  final String userId;
  final bool currentLikeStatus;
  final int currentLikeCount;
  final Function(bool isLiked, int newLikeCount) onLikeStatusChanged;

  const PostActions({
    super.key,
    required this.post,
    required this.token,
    required this.userId,
    required this.currentLikeStatus,
    required this.currentLikeCount,
    required this.onLikeStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LikeCommentShareRow(
      postId: post.id,
      initialLikeStatus: currentLikeStatus,
      initialLikeCount: currentLikeCount,
      size: 22,
      activeColor: Colors.red,
      showCount: false,
      token: token,
      userId: userId,
      onLikeStatusChanged: onLikeStatusChanged,
      currentLikeStatus: currentLikeStatus,
      currentLikeCount: currentLikeCount,
    );
  }
}