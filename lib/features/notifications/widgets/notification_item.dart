import 'package:flutter/material.dart';
import '../../../domain/notifications/entities/notification_entities.dart';

class NotificationItem extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback? onTap;

  const NotificationItem({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          // Add blue background for unread notifications
          color: !notification.isRead 
              ? Colors.blue.withValues(alpha: 0.05)
              : null,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Profile picture with notification type overlay
            Stack(
              children: [
                // User avatar
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
                    child: notification.actor.profileImageUrl != null && notification.actor.profileImageUrl!.isNotEmpty
                        ? Image.network(
                            notification.actor.profileImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar();
                            },
                          )
                        : _buildDefaultAvatar(),
                  ),
                ),
                
                // Notification type icon overlay
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getNotificationIconBackground(),
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _getNotificationIcon(),
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 16),
            
            // Notification content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User name, verification badge, and timestamp
                  Row(
                    children: [
                      // Full name (as per API structure)
                      Text(
                        notification.actor.fullName.isNotEmpty 
                            ? notification.actor.fullName 
                            : notification.actor.username,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      
                      
                      const Spacer(),
                      
                      // Timestamp
                      Text(
                        _formatTimestamp(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Notification message with post content if available
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      children: [
                        TextSpan(text: _getNotificationMessage()),
                        if (notification.post != null && notification.post!.content.isNotEmpty)
                          TextSpan(
                            text: ' "${notification.post!.content}"',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
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
    );
  }

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.reply:
        return Icons.chat_bubble;
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.followRequest:
        return Icons.person_add_outlined;
      case NotificationType.followRequestAccepted:
        return Icons.person_add_alt_1;
      case NotificationType.mention:
        return Icons.alternate_email;
      case NotificationType.notificationDeleted:
        return Icons.remove;
    }
  }

  Color _getNotificationIconBackground() {
    switch (notification.type) {
      case NotificationType.like:
        return const Color(0xFFFF016B); // Pink from Figma
      case NotificationType.reply:
        return const Color(0xFF3898ED); // Blue
      case NotificationType.follow:
        return const Color(0xFF7441F5); // Purple
      case NotificationType.followRequest:
        return const Color(0xFF7441F5); // Purple
      case NotificationType.followRequestAccepted:
        return const Color(0xFF28A745); // Green
      case NotificationType.mention:
        return const Color(0xFFFF8C00); // Orange
      case NotificationType.notificationDeleted:
        return Colors.grey;
    }
  }

  String _getNotificationMessage() {
    switch (notification.type) {
      case NotificationType.like:
        return 'liked your post';
      case NotificationType.reply:
        return 'replied to your post';
      case NotificationType.follow:
        return 'started following you';
      case NotificationType.followRequest:
        return 'requested to follow you';
      case NotificationType.followRequestAccepted:
        return 'accepted your follow request';
      case NotificationType.mention:
        return 'mentioned you in a post';
      case NotificationType.notificationDeleted:
        return 'deleted notification';
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    // Debug logging to help diagnose timing issues
    debugPrint('Notification timestamp: ${dateTime.toIso8601String()}');
    debugPrint('Current time: ${now.toIso8601String()}');
    debugPrint('Difference: ${difference.inMinutes} minutes');

    // Handle negative differences (future times)
    if (difference.isNegative) {
      return 'now';
    }

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${difference.inDays ~/ 7}w';
    }
  }
}