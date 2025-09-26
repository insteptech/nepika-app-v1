import 'package:flutter/material.dart';
import '../../../../domain/community/entities/community_entities.dart';
import 'user_name.dart';
import '../../../../core/config/constants/theme.dart';

/// Post header displaying username, timestamp, edited indicator, and menu button
/// Follows Single Responsibility Principle - only handles post header display
class PostHeader extends StatelessWidget {
  final PostEntity post;
  final bool isCurrentUserPost;
  final bool disableActions;
  final VoidCallback onMenuTap;

  const PostHeader({
    super.key,
    required this.post,
    required this.isCurrentUserPost,
    required this.disableActions,
    required this.onMenuTap,
  });

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
    return Padding(
      padding: const EdgeInsets.only(left: 9),
      child: SizedBox(
        height: 38,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Username with navigation
            UserNameWithNavigation(post: post),
            
            // const Spacer(),
            
            // Edited indicator
            if (post.isEdited) ...[
              Text(
                'edited',
                style: Theme.of(context).textTheme.bodySmall!
                    .secondary(context)
                    .copyWith(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
              ),
              const SizedBox(width: 8),
            ],

            // Timestamp
            Text(
              _timeAgo(post.updatedAt ?? post.createdAt),
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium!
                  .secondary(context)
                  .copyWith(fontWeight: FontWeight.w300),
            ),

            const SizedBox(width: 10),

            // Menu button
            IconButton(
              onPressed: disableActions ? null : onMenuTap,
              icon: const Icon(Icons.more_horiz, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
          ],
        ),
      ),
    );
  }
}