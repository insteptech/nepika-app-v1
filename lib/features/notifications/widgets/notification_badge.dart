import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_state.dart';
import '../bloc/notification_event.dart';
import '../../../core/config/constants/routes.dart';

class NotificationBadge extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final double iconSize;

  const NotificationBadge({
    super.key,
    this.onTap,
    this.iconColor,
    this.badgeColor,
    this.badgeTextColor,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        int unreadCount = 0;
        
        if (state is NotificationLoaded) {
          unreadCount = state.unreadCount;
        } else if (state is NotificationError) {
          unreadCount = state.unreadCount;
        } else if (state is NotificationConnecting) {
          unreadCount = state.unreadCount;
        } else if (state is NotificationDisconnected) {
          unreadCount = state.unreadCount;
        }

        return GestureDetector(
          onTap: () {
            onTap?.call();
            // Navigate to notifications screen and mark as seen
            context.read<NotificationBloc>().add(const MarkAllNotificationsAsSeen());
            Navigator.pushNamed(context, AppRoutes.notifications);
          },
          child: Stack(
            children: [
              // Notification bell icon
              Icon(
                Icons.notifications_none_outlined,
                size: iconSize,
                color: iconColor ?? Theme.of(context).iconTheme.color,
              ),
              
              // Badge for unread count
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor ?? Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: TextStyle(
                        color: badgeTextColor ?? Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Alternative notification icon using SVG (if you have custom icons)
class NotificationBadgeSVG extends StatelessWidget {
  final String iconPath;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final double iconSize;

  const NotificationBadgeSVG({
    super.key,
    required this.iconPath,
    this.onTap,
    this.iconColor,
    this.badgeColor,
    this.badgeTextColor,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        int unreadCount = 0;
        
        if (state is NotificationLoaded) {
          unreadCount = state.unreadCount;
        } else if (state is NotificationError) {
          unreadCount = state.unreadCount;
        } else if (state is NotificationConnecting) {
          unreadCount = state.unreadCount;
        } else if (state is NotificationDisconnected) {
          unreadCount = state.unreadCount;
        }

        return GestureDetector(
          onTap: () {
            onTap?.call();
            // Navigate to notifications screen and mark as seen
            context.read<NotificationBloc>().add(const MarkAllNotificationsAsSeen());
            Navigator.pushNamed(context, AppRoutes.notifications);
          },
          child: Stack(
            children: [
              // Custom SVG notification icon
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: iconColor ?? Theme.of(context).iconTheme.color,
                ),
                // TODO: Replace with SvgPicture.asset(iconPath) if using flutter_svg
                child: Icon(
                  Icons.notifications_none_outlined,
                  size: iconSize,
                  color: iconColor ?? Theme.of(context).iconTheme.color,
                ),
              ),
              
              // Badge for unread count
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor ?? Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: TextStyle(
                        color: badgeTextColor ?? Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}