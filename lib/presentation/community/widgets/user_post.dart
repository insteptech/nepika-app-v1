import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/presentation/community/pages/post_detail_page_integration.dart';
import 'package:nepika/presentation/community/widgets/like_comment_share_row.dart';
import 'package:nepika/presentation/community/widgets/user_icon.dart';
import 'package:nepika/presentation/community/widgets/user_name.dart';
import '../../../domain/community/entities/community_entities.dart';



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
  bool get isLiked {
    return widget.post.likes.any((like) => like.userId == widget.userId);
  }

  String _timeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }



  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        UserImageIcon(author: widget.post.author),

        SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  
                  UserNameWithNavigation(post: widget.post),

                  const Spacer(),

                  Text(
                    _timeAgo(widget.post.createdAt),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodyMedium!
                        .secondary(context)
                        .copyWith(fontWeight: FontWeight.w300),
                  ),

                  const SizedBox(width: 10),

                  Icon(
                    Icons.more_horiz,
                    size: 22,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ],
              ),
              const SizedBox(height: 7),

              GestureDetector(
                onTap: () {
                  widget.disableActions ? null : Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PostDetailPageIntegration(
                        token: widget.token,
                        postId: widget.post.postId,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                child: Text(
                  widget.post.content,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),

              const SizedBox(height: 15),
              LikeCommentShareRow(
                postId: widget.post.postId,
                initialLikeStatus: isLiked,
                initialLikeCount: widget.post.likeCount,
                size: 18,
                activeColor: Colors.red,
                showCount: false,
              ),
              const SizedBox(height: 10),
              widget.post.likeCount > 0
              ? Text(
                "${widget.post.likeCount} ${widget.post.likeCount == 1 ? 'Like' : 'Likes'}",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.secondary(context),
              )
              : const SizedBox.shrink(),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
