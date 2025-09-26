import 'package:flutter/material.dart';
import 'package:nepika/core/widgets/back_button.dart';

class SettingsHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool isPinned;

  const SettingsHeader({
    super.key,
    this.title = 'Settings',
    this.showBackButton = false,
    this.onBack,
    this.isPinned = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      floating: true,
      delegate: _SettingsHeaderDelegate(
        title: title,
        showBackButton: showBackButton,
        onBack: onBack,
        isPinned: true,
      ),
    );
  }
}

class _SettingsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool isPinned;

  const _SettingsHeaderDelegate({
    required this.title,
    required this.showBackButton,
    required this.onBack,
    required this.isPinned
  });

  @override
  double get minExtent => 50.0;

  @override
  double get maxExtent => 60.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    
    // Calculate dynamic padding - equal top and bottom spacing
    final topPadding = (8 - (2 * progress)).clamp(2.0, 8.0);
    final bottomPadding = (8 - (2 * progress)).clamp(2.0, 8.0);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: (maxExtent - shrinkOffset - 1).clamp(minExtent - 1, maxExtent - 1),
            padding: EdgeInsets.only(
              top: topPadding,
              bottom: bottomPadding,
              left: 20,
              right: 20,
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: (showBackButton || progress > 0.3) ? 1.0 : 0.0,
                    child: Center(
                      child: CustomBackButton(
                        label: showBackButton && isPinned ? 'Back' : '',
                        onPressed:
                            onBack ?? () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
                // Title with sliding animation
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  left: progress > 0.3 ? 28 : 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment: progress > 0.3
                        ? Alignment.centerLeft
                        : Alignment.center,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                      ),
                      child: Text(
                        title,
                        style: theme.textTheme.bodyLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: 1,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate != this;
  }
}
