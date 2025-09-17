import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme.dart';
import '../../../domain/community/entities/community_entities.dart';

class ThreadCard extends StatelessWidget {
  final PostEntity post;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onShare;

  const ThreadCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onLike,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: (post.userAvatar != null && post.userAvatar?.isNotEmpty == true)
                  ? Image.network(
                      post.userAvatar ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar();
                      },
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      post.username,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    Text(
                      _formatTimestamp(post.createdAt),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    IconButton(
                      onPressed: () => _showMoreOptions(context),
                      icon: Icon(
                        Icons.more_horiz,
                        size: 20,
                        color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    post.content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.4,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    _buildActionButton(
                      context,
                      icon: post.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                      iconColor: post.isLikedByUser ? Colors.red : null,
                      count: post.likeCount,
                      onPressed: onLike,
                    ),
                    const SizedBox(width: 20),
                    _buildActionButton(
                      context,
                      icon: Icons.mode_comment_outlined,
                      iconColor: null,
                      count: post.commentCount,
                      onPressed: onTap,
                    ),
                    const SizedBox(width: 20),
                    _buildActionButton(
                      context,
                      icon: Icons.repeat,
                      iconColor: null,
                      count: null,
                      onPressed: () {},
                    ),
                    const SizedBox(width: 20),
                    _buildActionButton(
                      context,
                      icon: Icons.share_outlined,
                      iconColor: null,
                      count: null,
                      onPressed: onShare,
                    ),
                  ],
                ),
                
                if (post.likeCount > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${post.likeCount} ${post.likeCount == 1 ? 'like' : 'likes'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE5E7EB),
      ),
      child: const Icon(
        Icons.person,
        size: 20,
        color: Color(0xFF6B7280),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required Color? iconColor,
    required int? count,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: iconColor ?? Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
          ),
          if (count != null && count > 0) ...[
            const SizedBox(width: 4),
            Text(
              _formatCount(count),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}w';
    }
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1).replaceAll('.0', '')}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    }
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: Icon(
                    Icons.copy,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  title: Text(
                    'Copy link',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: Icon(
                    Icons.report,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  title: Text(
                    'Report',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: Icon(
                    Icons.block,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  title: Text(
                    'Block user',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}