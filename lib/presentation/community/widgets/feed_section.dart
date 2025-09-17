import 'package:flutter/material.dart';
import '../../../domain/community/entities/community_entities.dart';
import 'thread_card.dart';

class FeedSection extends StatelessWidget {
  final PageController pageController;
  final List<PostEntity> threads;
  final List<PostEntity> replies;
  final bool loadingThreads;
  final bool loadingReplies;
  final Function(int) onPageChanged;
  final Function(String postId)? onLike;
  final Function(String postId)? onShare;
  final Function(PostEntity post)? onPostTap;
  final VoidCallback? onLoadMoreThreads;
  final VoidCallback? onLoadMoreReplies;

  const FeedSection({
    super.key,
    required this.pageController,
    required this.threads,
    required this.replies,
    required this.loadingThreads,
    required this.loadingReplies,
    required this.onPageChanged,
    this.onLike,
    this.onShare,
    this.onPostTap,
    this.onLoadMoreThreads,
    this.onLoadMoreReplies,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      onPageChanged: onPageChanged,
      physics: const PageScrollPhysics(), // Proper page snap behavior
      pageSnapping: true, // Enable page snapping
      itemCount: 2, // Threads and Replies
      itemBuilder: (context, pageIndex) {
        if (pageIndex == 0) {
          return _buildFeedPage(
            context,
            posts: threads,
            isLoading: loadingThreads,
            onLoadMore: onLoadMoreThreads,
            emptyMessage: 'No threads yet',
          );
        } else {
          return _buildFeedPage(
            context,
            posts: replies,
            isLoading: loadingReplies,
            onLoadMore: onLoadMoreReplies,
            emptyMessage: 'No replies yet',
          );
        }
      },
    );
  }

  Widget _buildFeedPage(
    BuildContext context, {
    required List<PostEntity> posts,
    required bool isLoading,
    required VoidCallback? onLoadMore,
    required String emptyMessage,
  }) {
    if (isLoading && posts.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.grey.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          onLoadMore?.call();
        },
        color: Theme.of(context).colorScheme.primary,
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: posts.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == posts.length) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            }

            final post = posts[index];
            return ThreadCard(
              post: post,
              onTap: () => onPostTap?.call(post),
              onLike: () => onLike?.call(post.id),
              onShare: () => onShare?.call(post.id),
            );
          },
        ),
      ),
    );
  }

}