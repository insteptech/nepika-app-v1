import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/presentation/community/widgets/like_comment_share_row.dart';
import 'package:nepika/presentation/community/widgets/page_header.dart';
import 'package:nepika/presentation/community/widgets/user_icon.dart';
import 'package:nepika/presentation/community/widgets/user_name.dart';
import 'package:nepika/presentation/community/widgets/user_post.dart';
import '../../../domain/community/entities/community_entities.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';

class PostDetailPage extends StatefulWidget {
  final String token;
  final String postId;
  final String userId;

  const PostDetailPage({
    super.key,
    required this.token,
    required this.postId,
    required this.userId,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Local state to track like status
  Map<String, bool> _localLikeStates = {};

  @override
  void initState() {
    super.initState();
    // Fetch the post details when the page loads
    context.read<CommunityBloc>().add(
      FetchSinglePost(token: widget.token, postId: widget.postId),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  void _navigateToSearch() {
    Navigator.pushNamed(
      context,
      AppRoutes.communitySearch,
      arguments: widget.token,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<CommunityBloc, CommunityState>(
        builder: (context, state) {
          if (state is PostDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PostDetailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading post',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CommunityBloc>().add(
                        FetchSinglePost(
                          token: widget.token,
                          postId: widget.postId,
                        ),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is PostDetailLoaded) {
            debugPrint('Post Detail Loaded: ${state.post}');
            return _buildPostDetailContent(context, state.post);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPostDetailContent(BuildContext context, PostDetailEntity post) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PageHeader(onSearchTap: _navigateToSearch),
            ),
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Main Post
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildMainPost(context, post),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      height: 1,
                      width: double.infinity,
                      color: Theme.of(context).textTheme.headlineMedium!
                          .secondary(context)
                          .color!
                          .withValues(alpha: 0.2),
                    ),
                  ),

                  // Comments List
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final comment = post.comments[index];
                      debugPrint(
                        'Comment Author Avatar URL: ${comment.author.avatarUrl}',
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 5,
                        ),
                        child: UserPostWidget(
                          disableActions: true,
                          post: comment,
                          token: widget.token,
                          userId: widget.userId,
                        ),
                      );
                    }, childCount: post.comments.length),
                  ),

                  // Bottom spacing
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),

            // Comment Input
            _buildCommentInput(context, post),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPost(BuildContext context, PostDetailEntity post) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Row
          Row(
            children: [
              // Avatar
              UserImageIcon(author: post.author, padding: 0),
              const SizedBox(width: 12),
              UserNameWithNavigation(postDetail: post),
               
              
              // TODO: Implement more options
              IconButton(
                icon: Icon(Icons.more_horiz, color: Colors.grey[600], size: 20),
                onPressed: () {
                  // TODO: Implement more options
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Post Content
          Text(post.content, style: Theme.of(context).textTheme.headlineMedium),

          const SizedBox(height: 15),

          LikeCommentShareRow(
            postId: post.postId,
            initialLikeStatus: _isPostLikedByUser(post),
            initialLikeCount: post.likeCount,
            size: 22,
            activeColor: Colors.red,
            showCount: false,
          ),

          const SizedBox(height: 15),

          RichText(
            text: TextSpan(
              style: Theme.of(
                context,
              ).textTheme.headlineMedium!.secondary(context),
              children: [
                TextSpan(text: '${post.commentCount} replies'),
                if (post.likes.isNotEmpty) ...[
                  const TextSpan(text: ' • '),
                  TextSpan(text: '${_formatLikeCount(post.likeCount)} likes'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        isActive ? activeIcon : icon,
        color: isActive ? Colors.red : Colors.grey[700],
        size: 22,
      ),
    );
  }

  Widget _buildCommentInput(BuildContext context, PostDetailEntity post) {
    return Container(
      padding: const EdgeInsets.only(left: 18, right: 18, top: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 53,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onTertiary,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).textTheme.headlineMedium!.secondary(context).color!,
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.only(right: 3),
                child: TextField(
                  key: post.postId.isNotEmpty
                      ? Key('comment_input_${post.postId}')
                      : null,
                  controller: _commentController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Comment',
                    hintStyle: Theme.of(
                      context,
                    ).textTheme.bodyLarge!.secondary(context),
                    fillColor: Colors.transparent,
                    prefixIcon: UserImageIcon(author: post.author, padding: 6),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitComment(String content) {
    // TODO: Implement comment submission
    debugPrint('Submitting comment: $content');
    _commentController.clear();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  String _formatLikeCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  bool _isPostLikedByUser(PostDetailEntity post) {
    // Check if current user has liked this post or local state
    final localState = _localLikeStates[post.postId];
    if (localState != null) {
      return localState;
    }
    return post.likes.any((like) => like.userId == widget.userId);
  }
}
