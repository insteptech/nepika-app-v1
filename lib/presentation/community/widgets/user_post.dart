import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/widgets/index.dart';
import 'package:nepika/presentation/community/pages/post_detail_page_integration.dart';
import 'package:nepika/presentation/community/widgets/like_comment_share_row.dart';
import 'package:nepika/presentation/community/widgets/user_icon.dart';
import 'package:nepika/presentation/community/widgets/user_name.dart';
import '../../../domain/community/entities/community_entities.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';

class UserPostWidget extends StatefulWidget {
  final PostEntity post;
  final String token;
  final String userId;
  final bool disableActions;

  const UserPostWidget({
    super.key,
    required this.post,
    required this.token,
    required this.userId,
    this.disableActions = false,
  });

  @override
  State<UserPostWidget> createState() => _UserPostWidgetState();
}

class _UserPostWidgetState extends State<UserPostWidget> {
  late PostEntity _currentPost;
  late int _currentLikeCount;
  late bool _currentLikeStatus;
  
  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _currentLikeCount = widget.post.likeCount;
    _currentLikeStatus = widget.post.isLikedByUser;
  }

  // Callback to update like count from LikeButton
  void _onLikeStatusChanged(bool isLiked, int newLikeCount) {
    if (mounted) {
      setState(() {
        _currentLikeStatus = isLiked;
        _currentLikeCount = newLikeCount;
      });
    }
  }

  bool get isLiked {
    return _currentLikeStatus;
  }

  bool get isCurrentUserPost {
    return _currentPost.userId == widget.userId;
  }

  String _timeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

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

  // Helper method to create clickable text spans with links and hashtags
  List<TextSpan> _buildClickableTextSpans(String text, TextStyle? baseStyle) {
    final List<TextSpan> spans = [];
    
    // Regex patterns for URLs and hashtags
    final urlPattern = RegExp(r'https?://[^\s]+|www\.[^\s]+|[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(?:/[^\s]*)?');
    final hashtagPattern = RegExp(r'#[a-zA-Z0-9_-]+');
    
    // Find all matches (URLs and hashtags)
    final allMatches = <Match>[];
    allMatches.addAll(urlPattern.allMatches(text));
    allMatches.addAll(hashtagPattern.allMatches(text));
    
    // Sort matches by start position
    allMatches.sort((a, b) => a.start.compareTo(b.start));
    
    int lastIndex = 0;
    
    for (final match in allMatches) {
      // Add normal text before the match
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }
      
      final matchText = match.group(0)!;
      
      if (urlPattern.hasMatch(matchText)) {
        // Handle URL
        spans.add(TextSpan(
          text: matchText,
          style: baseStyle?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w500,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _launchUrl(matchText),
        ));
      } else if (hashtagPattern.hasMatch(matchText)) {
        // Handle Hashtag
        spans.add(TextSpan(
          text: matchText,
          style: baseStyle?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            // Keep the same font weight as base style, don't make it bolder
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _handleHashtagTap(matchText),
        ));
      }
      
      lastIndex = match.end;
    }
    
    // Add remaining normal text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }
    
    return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
  }

  // Handle URL launch
  void _launchUrl(String url) async {
    try {
      // Ensure URL has protocol
      String fullUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        fullUrl = 'https://$url';
      }
      
      final uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open $url'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }




    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle hashtag tap
  void _handleHashtagTap(String hashtag) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hashtag tapped: $hashtag'),
          duration: const Duration(seconds: 1),
        ),
      );
      // TODO: Navigate to hashtag search or trending page
      // Navigator.pushNamed(context, AppRoutes.hashtagSearch, arguments: hashtag);
    }
  }

  void _showPostOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
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
                      icon: Icons.edit_outlined,
                      title: 'Edit Post',
                      onTap: () {
                        Navigator.of(modalContext).pop();
                        _editPost();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildOptionTile(
                      icon: Icons.delete_outline,
                      title: 'Delete Post',
                      isDestructive: true,
                      onTap: () {
                        Navigator.of(modalContext).pop();
                        _showDeleteConfirmation();
                      },
                    ),
                  ] else ...[
                    // Options for other user's post
                    _buildOptionTile(
                      icon: Icons.block_outlined,
                      title: 'Block User',
                      onTap: () {
                        Navigator.of(modalContext).pop();
                        _blockUser();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildOptionTile(
                      icon: Icons.report_outlined,
                      title: 'Report Post',
                      onTap: () {
                        Navigator.of(modalContext).pop();
                        _reportPost();
                      },
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
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

  void _editPost() {
    final TextEditingController editController = TextEditingController(text: _currentPost.content);
    int wordCount = _currentPost.content.trim().split(RegExp(r'\s+')).length;
    const int maxWords = 50;
    
    // Capture the BLoC reference before creating the modal
    final communityBloc = context.read<CommunityBloc>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
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
                                 editController.text.trim() != _currentPost.content;

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
                      // Handle indicator
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Title
                      Text(
                        'Edit Post',
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Word count indicator
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
                      
                      // Text input area
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
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
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
                        child: BlocConsumer<CommunityBloc, CommunityState>(
                          bloc: communityBloc,
                          listener: (blocContext, state) {
                            if (state is PostUpdateSuccess) {
                              // Update the local post state with edited content
                              if (mounted) {
                                setState(() {
                                  _currentPost = PostEntity(
                                    id: _currentPost.id,
                                    userId: _currentPost.userId,
                                    tenantId: _currentPost.tenantId,
                                    content: editController.text.trim(),
                                    parentPostId: _currentPost.parentPostId,
                                    likeCount: _currentPost.likeCount,
                                    commentCount: _currentPost.commentCount,
                                    isEdited: true, // Mark as edited
                                    isDeleted: _currentPost.isDeleted,
                                    createdAt: _currentPost.createdAt,
                                    updatedAt: DateTime.now(), // Update timestamp
                                    username: _currentPost.username,
                                    userAvatar: _currentPost.userAvatar,
                                    isLikedByUser: _currentPost.isLikedByUser,
                                  );
                                });
                              }
                              Navigator.of(modalContext).pop();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Post updated successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else if (state is PostUpdateError) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to update post: ${state.message}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          builder: (blocContext, state) {
                            final isLoading = state is PostUpdateLoading;
                            final canUpdate = getCanUpdate();
                            return CustomButton(
                              text: 'Update Post',
                              onPressed: canUpdate && !isLoading ? () {
                                communityBloc.add(
                                  UpdatePost(
                                    token: widget.token,
                                    postId: _currentPost.id,
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
        );
      },
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            BlocConsumer<CommunityBloc, CommunityState>(
              bloc: context.read<CommunityBloc>(),
              listener: (blocContext, state) {
                if (state is PostDeleteSuccess) {
                  Navigator.of(dialogContext).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Post deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else if (state is PostDeleteError) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete post: ${state.message}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              builder: (blocContext, state) {
                final isLoading = state is PostDeleteLoading;
                return ElevatedButton(
                  onPressed: isLoading ? null : () {
                    context.read<CommunityBloc>().add(
                      DeletePost(
                        token: widget.token,
                        postId: _currentPost.id,
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
        );
      },
    );
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Block User'),
          content: Text('Are you sure you want to block ${_currentPost.username}? You will no longer see their posts and they won\'t be able to interact with your content.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            BlocConsumer<CommunityBloc, CommunityState>(
              bloc: context.read<CommunityBloc>(),
              listener: (blocContext, state) {
                if (state is BlockUserSuccess && state.userId == _currentPost.userId) {
                  Navigator.of(dialogContext).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${_currentPost.username} has been blocked'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } else if (state is BlockUserError && state.userId == _currentPost.userId) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to block user: ${state.message}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              builder: (blocContext, state) {
                final isLoading = state is BlockUserLoading && state.userId == _currentPost.userId;
                return ElevatedButton(
                  onPressed: isLoading ? null : () {
                    final blockData = BlockUserEntity(
                      userId: _currentPost.userId,
                      reason: 'Inappropriate behavior',
                    );
                    context.read<CommunityBloc>().add(
                      BlockUser(
                        token: widget.token,
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
            ),
          ],
        );
      },
    );
  }

  void _reportPost() {
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

  Widget _buildReplyIndicator(BuildContext context) {
    // In a real implementation, the API should include parent post author information
    // For now, we'll create a structure that can be easily updated when API is enhanced
    
    // Placeholder username - this should come from API response
    // You can modify your API to include 'parent_author_name' and 'parent_author_id' fields
    final parentUsername = 'thread'; // This would be dynamic from API
    final parentUserId = 'parent_user_id'; // This would be dynamic from API
    
    return GestureDetector(
      onTap: () => _navigateToUserProfile(parentUserId),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
            children: [
              const TextSpan(text: 'Replying to '),
              TextSpan(
                text: '@$parentUsername',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToUserProfile(String userId) {
    Navigator.pushNamed(
      context,
      AppRoutes.communityUserProfile,
      arguments: {'userId': userId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserImageIcon(
          author: AuthorEntity(
            id: _currentPost.userId,
            fullName: _currentPost.username.isNotEmpty ? _currentPost.username : 'User',
            avatarUrl: _currentPost.userAvatar ?? '',
          ),
        ),

        const SizedBox(width: 5),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 9),
                child: SizedBox(
                height: 38,
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    UserNameWithNavigation(post: _currentPost),

                  // const Spacer(),

                  // Show edited indicator if post was edited
                  if (_currentPost.isEdited) ...[
                    Text(
                      'edited',
                      style: Theme.of(context).textTheme.bodySmall!
                          .secondary(context)
                          .copyWith(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  Text(
                    _timeAgo(_currentPost.updatedAt ?? _currentPost.createdAt),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodyMedium!
                        .secondary(context)
                        .copyWith(fontWeight: FontWeight.w300),
                  ),

                  const SizedBox(width: 10),

                  IconButton(
                    onPressed: widget.disableActions ? null : _showPostOptionsModal,
                    icon: Icon(Icons.more_horiz, size: 22),
                    padding: EdgeInsets.zero,
                    // constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  )


                ],
              ),
              ),
              ),
              
              
              // Show "Replying to @username" if this is a reply
              if (_currentPost.parentPostId != null && _currentPost.parentPostId!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
                  child: _buildReplyIndicator(context),
                ),
              ],
              
              // const SizedBox(height: 7),
              Padding(padding: EdgeInsets.only(left: 9),
              child: InkWell(
                onTap: widget.disableActions ? null : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PostDetailPageIntegration(
                        token: widget.token,
                        postId: _currentPost.id,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final baseStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                      );
                      
                      final textSpan = TextSpan(
                        text: _currentPost.content,
                        style: baseStyle,
                      );
                      
                      final textPainter = TextPainter(
                        text: textSpan,
                        textDirection: TextDirection.ltr,
                        maxLines: 5,
                      );
                      textPainter.layout(maxWidth: constraints.maxWidth);
                      
                      final isTextOverflowing = textPainter.didExceedMaxLines;
                      
                      if (isTextOverflowing) {
                        // Calculate how much text can fit and add "see more" inline
                        final seeMoreSpan = TextSpan(
                          text: '..see more',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = widget.disableActions ? null : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PostDetailPageIntegration(
                                    token: widget.token,
                                    postId: _currentPost.id,
                                    userId: widget.userId,
                                  ),
                                ),
                              );
                            },
                        );
                        
                        // Calculate truncated text to fit with "see more"
                        String truncatedText = _currentPost.content;
                        final words = _currentPost.content.split(' ');
                        
                        // Test with progressively shorter text until it fits
                        for (int i = words.length - 1; i > 0; i--) {
                          final truncatedContent = words.take(i).join(' ');
                          final clickableSpans = _buildClickableTextSpans(truncatedContent, baseStyle);
                          final testSpan = TextSpan(
                            children: [...clickableSpans, seeMoreSpan],
                          );
                          final testPainter = TextPainter(
                            text: testSpan,
                            textDirection: TextDirection.ltr,
                            maxLines: 5,
                          );
                          testPainter.layout(maxWidth: constraints.maxWidth);
                          
                          if (!testPainter.didExceedMaxLines) {
                            truncatedText = truncatedContent;
                            break;
                          }
                        }
                        
                        final finalClickableSpans = _buildClickableTextSpans(truncatedText, baseStyle);
                        
                        return RichText(
                          text: TextSpan(
                            children: [...finalClickableSpans, seeMoreSpan],
                          ),
                        );
                      } else {
                        // Text doesn't overflow, show with clickable elements
                        final clickableSpans = _buildClickableTextSpans(_currentPost.content, baseStyle);
                        
                        return RichText(
                          text: TextSpan(children: clickableSpans),
                        );
                      }
                    },
                  ),
                ),
              ),
              ),
              

              const SizedBox(height: 5),
              LikeCommentShareRow(
                postId: _currentPost.id,
                initialLikeStatus: isLiked,
                initialLikeCount: _currentLikeCount,
                size: 18,
                activeColor: Colors.red,
                showCount: false,
                token: widget.token,
                userId: widget.userId,
                onLikeStatusChanged: _onLikeStatusChanged,
                currentLikeStatus: _currentLikeStatus,
                currentLikeCount: _currentLikeCount,
              ),
              // const SizedBox(height: 6),
              _currentLikeCount > 0
              ? Padding(padding: EdgeInsets.only(left: 7),
              child: Text(
                "$_currentLikeCount ${_currentLikeCount == 1 ? 'Like' : 'Likes'}",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.secondary(context),
              ))
              : const SizedBox.shrink(),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}