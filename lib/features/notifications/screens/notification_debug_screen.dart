import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/notification_service.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_state.dart';
import '../bloc/notification_event.dart';

class NotificationDebugScreen extends StatelessWidget {
  const NotificationDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Debug'),
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Status
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connection Status',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              state is NotificationLoaded && state.isConnected
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: state is NotificationLoaded && state.isConnected
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              state is NotificationLoaded && state.isConnected
                                  ? 'Connected'
                                  : 'Disconnected',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // State Information
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current State',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('State Type: ${state.runtimeType}'),
                        if (state is NotificationLoaded) ...[
                          Text('Unread Count: ${state.unreadCount}'),
                          Text('Total Notifications: ${state.notifications.length}'),
                          Text('Filtered Notifications: ${state.filteredNotifications.length}'),
                          Text('Current Filter: ${state.currentFilter.displayName}'),
                        ],
                        if (state is NotificationError) ...[
                          Text('Error: ${state.message}'),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Debug Actions
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Debug Actions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                context.read<NotificationBloc>().add(
                                  const ConnectToNotificationStream(),
                                );
                              },
                              child: const Text('Connect SSE'),
                            ),
                            
                            ElevatedButton(
                              onPressed: () {
                                context.read<NotificationBloc>().add(
                                  const DisconnectFromNotificationStream(),
                                );
                              },
                              child: const Text('Disconnect SSE'),
                            ),
                            
                            ElevatedButton(
                              onPressed: () {
                                context.read<NotificationBloc>().add(
                                  const FetchUnreadCount(),
                                );
                              },
                              child: const Text('Fetch Unread Count'),
                            ),
                            
                            ElevatedButton(
                              onPressed: () {
                                context.read<NotificationBloc>().add(
                                  const MarkAllNotificationsAsSeen(),
                                );
                              },
                              child: const Text('Mark All Seen'),
                            ),
                            
                            ElevatedButton(
                              onPressed: () {
                                NotificationService.instance.addTestNotification();
                              },
                              child: const Text('Add Test Notification'),
                            ),
                            
                            ElevatedButton(
                              onPressed: () {
                                context.read<NotificationBloc>().add(
                                  const ClearAllNotifications(),
                                );
                              },
                              child: const Text('Clear All'),
                            ),
                            
                            ElevatedButton(
                              onPressed: () async {
                                final result = await NotificationService.instance.testConnection();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result 
                                          ? 'Backend connection successful!' 
                                          : 'Backend connection failed!',
                                      ),
                                      backgroundColor: result ? Colors.green : Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Test Backend'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Notifications List
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: state is NotificationLoaded
                                ? state.notifications.isEmpty
                                    ? const Center(
                                        child: Text('No notifications'),
                                      )
                                    : ListView.builder(
                                        itemCount: state.notifications.length,
                                        itemBuilder: (context, index) {
                                          final notification = state.notifications[index];
                                          return ListTile(
                                            leading: Icon(_getIconForType(notification.type)),
                                            title: Text(notification.actor.username),
                                            subtitle: Text(notification.message),
                                            trailing: Text(
                                              _formatTime(notification.createdAt),
                                            ),
                                          );
                                        },
                                      )
                                : const Center(
                                    child: Text('No notifications loaded'),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(type) {
    switch (type.toString()) {
      case 'NotificationType.like':
        return Icons.favorite;
      case 'NotificationType.reply':
        return Icons.chat_bubble;
      case 'NotificationType.follow':
        return Icons.person_add;
      case 'NotificationType.mention':
        return Icons.alternate_email;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}