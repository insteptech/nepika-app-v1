import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/community/entities/community_entities.dart';
import '../../../../core/widgets/index.dart';
import '../bloc/blocs/posts_bloc.dart';
import '../bloc/events/posts_event.dart';
import '../bloc/states/posts_state.dart';
import '../bloc/blocs/profile_bloc.dart';
import '../bloc/events/profile_event.dart';
import '../bloc/states/profile_state.dart';

/// Post menu component handling all post-related actions (edit, delete, block, report)
/// Follows Single Responsibility Principle - only handles post menu actions
class PostMenu {
  static void show({
    required BuildContext context,
    required PostEntity post,
    required String token,
    required String userId,
    required bool isCurrentUserPost,
    required Function(PostEntity) onPostUpdated,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        // Try to get ProfileBloc from the original context, handle gracefully if not available
        try {
          final profileBloc = context.read<ProfileBloc>();
          return BlocProvider<ProfileBloc>.value(
            value: profileBloc,
            child: _PostMenuContent(
              originalContext: context,
              post: post,
              token: token,
              userId: userId,
              isCurrentUserPost: isCurrentUserPost,
              onPostUpdated: onPostUpdated,
            ),
          );
        } catch (e) {
          // Fallback: Return content without ProfileBloc provider
          debugPrint('PostMenu: ProfileBloc not available, some features may be disabled: $e');
          return _PostMenuContent(
            originalContext: context,
            post: post,
            token: token,
            userId: userId,
            isCurrentUserPost: isCurrentUserPost,
            onPostUpdated: onPostUpdated,
          );
        }
      },
    );
  }
}

class _PostMenuContent extends StatelessWidget {
  final BuildContext originalContext;
  final PostEntity post;
  final String token;
  final String userId;
  final bool isCurrentUserPost;
  final Function(PostEntity) onPostUpdated;

