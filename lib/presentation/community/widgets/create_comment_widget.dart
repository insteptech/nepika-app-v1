import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/constants/app_constants.dart';
import '../../../domain/community/entities/community_entities.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';
import '../bloc/community_composite_state.dart';

class CreateCommentWidget extends StatefulWidget {
  final String postId;
  final String parentPostContent;
  final VoidCallback? onCommentCreated;

  const CreateCommentWidget({
    super.key,
    required this.postId,
    required this.parentPostContent,
    this.onCommentCreated,
  });

  @override
  State<CreateCommentWidget> createState() => _CreateCommentWidgetState();
}

class _CreateCommentWidgetState extends State<CreateCommentWidget> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _token;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.accessTokenKey);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitComment() {
    if (_token == null || _commentController.text.trim().isEmpty) return;

    final content = _commentController.text.trim();
    
    setState(() {
      _isLoading = true;
    });

    final createPostData = CreatePostEntity(
      content: content,
      parentPostId: widget.postId,
    );

    context.read<CommunityBloc>().add(
      CreatePost(
        token: _token!,
        postData: createPostData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CommunityBloc, CommunityState>(
      listener: (context, state) {
        if (state is CommunityCompositeState) {
          if (state.createPostState is CreatePostSuccess) {
            _commentController.clear();
            _focusNode.unfocus();
            setState(() {
              _isLoading = false;
            });
            widget.onCommentCreated?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Comment posted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state.createPostState is CreatePostError) {
            setState(() {
              _isLoading = false;
            });
            final error = state.createPostState as CreatePostError;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to post comment: ${error.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        // Handle legacy states for backward compatibility
        else if (state.runtimeType.toString() == 'CreatePostSuccess') {
          _commentController.clear();
          _focusNode.unfocus();
          setState(() {
            _isLoading = false;
          });
          widget.onCommentCreated?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment posted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state.runtimeType.toString() == 'CreatePostError') {
          setState(() {
            _isLoading = false;
          });
          // Handle error - would need reflection or dynamic access for message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to post comment'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Parent post preview
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.reply,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to: ${widget.parentPostContent.length > 100 
                        ? '${widget.parentPostContent.substring(0, 100)}...' 
                        : widget.parentPostContent}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Comment input
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      maxHeight: 120,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _focusNode.hasFocus
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        width: _focusNode.hasFocus ? 2 : 1,
                      ),
                    ),
                    child: TextField(
                      controller: _commentController,
                      focusNode: _focusNode,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Write a thoughtful comment...',
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                      onChanged: (text) {
                        setState(() {}); // Rebuild to update send button state
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: _isLoading || _commentController.text.trim().isEmpty
                        ? null
                        : _submitComment,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _commentController.text.trim().isEmpty
                            ? Theme.of(context).colorScheme.surfaceVariant
                            : Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              size: 20,
                              color: _commentController.text.trim().isEmpty
                                  ? Theme.of(context).colorScheme.onSurfaceVariant
                                  : Theme.of(context).colorScheme.onPrimary,
                            ),
                    ),
                  ),
                ),
              ],
            ),

            // Character count and hints
            if (_commentController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${_commentController.text.length}/500',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _commentController.text.length > 450
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (_commentController.text.length > 500)
                    Text(
                      'Comment too long',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ],

            // Quick emoji reactions (optional)
            if (_focusNode.hasFocus) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickReaction('👍', ' Great point!'),
                    _buildQuickReaction('❤️', ' Love this!'),
                    _buildQuickReaction('🤔', ' Interesting...'),
                    _buildQuickReaction('💯', ' Absolutely!'),
                    _buildQuickReaction('🔥', ' This is fire!'),
                    _buildQuickReaction('👏', ' Well said!'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReaction(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          final currentText = _commentController.text;
          final newText = currentText.isEmpty ? '$emoji$text' : '$currentText $emoji$text';
          _commentController.text = newText;
          _commentController.selection = TextSelection.fromPosition(
            TextPosition(offset: newText.length),
          );
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                text,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}