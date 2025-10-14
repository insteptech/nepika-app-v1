import 'package:flutter/material.dart';

/// Lightweight wrapper to detect scroll events - optimized for performance
class ScrollablePageWrapper extends StatelessWidget {
  final Widget child;
  final Function(double scrollOffset, double scrollDelta) onScroll;

  const ScrollablePageWrapper({
    super.key,
    required this.child,
    required this.onScroll,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        // Respond to any scroll updates for more responsive navbar behavior
        if (notification is ScrollUpdateNotification &&
            !notification.metrics.outOfRange &&
            notification.scrollDelta != null &&
            notification.scrollDelta!.abs() > 1.0) { // Reduced threshold for better responsiveness

          // Defer scroll handling to avoid calling setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onScroll(notification.metrics.pixels, notification.scrollDelta!);
          });
        }
        return false; // Allow the notification to continue
      },
      child: child,
    );
  }
}