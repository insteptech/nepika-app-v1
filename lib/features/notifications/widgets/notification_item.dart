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
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFFF2F2F2), // Greyscale/300 from Figma
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
                      color: const Color(0xFFF2F2F2), // Greyscale/300
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: notification.actor.profileImageUrl != null
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
                        color: Colors.white,
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
                      // Username
                      Text(
                        notification.actor.username,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      
                      const SizedBox(width: 4),
                      
                      // Verification badge (if needed)
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4192EF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Timestamp
                      Text(
                        _formatTimestamp(notification.createdAt),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFFB8B8B8), // Greyscale/700
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Notification message
                  Text(
                    _getNotificationMessage(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFB8B8B8), // Greyscale/700
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Replies button (matching Figma design)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFCDCDCD), // Greyscale/600
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Replies',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF111111), // fill_9T3J13
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F2F2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        color: Color(0xFFB8B8B8),
        size: 24,
      ),
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
      case NotificationType.mention:
        return const Color(0xFFFF8C00); // Orange
      case NotificationType.notificationDeleted:
        return Colors.grey;
    }
  }

  String _getNotificationMessage() {
    switch (notification.type) {
      case NotificationType.like:
        return 'Liked your photo';
      case NotificationType.reply:
        return 'Replied to your post';
      case NotificationType.follow:
        return 'Followed you';
      case NotificationType.mention:
        return 'Mentioned you';
      case NotificationType.notificationDeleted:
        return 'Deleted notification';
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
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