import 'package:flutter/material.dart';
import '../../../domain/blocked_users/entities/blocked_user_entities.dart';

class BlockedUserItem extends StatelessWidget {
  final BlockedUserEntity user;
  final bool isUnblocking;
  final VoidCallback onUnblock;

  const BlockedUserItem({
    super.key,
    required this.user,
    required this.isUnblocking,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Profile picture
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                  ? Image.network(
                      user.profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar(theme);
                      },
                    )
                  : _buildDefaultAvatar(theme),
            ),
          ),

          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username
                Text(
                  user.username ?? 'Unknown User',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Blocked date
                Text(
                  'Blocked ${_formatDate(user.createdAt)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Unblock button
          SizedBox(
            height: 36,
            child: isUnblocking
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : OutlinedButton(
                    onPressed: onUnblock,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      'Unblock',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.dividerColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        color: theme.iconTheme.color?.withValues(alpha: 0.5),
        size: 24,
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        if (difference.inMinutes < 1) {
          return 'just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = difference.inDays ~/ 7;
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = difference.inDays ~/ 30;
      return '${months}mo ago';
    } else {
      final years = difference.inDays ~/ 365;
      return '${years}y ago';
    }
  }
}