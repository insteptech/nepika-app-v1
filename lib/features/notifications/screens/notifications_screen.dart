import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_state.dart';
import '../bloc/notification_event.dart';
import '../widgets/notification_item.dart';
import '../widgets/notification_filter_tabs.dart';
import '../../../domain/notifications/entities/notification_entities.dart';
import '../../../core/widgets/back_button.dart';
import '../../../core/config/constants/app_constants.dart';
import '../../community/utils/community_navigation.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _token;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Only mark notifications as seen if there are unread notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<NotificationBloc>();
      final state = bloc.state;
      
      // Check if there are unread notifications before making API call
      int unreadCount = 0;
      if (state is NotificationLoaded) {
        unreadCount = state.unreadCount;
      } else if (state is NotificationDisconnected) {
        unreadCount = state.unreadCount;
      }
      
      // Only call mark as seen if there are actually unread notifications
      if (unreadCount > 0) {
        bloc.add(const MarkAllNotificationsAsSeen());
      }
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
            // Top section with back button (non-sticky)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // const CustomBackButton(),
                    // const SizedBox(height: 15),
                  ],
                ),
              ),
            ),

            // Sticky header with Activity title and back button
            SliverPersistentHeader(
              pinned: true,
              delegate: _ActivityHeaderDelegate(
                minHeight: 50,
                maxHeight: 70,
                theme: theme,
              ),
            ),

            // Sticky Filter Tabs
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterTabsDelegate(
                height: 60,
                theme: theme,
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

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.accessTokenKey);
      final userData = prefs.getString(AppConstants.userDataKey);
      
      if (token != null && userData != null && mounted) {
        final userDataJson = jsonDecode(userData);
        setState(() {
          _token = token;
          _userId = userDataJson['id']?.toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void _handleNotificationTap(NotificationEntity notification) {
    // Handle notification tap based on type
    switch (notification.type) {
      case NotificationType.like:
      case NotificationType.reply:
      case NotificationType.mention:
        // Navigate to post detail if postId is available
        if (notification.postId != null && _token != null && _userId != null) {
          CommunityNavigation.navigateToPostDetail(
            context,
            postId: notification.postId!,
            token: _token,
            userId: _userId,
          );
        }
        break;
      case NotificationType.follow:
      case NotificationType.followRequest:
      case NotificationType.followRequestAccepted:
        // Navigate to user profile
        if (_token != null && _userId != null) {
          CommunityNavigation.navigateToUserProfile(
            context,
            userId: notification.actor.id,
          );
        }
        break;
      case NotificationType.notificationDeleted:
        // This shouldn't be tappable
        break;
    }
  }
}

// Custom header delegate for Activity title with size animation and back button
class _ActivityHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final ThemeData theme;

  _ActivityHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.theme,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Calculate progress from 0.0 (expanded) to 1.0 (collapsed)
    final progress = (shrinkOffset / (maxHeight - minHeight)).clamp(0.0, 1.0);

    // Check if header is stuck to top
    final isStuckToTop = shrinkOffset > 0;

    // Interpolate font size from 32 (expanded) to 24 (collapsed)
    final fontSize = 32.0 - (progress * 8.0);

    // Interpolate vertical padding
    final verticalPadding = 10.0 - (progress * 5.0);

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: verticalPadding),
      child: Row(
        children: [
          // Animated back button (appears when stuck)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isStuckToTop ? 40 : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isStuckToTop ? 1.0 : 0.0,
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: 40,
                child: CustomBackButton(
                  label: '',
                  iconSize: 24,
                  iconColor: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          // Activity title
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Activity",
                style: TextStyle(
                  color: theme.textTheme.titleLarge?.color,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_ActivityHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight;
  }
}

// Custom delegate for sticky filter tabs
class _FilterTabsDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final ThemeData theme;

  _FilterTabsDelegate({
    required this.height,
    required this.theme,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: const NotificationFilterTabs(),
    );
  }

  @override
  bool shouldRebuild(_FilterTabsDelegate oldDelegate) {
    return height != oldDelegate.height;
  }
}