import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loader for bento grid items that matches the actual bento layout
class BentoGridSkeleton extends StatelessWidget {
  final int itemCount;
  final double spacing;

  const BentoGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Column(
        children: _buildBentoSkeletonRows(),
      ),
    );
  }

  List<Widget> _buildBentoSkeletonRows() {
    final List<Widget> rows = [];
    int index = 0;

    // Same layout patterns as BentoGridLayout
    final patterns = [
      _SkeletonRowPattern.largeLeft,
      _SkeletonRowPattern.smallLeft,
      _SkeletonRowPattern.largeLeft,
      _SkeletonRowPattern.twoEqual,
      _SkeletonRowPattern.smallLeft,
      _SkeletonRowPattern.largeLeft,
      _SkeletonRowPattern.twoEqual,
      _SkeletonRowPattern.smallLeft,
    ];

    int patternIndex = 0;

    while (index < itemCount) {
      final pattern = patterns[patternIndex % patterns.length];

      switch (pattern) {
        case _SkeletonRowPattern.largeLeft:
          rows.add(_buildLargeLeftSkeletonRow());
          break;
        case _SkeletonRowPattern.smallLeft:
          rows.add(_buildSmallLeftSkeletonRow());
          break;
        case _SkeletonRowPattern.twoEqual:
          rows.add(_buildTwoEqualSkeletonRow());
          break;
      }

      index += 2;
      if (index < itemCount) {
        rows.add(SizedBox(height: spacing));
      }

      patternIndex++;
    }

    return rows;
  }

  Widget _buildLargeLeftSkeletonRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Large item on left (2/3 width)
          Expanded(
            flex: 2,
            child: _buildSkeletonItem(),
          ),
          SizedBox(width: spacing),
          // Small item on right (1/3 width)
          Expanded(
            flex: 1,
            child: _buildSkeletonItem(),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallLeftSkeletonRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Small item on left (1/3 width)
          Expanded(
            flex: 1,
            child: _buildSkeletonItem(),
          ),
          SizedBox(width: spacing),
          // Large item on right (2/3 width)
          Expanded(
            flex: 2,
            child: _buildSkeletonItem(),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoEqualSkeletonRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Equal left item
          Expanded(
            flex: 1,
            child: _buildSkeletonItem(),
          ),
          SizedBox(width: spacing),
          // Equal right item
          Expanded(
            flex: 1,
            child: _buildSkeletonItem(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonItem() {
    return AspectRatio(
      aspectRatio: 1.2, // Same aspect ratio as BentoGridItem
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20), // Same border radius as BentoGridItem
        ),
      ),
    );
  }
}

/// Row pattern types for skeleton layout
enum _SkeletonRowPattern {
  largeLeft,
  smallLeft,
  twoEqual,
}

/// Skeleton loader for individual image tiles
class ImageTileSkeleton extends StatelessWidget {
  const ImageTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      period: const Duration(milliseconds: 800), // Faster shimmer animation
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Skeleton for header count
class HeaderCountSkeleton extends StatelessWidget {
  const HeaderCountSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: 80,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