  const _PostMenuContent({
    required this.originalContext,
    required this.post,
    required this.token,
    required this.userId,
    required this.isCurrentUserPost,
    required this.onPostUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              
              if (isCurrentUserPost) ...[
                // Options for current user's post
                _buildOptionTile(
                  context: context,
                  icon: Icons.edit_outlined,
                  title: 'Edit Post',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showEditPostDialog(context);
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionTile(
                  context: context,
                  icon: Icons.delete_outline,
                  title: 'Delete Post',
                  isDestructive: true,
                  onTap: () {
                    Navigator.of(context).pop();
                    _showDeleteConfirmation(context);
                  },
                ),
              ] else ...[
                // Options for other user's post
                _buildOptionTile(
                  context: context,
                  icon: Icons.block_outlined,
                  title: 'Block User',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showBlockUserDialog(context);
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionTile(
                  context: context,
                  icon: Icons.report_outlined,
                  title: 'Report Post',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showReportDialog(context);
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDestructive 
                ? Colors.red.withValues(alpha: 0.05)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDestructive 
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: isDestructive 
                    ? Colors.red.withValues(alpha: 0.8)
                    : Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDestructive 
                      ? Colors.red.withValues(alpha: 0.8)
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPostDialog(BuildContext context) {
    final TextEditingController editController = TextEditingController(text: post.content);
    int wordCount = post.content.trim().split(RegExp(r'\s+')).length;
    const int maxWords = 50;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        // Provide PostsBloc to the modal context
        return BlocProvider<PostsBloc>.value(
          value: originalContext.read<PostsBloc>(),
          child: StatefulBuilder(
          builder: (context, setState) {
            void updateWordCount() {
              final text = editController.text.trim();
              final words = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
              setState(() {
                wordCount = words;
              });
            }

            Color getWordCountColor() {
              if (wordCount > maxWords) return Colors.red;
              if (wordCount > maxWords * 0.8) return Colors.orange;
              return Colors.grey;
            }

            bool getCanUpdate() => editController.text.trim().isNotEmpty && 
                                 wordCount <= maxWords &&
                                 editController.text.trim() != post.content;

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle and title
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Edit Post',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Word count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$wordCount/$maxWords words',
                            style: TextStyle(
                              color: getWordCountColor(),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Text input
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: editController,
                          maxLines: 5,
                          minLines: 3,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'Update your post...',
                            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (value) => updateWordCount(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Update button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: BlocConsumer<PostsBloc, PostsState>(
                          listenWhen: (previous, current) => current is PostOperationState,
                          listener: (context, state) {
                            if (state is PostOperationSuccess && state.operationType == 'update') {
                              if (state.post != null) {
                                onPostUpdated(state.post!);
                              }
                              Navigator.of(modalContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(state.message),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else if (state is PostOperationError && state.operationType == 'update') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update post: ${state.message}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          builder: (context, state) {
                            final isLoading = state is PostOperationLoading && state.operationType == 'update';
                            final canUpdate = getCanUpdate();
                            return CustomButton(
                              text: 'Update Post',
                              onPressed: canUpdate && !isLoading ? () {
                                context.read<PostsBloc>().add(
                                  UpdatePost(
                                    token: token,
                                    postId: post.id,
                                    content: editController.text.trim(),
                                  ),
                                );
                              } : null,
                              isLoading: isLoading,
                              isDisabled: !canUpdate,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocProvider<PostsBloc>.value(
          value: originalContext.read<PostsBloc>(),
          child: AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            BlocConsumer<PostsBloc, PostsState>(
              listenWhen: (previous, current) => current is PostOperationState,
              listener: (context, state) {
                if (state is PostOperationSuccess && state.operationType == 'delete') {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (state is PostOperationError && state.operationType == 'delete') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete post: ${state.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                final isLoading = state is PostOperationLoading && state.operationType == 'delete';
                return ElevatedButton(
                  onPressed: isLoading ? null : () {
                    context.read<PostsBloc>().add(
                      DeletePost(
                        token: token,
                        postId: post.id,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Delete'),
                );
              },
            ),
          ],
        ),
        );
      },
    );
  }

  void _showBlockUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Provide ProfileBloc to the dialog context
        return BlocProvider<ProfileBloc>.value(
          value: originalContext.read<ProfileBloc>(),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.block, color: Colors.red.withValues(alpha: 0.8), size: 24),
                const SizedBox(width: 8),
                const Text('Block User'),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                'Are you sure you want to block ${post.username}?\n\nYou will no longer see their posts and they won\'t be able to interact with your content.',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            // Try to use ProfileBloc, fall back to simple button if not available
            Builder(
              builder: (builderContext) {
                try {
                  return BlocConsumer<ProfileBloc, ProfileState>(
              listener: (context, state) {
                if (state is BlockUserSuccess && state.userId == post.userId) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${post.username} has been blocked'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else if (state is BlockUserError && state.userId == post.userId) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to block user: ${state.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                final isLoading = state is BlockUserLoading && state.userId == post.userId;
                return ElevatedButton(
                  onPressed: isLoading ? null : () {
                    final blockData = BlockUserEntity(
                      userId: post.userId,
                      reason: 'Inappropriate behavior',
                    );
                    context.read<ProfileBloc>().add(
                      BlockUser(
                        token: token,
                        blockData: blockData,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Block'),
                );
              },
            );
                } catch (e) {
                  // Fallback: Simple block button without BLoC integration
                  debugPrint('PostMenu: ProfileBloc not available for block user dialog: $e');
                  return TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(builderContext).showSnackBar(
                        const SnackBar(
                          content: Text('Block feature temporarily unavailable'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    child: const Text('Block'),
                  );
                }
              },
            ),
          ],
        ),
        );
      },
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Report Post'),
          content: const Text('Thank you for helping keep our community safe. This post has been reported and will be reviewed by our moderation team.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post reported successfully'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Report'),
            ),
          ],
        );
      },
    );
  }
}