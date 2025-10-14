import 'package:flutter/material.dart';

/// Skeleton loader that matches the exact structure of UserPostWidget
/// Shows animated shimmer effect while posts are loading
class PostSkeletonLoader extends StatefulWidget {
  final int itemCount;

  const PostSkeletonLoader({
    super.key,
    this.itemCount = 3,
  });

  @override
  State<PostSkeletonLoader> createState() => _PostSkeletonLoaderState();
}

class _PostSkeletonLoaderState extends State<PostSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _PostSkeletonItem(animation: _animation),
      ),
    );
  }
}

/// Single post skeleton item matching UserPostWidget structure
/// Minimized design for cleaner loading state
class _PostSkeletonItem extends StatelessWidget {
  final Animation<double> animation;

  const _PostSkeletonItem({required this.animation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar skeleton (matching UserImageIcon)
            _SkeletonBox(
              width: 42,
              height: 42,
              borderRadius: BorderRadius.circular(21),
              baseColor: baseColor,
              highlightColor: highlightColor,
              opacity: animation.value,
            ),
            const SizedBox(width: 10),

            // Post content area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section (username and timestamp only)
                  Row(
                    children: [
                      // Username skeleton
                      _SkeletonBox(
                        width: 90,
                        height: 12,
                        borderRadius: BorderRadius.circular(4),
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                        opacity: animation.value,
                      ),
                      const SizedBox(width: 8),
                      // Timestamp skeleton
                      _SkeletonBox(
                        width: 35,
                        height: 10,
                        borderRadius: BorderRadius.circular(4),
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                        opacity: animation.value,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Post content skeleton (2 lines only)
                  _SkeletonBox(
                    width: double.infinity,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    opacity: animation.value,
                  ),
                  const SizedBox(height: 6),
                  _SkeletonBox(
                    width: 180,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    opacity: animation.value,
                  ),

                  const SizedBox(height: 12),

                  // Actions section (simplified)
                  Row(
                    children: [
                      // Like button skeleton
                      _SkeletonBox(
                        width: 50,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                        opacity: animation.value,
                      ),
                      const SizedBox(width: 12),
                      // Comment button skeleton
                      _SkeletonBox(
                        width: 55,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                        opacity: animation.value,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Reusable skeleton box with shimmer effect
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Color baseColor;
  final Color highlightColor;
  final double opacity;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.baseColor,
    required this.highlightColor,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color.lerp(baseColor, highlightColor, opacity),
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Single skeleton loader for loading more posts at the bottom
class SinglePostSkeleton extends StatefulWidget {
  const SinglePostSkeleton({super.key});

  @override
  State<SinglePostSkeleton> createState() => _SinglePostSkeletonState();
}

class _SinglePostSkeletonState extends State<SinglePostSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: _PostSkeletonItem(animation: _animation),
    );
  }
}
