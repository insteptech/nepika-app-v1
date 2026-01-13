import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'like_button.dart';
import '../utils/community_navigation.dart';
import '../bloc/blocs/posts_bloc.dart';
import '../bloc/events/posts_event.dart';

class LikeCommentShareRow extends StatefulWidget {
  final String postId;
  final bool initialLikeStatus;
  final int initialLikeCount;
  final double? size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showCount;
  final String? token;
  final String? userId;
  final Function(bool isLiked, int newLikeCount)? onLikeStatusChanged;
  final bool? currentLikeStatus;
  final int? currentLikeCount;
  final bool showCommentButton;
  final VoidCallback? onShareTap;

  const LikeCommentShareRow({
    super.key,
    required this.postId,
    required this.initialLikeStatus,
    required this.initialLikeCount,
    this.size = 24,
    this.activeColor = Colors.red,
    this.inactiveColor,
    this.showCount = false,
    this.token,
    this.userId,
    this.onLikeStatusChanged,
    this.currentLikeStatus,
    this.currentLikeCount,
    this.showCommentButton = true,
    this.onShareTap,
  });

  @override
  State<LikeCommentShareRow> createState() => _LikeCommentShareRowState();
}

class _LikeCommentShareRowState extends State<LikeCommentShareRow> {
  void _onLikeStatusChanged(bool isLiked, int newLikeCount) {
    widget.onLikeStatusChanged?.call(isLiked, newLikeCount);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        LikeButton(
          postId: widget.postId,
          initialLikeStatus: widget.initialLikeStatus,
          initialLikeCount: widget.initialLikeCount,
          size: widget.size,
          activeColor: widget.activeColor,
          showCount: widget.showCount,
          onLikeStatusChanged: _onLikeStatusChanged,
        ),
        if (widget.showCommentButton)
          InkWell(
            onTap: () async {
              await CommunityNavigation.navigateToPostDetail(
                context,
                postId: widget.postId,
                token: widget.token!,
                userId: widget.userId!,
                currentLikeStatus: widget.currentLikeStatus ?? widget.initialLikeStatus,
                currentLikeCount: widget.currentLikeCount ?? widget.initialLikeCount,
              );
              
              // Trigger sync after returning from post details
              if (context.mounted) {
                try {
                  final postsBloc = context.read<PostsBloc>();
                  postsBloc.add(SyncLikeStatesEvent());
                } catch (e) {
                  debugPrint('LikeCommentShareRow: Error syncing like states after navigation: $e');
                }
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/icons/comment_icon.png',
                height: 18,
                color: Theme.of(context).textTheme.bodyMedium!.primary(context).color,
              ),
            ),
          ),
        /*
        InkWell(
          onTap: () {
            // Use ShareService to invoke native share sheet
            // We need to construct a minimal PostEntity or change widget to accept it.
            // For now, let's just share the post ID/Link since we don't have the full post entity here
            // To fix this propery, we should pass the PostEntity to this widget
            // But since this widget is used in multiple places, let's create a temporary entity or 
            // better yet, refactor the parenting widget to handle the logic if needed.
            // Actually, the parent PostActions HAS the post entity.
            // Let's modify this widget to optionally accept onShareTap callback?
            // Or better, update ShareService to take ID and basic content if full entity not available.
            // WAITING: I need to update the widget to accept onShareTap callback so parent constructs it.
             widget.onShareTap?.call();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              'assets/icons/send_icon.png',
              height: 16,
              color: Theme.of(context).textTheme.bodyMedium!.primary(context).color,
            ),
          ),
        ),
        */
      ],
    );
  }
}