import 'package:flutter/material.dart';

class SkeletonLoading extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const SkeletonLoading({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Colors.transparent,
                Color(0xFFF5F5F5),
                Colors.transparent,
              ],
              stops: [
                0.0,
                0.5,
                1.0,
              ],
              transform: GradientRotation(_animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class SkeletonContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;

  const SkeletonContainer({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }
}

// Post Skeleton
class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoading(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 1),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row
            Row(
              children: [
                SkeletonContainer(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonContainer(
                        width: 120,
                        height: 14,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      const SizedBox(height: 4),
                      SkeletonContainer(
                        width: 80,
                        height: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ),
                SkeletonContainer(
                  width: 24,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Post content
            SkeletonContainer(
              width: double.infinity,
              height: 16,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            SkeletonContainer(
              width: MediaQuery.of(context).size.width * 0.75,
              height: 16,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                SkeletonContainer(
                  width: 60,
                  height: 32,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(width: 16),
                SkeletonContainer(
                  width: 60,
                  height: 32,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(width: 16),
                SkeletonContainer(
                  width: 60,
                  height: 32,
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Comment Skeleton
class CommentSkeleton extends StatelessWidget {
  const CommentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoading(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 1),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row
            Row(
              children: [
                SkeletonContainer(
                  width: 32,
                  height: 32,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonContainer(
                        width: 100,
                        height: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(height: 2),
                      SkeletonContainer(
                        width: 60,
                        height: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Comment content
            SkeletonContainer(
              width: double.infinity,
              height: 14,
              borderRadius: BorderRadius.circular(7),
            ),
            const SizedBox(height: 4),
            SkeletonContainer(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 14,
              borderRadius: BorderRadius.circular(7),
            ),
            const SizedBox(height: 8),
            
            // Like button
            SkeletonContainer(
              width: 40,
              height: 24,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
      ),
    );
  }
}

// Profile Skeleton
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoading(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Row(
              children: [
                SkeletonContainer(
                  width: 80,
                  height: 80,
                  borderRadius: BorderRadius.circular(40),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonContainer(
                        width: 150,
                        height: 20,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 8),
                      SkeletonContainer(
                        width: 100,
                        height: 16,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SkeletonContainer(
                            width: 60,
                            height: 14,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          const SizedBox(width: 20),
                          SkeletonContainer(
                            width: 60,
                            height: 14,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Bio
            SkeletonContainer(
              width: double.infinity,
              height: 16,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            SkeletonContainer(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 16,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 20),
            
            // Follow button
            SkeletonContainer(
              width: 120,
              height: 40,
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
      ),
    );
  }
}

// User List Item Skeleton (for followers/following)
class UserListItemSkeleton extends StatelessWidget {
  const UserListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoading(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SkeletonContainer(
              width: 50,
              height: 50,
              borderRadius: BorderRadius.circular(25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonContainer(
                    width: 120,
                    height: 16,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 4),
                  SkeletonContainer(
                    width: 80,
                    height: 14,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  const SizedBox(height: 4),
                  SkeletonContainer(
                    width: 60,
                    height: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
            ),
            SkeletonContainer(
              width: 80,
              height: 32,
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
      ),
    );
  }
}

// Post Feed Skeleton (multiple posts)
class PostFeedSkeleton extends StatelessWidget {
  final int itemCount;
  
  const PostFeedSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => const PostSkeleton(),
      ),
    );
  }
}

// Comments Feed Skeleton
class CommentsFeedSkeleton extends StatelessWidget {
  final int itemCount;
  
  const CommentsFeedSkeleton({
    super.key,
    this.itemCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => const CommentSkeleton(),
      ),
    );
  }
}

// User List Skeleton
class UserListSkeleton extends StatelessWidget {
  final int itemCount;
  
  const UserListSkeleton({
    super.key,
    this.itemCount = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => const UserListItemSkeleton(),
      ),
    );
  }
}