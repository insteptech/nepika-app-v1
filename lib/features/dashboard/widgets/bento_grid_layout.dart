import 'package:flutter/material.dart';

/// Bento grid layout for displaying images in an asymmetric grid pattern
/// Creates a visually appealing masonry-style layout with varied patterns
class BentoGridLayout extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final EdgeInsets padding;

  const BentoGridLayout({
    super.key,
    required this.children,
    this.spacing = 12,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: Column(
        children: _buildBentoRows(),
      ),
    );
  }

  List<Widget> _buildBentoRows() {
    final List<Widget> rows = [];
    int index = 0;
    int rowNumber = 0;

    while (index < children.length) {
      // Alternate between large-left and small-left patterns only
      final bool isLargeLeft = rowNumber % 2 == 0;
      final pattern = isLargeLeft ? _RowPattern.largeLeft : _RowPattern.smallLeft;
      
      debugPrint('🔲 Bento Row $rowNumber: Pattern ${pattern.name} (images: $index-${index + 1})');

      switch (pattern) {
        case _RowPattern.largeLeft:
          rows.add(_buildLargeLeftRow(index));
          break;
        case _RowPattern.smallLeft:
          rows.add(_buildSmallLeftRow(index));
          break;
        case _RowPattern.twoEqual:
          // This case should never be reached now
          rows.add(_buildTwoEqualRow(index));
          break;
      }

      index += 2;

      if (index < children.length) {
        rows.add(SizedBox(height: spacing));
      }

      rowNumber++;
    }

    return rows;
  }

  Widget _buildLargeLeftRow(int startIndex) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Large item on left (2/3 width)
          Expanded(
            flex: 2,
            child: startIndex < children.length
                ? children[startIndex]
                : const SizedBox.shrink(),
          ),
          SizedBox(width: spacing),
          // Small item on right (1/3 width)
          Expanded(
            flex: 1,
            child: startIndex + 1 < children.length
                ? children[startIndex + 1]
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallLeftRow(int startIndex) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Small item on left (1/3 width)
          Expanded(
            flex: 1,
            child: startIndex < children.length
                ? children[startIndex]
                : const SizedBox.shrink(),
          ),
          SizedBox(width: spacing),
          // Large item on right (2/3 width)
          Expanded(
            flex: 2,
            child: startIndex + 1 < children.length
                ? children[startIndex + 1]
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoEqualRow(int startIndex) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Equal left item
          Expanded(
            flex: 1,
            child: startIndex < children.length
                ? children[startIndex]
                : const SizedBox.shrink(),
          ),
          SizedBox(width: spacing),
          // Equal right item
          Expanded(
            flex: 1,
            child: startIndex + 1 < children.length
                ? children[startIndex + 1]
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Row pattern types for varied layouts
enum _RowPattern {
  largeLeft,
  smallLeft,
  twoEqual,
}

/// Grid item for bento layout with consistent aspect ratio
class BentoGridItem extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double aspectRatio;
  final BorderRadius? borderRadius;

  const BentoGridItem({
    super.key,
    required this.child,
    this.onTap,
    this.aspectRatio = 1.2,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(20),
          child: child,
        ),
      ),
    );
  }
}
