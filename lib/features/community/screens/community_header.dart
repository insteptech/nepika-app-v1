import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/back_button.dart';
import '../../notifications/widgets/notification_badge.dart';
import '../../notifications/bloc/notification_bloc.dart';
import '../../notifications/bloc/notification_event.dart';

/// Community header component with logo, back button, search, and notifications
/// Follows Single Responsibility Principle - only handles header display
class CommunityHeader extends SliverPersistentHeaderDelegate {
  final VoidCallback onSearchTap;

  CommunityHeader({required this.onSearchTap});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Calculate the shrink progress (0.0 to 1.0)
    final progress = shrinkOffset / maxExtent;
    final clampedProgress = progress.clamp(0.0, 1.0);
    
    // Interpolate heights for logo and search icon
    final logoHeight = 30.0 - (8.0 * clampedProgress); // 30 -> 22
    final searchHeight = 25.0 - (7.0 * clampedProgress); // 25 -> 18
    final containerHeight = maxExtent - (shrinkOffset.clamp(0.0, maxExtent - minExtent));

    return Container(
      height: containerHeight,
      color: Theme.of(context).colorScheme.onTertiary,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Nepika Logo
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            child: Image.asset(
              'assets/images/nepika_logo_image.png',
              height: logoHeight,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          // Back Button
          const Positioned(
            left: 0,
            child: CustomBackButton(),
          ),

          // Search and Notification Icons
          Positioned(
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search Icon
                GestureDetector(
                  onTap: onSearchTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/icons/search_icon.png',
                      height: searchHeight,
                    ),
                  ),
                ),
                
                const SizedBox(width: 9),
                
                // Notification Badge
                BlocProvider(
                  create: (context) => NotificationBloc()..add(const ConnectToNotificationStream()),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: NotificationBadge(
                      iconSize: searchHeight,
                      iconColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 70.0; // Full height
  
  @override
  double get minExtent => 50.0; // Minimum height when sticky

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}