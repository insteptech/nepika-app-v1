import 'package:flutter/material.dart';
import '../../../core/widgets/back_button.dart';

class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;
  final bool isFirstHeader;
  final bool showAnimatedBackButton;
  final String? title;
  final Color? backgroundColor;

  StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
    this.isFirstHeader = false,
    this.showAnimatedBackButton = false,
    this.title,
    this.backgroundColor,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    if ((isFirstHeader || showAnimatedBackButton) && title != null) {
      // Check if header is stuck to top - when shrinkOffset equals the difference
      final isStuckToTop = shrinkOffset > 0;
      
      return Container(
        color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        padding: showAnimatedBackButton 
            ? const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
            : const EdgeInsets.only(left: 20, right: 20),
        child: Row(
          children: [
            // Show back button with slide animation only when stuck to top
            if (isFirstHeader || showAnimatedBackButton)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: ((isFirstHeader || showAnimatedBackButton) && isStuckToTop) ? 40 : 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: ((isFirstHeader || showAnimatedBackButton) && isStuckToTop) ? 1.0 : 0.0,
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    maxWidth: 40,
                    child: CustomBackButton(
                      label: '',
                      iconSize: 24,
                      iconColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return SizedBox.expand(child: child);
    }
  }

  @override
  bool shouldRebuild(StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child ||
        isFirstHeader != oldDelegate.isFirstHeader ||
        showAnimatedBackButton != oldDelegate.showAnimatedBackButton ||
        title != oldDelegate.title ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}