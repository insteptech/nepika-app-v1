import 'package:flutter/material.dart';
import '../../../../domain/community/entities/community_entities.dart';
import 'user_icon.dart';
import 'post_header.dart';
import 'post_content.dart';
import 'post_actions.dart';
import 'post_menu.dart';

/// Clean, focused user post widget following Single Responsibility Principle
/// Only responsible for displaying a post and coordinating its sub-components
class UserPostWidget extends StatefulWidget {
  final PostEntity post;
  final String token;
  final String userId;
  final bool disableActions;

  const UserPostWidget({
    super.key,
    required this.post,
    required this.token,
    required this.userId,
    this.disableActions = false,
  });

  @override
  State<UserPostWidget> createState() => _UserPostWidgetState();
}

class _UserPostWidgetState extends State<UserPostWidget> {
  late PostEntity _currentPost;
  late int _currentLikeCount;
  late bool _currentLikeStatus;
  
  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _currentLikeCount = widget.post.likeCount;
    _currentLikeStatus = widget.post.isLikedByUser;
  }

  @override
  void didUpdateWidget(UserPostWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _currentPost = widget.post;
      _currentLikeCount = widget.post.likeCount;
      _currentLikeStatus = widget.post.isLikedByUser;
    }
  }

  void _onLikeStatusChanged(bool isLiked, int newLikeCount) {
    if (mounted) {
      setState(() {
        _currentLikeStatus = isLiked;
        _currentLikeCount = newLikeCount;
      });
    }
  }

  void _onPostUpdated(PostEntity updatedPost) {
    if (mounted) {
      setState(() {
        _currentPost = updatedPost;
      });
    }
  }

  bool get _isCurrentUserPost => _currentPost.userId == widget.userId;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Avatar
        UserImageIcon(
          author: AuthorEntity(
            id: _currentPost.userId,
            fullName: _currentPost.username.isNotEmpty ? _currentPost.username : 'User',
            avatarUrl: _currentPost.userAvatar ?? '',
          ),
        ),
        const SizedBox(width: 5),
        
        // Post Content Area
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post Header (username, timestamp, options)
              PostHeader(
                post: _currentPost,
                isCurrentUserPost: _isCurrentUserPost,
                disableActions: widget.disableActions,
                onMenuTap: () => _showPostMenu(),
              ),
              
              // Reply Indicator (if this is a reply)
              if (_currentPost.parentPostId?.isNotEmpty == true)
                _buildReplyIndicator(),
              
              // Post Content
              PostContent(
                post: _currentPost,
                token: widget.token,
                userId: widget.userId,
                disableActions: widget.disableActions,
              ),
              
              const SizedBox(height: 5),
              
              // Post Actions (like, comment, share)
              PostActions(
                post: _currentPost,
                token: widget.token,
                userId: widget.userId,
                currentLikeStatus: _currentLikeStatus,
                currentLikeCount: _currentLikeCount,
                onLikeStatusChanged: _onLikeStatusChanged,
              ),
              
              // Like Count Display
              if (_currentLikeCount > 0) _buildLikeCount(),
              
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReplyIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
            children: [
              const TextSpan(text: 'Replying to '),
              TextSpan(
                text: '@thread', // This should come from API
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLikeCount() {
    return Padding(
      padding: const EdgeInsets.only(left: 7),
      child: Text(
        "$_currentLikeCount ${_currentLikeCount == 1 ? 'Like' : 'Likes'}",
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  void _showPostMenu() {
    PostMenu.show(
      context: context,
      post: _currentPost,
      token: widget.token,
      userId: widget.userId,
      isCurrentUserPost: _isCurrentUserPost,
      onPostUpdated: _onPostUpdated,
    );
  }
}