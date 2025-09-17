import 'package:flutter/material.dart';

class AnimatedRoutineHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;

  AnimatedRoutineHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final bool isCollapsed = progress > 0.7;
    
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Back button (always visible)
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isCollapsed
                    ? Row(
                        key: const ValueKey('collapsed'),
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Today's Routine",
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('expanded'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Back',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                ),
              ),
              
              // Title section (only visible when expanded)
              if (!isCollapsed) ...[
                const SizedBox(height: 25),
                Text(
                  "Today's Routine",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Stay consistent. Mark each step as you complete it.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(AnimatedRoutineHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight || maxHeight != oldDelegate.maxHeight;
  }
}

class AnimatedRoutineHeader extends StatelessWidget {
  final Widget child;
  final int completedCount;
  final int totalCount;

  const AnimatedRoutineHeader({
    super.key,
    required this.child,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Animated sticky header
        SliverPersistentHeader(
          pinned: true,
          delegate: AnimatedRoutineHeaderDelegate(
            minHeight: 70,
            maxHeight: 180,
          ),
        ),
        
        // Steps header (static)
        SliverToBoxAdapter(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Steps',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        'Completed: $completedCount/$totalCount',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        
        // Main content
        SliverToBoxAdapter(child: child),
      ],
    );
  }
}