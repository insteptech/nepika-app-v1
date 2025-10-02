import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_state.dart';
import '../bloc/notification_event.dart';
import '../widgets/notification_item.dart';
import '../widgets/notification_filter_tabs.dart';
import '../../../domain/notifications/entities/notification_entities.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all notifications as seen when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationBloc>().add(const MarkAllNotificationsAsSeen());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              pinned: true,
              title: Text(
                'Activity',
                style: TextStyle(
                  color: theme.textTheme.titleLarge?.color,
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                ),
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: theme.iconTheme.color,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            
            // Filter Tabs
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: NotificationFilterTabs(),
              ),
            ),
            
            // Notifications List
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                if (state is NotificationLoading || state is NotificationConnecting) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (state is NotificationError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load notifications',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<NotificationBloc>().add(
                                const ConnectToNotificationStream(),
                              );
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                List<NotificationEntity> notifications = [];
                if (state is NotificationLoaded) {
                  notifications = state.filteredNotifications;
                } else if (state is NotificationDisconnected) {
                  notifications = state.notifications;
                }

                if (notifications.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'When you get notifications, they\'ll show up here',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final notification = notifications[index];
                      return NotificationItem(
                        notification: notification,
                        onTap: () => _handleNotificationTap(notification),
                      );
                    },
                    childCount: notifications.length,
                  ),
                );
              },
            ),
            
            // Add some bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationEntity notification) {
    // Handle notification tap based on type
    switch (notification.type) {
      case NotificationType.like:
      case NotificationType.reply:
      case NotificationType.mention:
        // Navigate to post detail if postId is available
        if (notification.postId != null) {
          // TODO: Navigate to post detail screen
          // Navigator.pushNamed(
          //   context,
          //   CommunityRoutes.postDetail,
          //   arguments: {'postId': notification.postId},
          // );
        }
        break;
      case NotificationType.follow:
        // Navigate to user profile
        // TODO: Navigate to user profile screen
        // Navigator.pushNamed(
        //   context,
        //   CommunityRoutes.userProfile,
        //   arguments: {'userId': notification.actor.id},
        // );
        break;
      case NotificationType.notificationDeleted:
        // This shouldn't be tappable
        break;
    }
  }
}