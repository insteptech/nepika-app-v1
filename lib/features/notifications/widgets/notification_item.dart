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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // Responsive sizes
    final avatarSize = isSmallScreen ? 44.0 : 48.0;
    final iconSize = isSmallScreen ? 22.0 : 24.0;
    final iconContentSize = isSmallScreen ? 12.0 : 14.0;
    final horizontalPadding = isSmallScreen ? 16.0 : 20.0;
    final verticalPadding = isSmallScreen ? 12.0 : 16.0;
    final contentSpacing = isSmallScreen ? 12.0 : 16.0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile picture with notification type overlay
            Stack(
              children: [
                // User avatar
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(avatarSize / 2),
                    child: notification.actor.profileImageUrl != null &&
                            notification.actor.profileImageUrl!.isNotEmpty
                        ? Image.network(
                            notification.actor.profileImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar(avatarSize);
                            },
                          )
                        : _buildDefaultAvatar(avatarSize),
                  ),
                ),

                // Notification type icon overlay
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: iconSize,
                    height: iconSize,
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
                      size: iconContentSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(width: contentSpacing),

            // Notification content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // User name, verification badge, and timestamp
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full name (as per API structure)
                      Expanded(
                        child: Text(
                          notification.actor.fullName.isNotEmpty
                              ? notification.actor.fullName
                              : notification.actor.username,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Timestamp
                      Text(
                        _formatTimestamp(notification.createdAt),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Notification message with post content if available
                  Flexible(
                    child: RichText(
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 15,
                          color: theme.textTheme.bodyMedium?.color,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: _getNotificationMessage(),
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                          ),
                          if (notification.post != null &&
                              notification.post!.content.isNotEmpty)
                            TextSpan(
                              text:
                                  ' "${notification.post!.content.characters.take(30).toString()}${notification.post!.content.length > 30 ? '...' : ''}"',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                        ],
                      ),
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

  Widget _buildDefaultAvatar(double size) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: theme.dividerColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            color: theme.iconTheme.color?.withValues(alpha: 0.5),
            size: size * 0.5,
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