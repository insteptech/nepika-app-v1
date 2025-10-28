import 'package:flutter/material.dart';

class ProgressiveStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final double crossButtonScrollThreshold;
  final double titleScrollThreshold;
  final String title;
  final Color? backgroundColor;

  ProgressiveStickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.crossButtonScrollThreshold,
    required this.titleScrollThreshold,
    required this.title,
    this.backgroundColor,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    try {
      // Stage detection based on scroll position
      final bool showBackButton = shrinkOffset >= crossButtonScrollThreshold;
      final bool showTitle = shrinkOffset >= titleScrollThreshold;
      
      // Always show header container but content depends on scroll
      
      return Container(
        height: maxHeight,
        decoration: BoxDecoration(
          // Always show some background for debugging
          color: showBackButton 
              ? Colors.white
              : Colors.red.withValues(alpha: 0.2), // Red background to see if header is there
          border: Border.all(color: Colors.orange, width: 2), // Orange border for debugging
          boxShadow: showBackButton ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // Debug info
            Text(
              'Scroll: ${shrinkOffset.toStringAsFixed(0)} | Back: $showBackButton | Title: $showTitle',
              style: const TextStyle(fontSize: 10, color: Colors.purple),
            ),
            Expanded(
              child: Row(
                children: [
            // Back button with animation
            SizedBox(
              width: 40,
              child: showBackButton 
                ? GestureDetector(
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1), // Visible background for testing
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.blue, // Force blue color for visibility
                        size: 24,
                      ),
                    ),
                  )
                : const SizedBox(width: 40, height: 32), // Placeholder instead of shrink
            ),
            
            // Title
            Expanded(
              child: showTitle 
                ? Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Force black color for visibility
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                : const SizedBox(height: 32), // Placeholder instead of shrink
            ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // Fallback in case of any errors
      return Container(
        height: maxHeight,
        color: backgroundColor ?? Colors.white,
        child: const SizedBox.shrink(),
      );
    }
  }

  @override
  bool shouldRebuild(ProgressiveStickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        crossButtonScrollThreshold != oldDelegate.crossButtonScrollThreshold ||
        titleScrollThreshold != oldDelegate.titleScrollThreshold ||
        title != oldDelegate.title ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}