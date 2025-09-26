import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/config/constants/routes.dart';
import '../../../core/config/constants/theme.dart';
import '../../../core/config/constants/app_constants.dart';
import '../../../core/widgets/back_button.dart';
import '../../../domain/community/entities/community_entities.dart';
import '../bloc/blocs/posts_bloc.dart';
import '../bloc/events/posts_event.dart';
import '../bloc/states/posts_state.dart';
import '../widgets/like_comment_share_row.dart';
import '../widgets/like_state_listener.dart';
import '../widgets/user_post_widget.dart';
import '../widgets/user_icon.dart';
import '../widgets/user_name.dart';
import '../utils/community_state_recovery_mixin.dart';

class PostDetailScreen extends StatefulWidget {
  final String? token;
  final String postId;
  final String? userId;
  final bool? currentLikeStatus;
  final int? currentLikeCount;

  const PostDetailScreen({
    super.key,
    this.token,
    required this.postId,
    this.userId,
    this.currentLikeStatus,
    this.currentLikeCount,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> with CommunityStateRecoveryMixin {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _token;
  String? _userId;
  
  // Store the loaded post to prevent blank screen during comment operations
  PostDetailEntity? _loadedPost;
  
  // Local state for comments to prevent conflicts with post loading
  List<PostEntity> _localComments = [];
  bool _commentsLoaded = false;
  bool _isLoadingComments = false;
  bool _hasMoreComments = false;
  int _currentCommentsPage = 1;
  String? _commentsError;
  
  // Current user data for profile picture
  AuthorEntity? _currentUser;
  
  // Removed AutomaticKeepAliveClientMixin to prevent state conflicts

  @override
  void initState() {
    super.initState();
    
    // Add scroll listener for infinite loading
    _scrollController.addListener(_onScroll);
    
    // Initialize data and then load content
    _initializeAndLoadContent();
  }

  @override
  void didUpdateWidget(PostDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If postId changed, reset the loaded post and reload
    if (oldWidget.postId != widget.postId) {
      debugPrint('PostDetailScreen: PostId changed from ${oldWidget.postId} to ${widget.postId} - resetting state');
      
      // Reset the loaded post to prevent showing wrong content
      _loadedPost = null;
      
      // Reset comments state as well
      _localComments.clear();
      _commentsLoaded = false;
      _isLoadingComments = false;
      _hasMoreComments = false;
      _currentCommentsPage = 1;
      _commentsError = null;
      
      // Reinitialize and load content for new postId
      _initializeAndLoadContent();
    }
  }

  Future<void> _initializeAndLoadContent() async {
    try {
      debugPrint('PostDetailScreen: Starting initialization for post ${widget.postId}');
      
      // Step 1: Initialize token and user data
      final prefs = await SharedPreferences.getInstance();
      _token = widget.token ?? prefs.getString(AppConstants.accessTokenKey);
      
      final userDataString = prefs.getString(AppConstants.userDataKey);
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        _userId = widget.userId ?? userData['id'];
      } else {
        _userId = widget.userId;
      }

      if (_token == null) {
        debugPrint('PostDetailScreen: No access token found');
        if (mounted) {
          setState(() {});
        }
        return;
      }

      debugPrint('PostDetailScreen: Token initialized: ${_token!.length} characters');
      debugPrint('PostDetailScreen: User ID: $_userId');

      if (mounted) {
        setState(() {});
      }

      // Step 2: Load current user data for profile picture
      await _loadCurrentUser();

      // Step 3: Load post and comments with guaranteed token availability
      await _loadPostWithToken();
      await _loadCommentsWithToken();
      
      // Step 4: Final safety check - ensure requests were made
      _scheduleRequestMonitoring();

    } catch (e) {
      debugPrint('PostDetailScreen: Error in initialization: $e');
      if (mounted) {
        setState(() {});
      }
    }
  }
  
  void _scheduleRequestMonitoring() {
    // Monitor after 2 seconds to ensure requests were made
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _loadedPost == null && _token != null) {
        debugPrint('PostDetailScreen: SAFETY CHECK - No post loaded after 2 seconds, forcing request');
        try {
          context.read<PostsBloc>().add(
            FetchSinglePost(token: _token!, postId: widget.postId),
          );
        } catch (e) {
          debugPrint('PostDetailScreen: Safety check failed: $e');
        }
      }
      
      if (mounted && _localComments.isEmpty && !_commentsLoaded && _token != null) {
        debugPrint('PostDetailScreen: SAFETY CHECK - No comments loaded after 2 seconds, forcing request');
        try {
          context.read<PostsBloc>().add(
            FetchPostComments(token: _token!, postId: widget.postId),
          );
        } catch (e) {
          debugPrint('PostDetailScreen: Comments safety check failed: $e');
        }
      }
    });
  }
  
  Future<void> _loadCurrentUser() async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      final userDataString = sharedPrefs.getString(AppConstants.userDataKey);
      
      if (userDataString != null && mounted) {
        final userData = jsonDecode(userDataString);
        setState(() {
          _currentUser = AuthorEntity(
            id: userData['id'] ?? (_userId ?? widget.userId ?? ''),
            fullName: userData['username'] ?? 'You',
            avatarUrl: userData['profileImageUrl'] ?? '',
          );
        });
      } else if (mounted) {
        // Fallback to basic current user
        setState(() {
          _currentUser = AuthorEntity(
            id: _userId ?? widget.userId ?? '',
            fullName: 'You',
            avatarUrl: '',
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading current user data: $e');
      if (mounted) {
        setState(() {
          _currentUser = AuthorEntity(
            id: _userId ?? widget.userId ?? '',
            fullName: 'You',
            avatarUrl: '',
          );
        });
      }
    }
  }

  Future<void> _loadPostWithToken() async {
    debugPrint('PostDetailScreen: Loading post with token guaranteed');
    
    try {
      // Try to recover existing state first
      final stateRecovered = recoverPostDetailState(widget.postId, (post) {
        debugPrint('PostDetailScreen: State recovered for post ${post.id}');
        setState(() {
          _loadedPost = post;
        });
      });
      
      // Always try to fetch from backend to ensure fresh data
      debugPrint('PostDetailScreen: Fetching post from backend (token: ${_token?.substring(0, 10)}...)');
      
      // Primary attempt with proper timing
      dispatchAfterListeners(() {
        try {
          debugPrint('PostDetailScreen: Dispatching FetchSinglePost event with cache buster');
          context.read<PostsBloc>().add(
            FetchSinglePost(
              token: _token!, 
              postId: widget.postId,
              cacheBuster: DateTime.now().millisecondsSinceEpoch,
            ),
          );
        } catch (e) {
          debugPrint('PostDetailScreen: Error dispatching FetchSinglePost: $e');
          _retryPostLoad();
        }
      });
      
      // Fallback attempt after a short delay
      if (!stateRecovered) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _loadedPost == null) {
            debugPrint('PostDetailScreen: Fallback attempt to load post');
            _retryPostLoad();
          }
        });
      }
      
    } catch (e) {
      debugPrint('PostDetailScreen: Error in _loadPostWithToken: $e');
      _retryPostLoad();
    }
  }
  
  void _retryPostLoad() {
    try {
      if (mounted && _token != null) {
        debugPrint('PostDetailScreen: Retrying post load');
        context.read<PostsBloc>().add(
          FetchSinglePost(
            token: _token!, 
            postId: widget.postId,
            cacheBuster: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }
    } catch (e) {
      debugPrint('PostDetailScreen: Retry failed: $e');
    }
  }
  
  Future<void> _loadCommentsWithToken() async {
    debugPrint('PostDetailScreen: Loading comments with token guaranteed');
    
    if (mounted) {
      setState(() {
        _isLoadingComments = true;
        _commentsError = null;
      });
    }
    
    try {
      // Primary attempt with proper timing
      dispatchAfterListeners(() {
        try {
          debugPrint('PostDetailScreen: Dispatching FetchPostComments event');
          context.read<PostsBloc>().add(
            FetchPostComments(
              token: _token!,
              postId: widget.postId,
            ),
          );
        } catch (e) {
          debugPrint('PostDetailScreen: Error dispatching FetchPostComments: $e');
          _retryCommentsLoad();
        }
      });
      
      // Fallback attempt after a short delay
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted && _localComments.isEmpty && !_commentsLoaded) {
          debugPrint('PostDetailScreen: Fallback attempt to load comments');
          _retryCommentsLoad();
        }
      });
      
    } catch (e) {
      debugPrint('PostDetailScreen: Error in _loadCommentsWithToken: $e');
      _retryCommentsLoad();
    }
  }
  
  void _retryCommentsLoad() {
    try {
      if (mounted && _token != null) {
        debugPrint('PostDetailScreen: Retrying comments load');
        context.read<PostsBloc>().add(
          FetchPostComments(
            token: _token!,
            postId: widget.postId,
          ),
        );
      }
    } catch (e) {
      debugPrint('PostDetailScreen: Comments retry failed: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('PostDetailScreen: Disposing all cached data for post ${widget.postId}');
    
    // Clear all cached post data to prevent conflicts between different post details
    _loadedPost = null;
    
    // Clear comments data
    _localComments.clear();
    _commentsLoaded = false;
    _isLoadingComments = false;
    _hasMoreComments = false;
    _currentCommentsPage = 1;
    _commentsError = null;
    
    // Clear user data
    _currentUser = null;
    _token = null;
    _userId = null;
    
    // Dispose controllers
    _commentController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      // User has scrolled to 90% of the content, load more comments
      if (_hasMoreComments && !_isLoadingComments && _commentsLoaded) {
        _loadMoreComments();
      }
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
  
  Future<void> _loadMoreComments() async {
    if (mounted) {
      setState(() {
        _isLoadingComments = true;
      });
    }
    
    if (_token != null) {
      context.read<PostsBloc>().add(
        LoadMoreComments(
          token: _token!,
          postId: widget.postId,
          page: _currentCommentsPage + 1,
        ),
      );
    }
  }

  void _navigateToSearch() {
    Navigator.pushNamed(
      context,
      AppRoutes.communitySearch,
      arguments: _token,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onTertiary,
      body: BlocListener<PostsBloc, PostsState>(
        listener: (context, state) {
          _handleBlocStateChanges(state);
        },
        child: _buildBody(),
      ),
    );
  }
  
  void _handleBlocStateChanges(PostsState state) {
    if (state is PostOperationSuccess && state.operationType == 'create') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh comments after posting
      _refreshComments();
    } else if (state is PostOperationError && state.operationType == 'create') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post comment: ${state.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (state is PostDetailLoaded) {
      if (mounted) {
        setState(() {
          _loadedPost = state.post;
        });
      }
      debugPrint('Post Detail Loaded: ${state.post.id}');
    } else if (state is CommentsState && state.parentPostId == widget.postId) {
      if (mounted) {
        setState(() {
          _localComments = List.from(state.comments);
          _commentsLoaded = !state.isLoading || state.comments.isNotEmpty;
          _isLoadingComments = state.isLoading || state.isLoadingMore;
          _hasMoreComments = state.hasMoreComments;
          _currentCommentsPage = state.currentPage;
          _commentsError = state.error;
        });
        
        if (state.error != null && !_commentsLoaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load comments: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _refreshComments() async {
    if (mounted) {
      setState(() {
        _localComments.clear();
        _commentsLoaded = false;
        _currentCommentsPage = 1;
        _commentsError = null;
      });
    }
    _loadCommentsWithToken();
  }
  
  Widget _buildBody() {
    // Show main loading only if we don't have a cached post
    if (_loadedPost == null) {
      return BlocBuilder<PostsBloc, PostsState>(
        buildWhen: (previous, current) {
          // Only rebuild for post detail states
          return current is PostDetailLoading || 
                 current is PostDetailLoaded || 
                 current is PostDetailError;
        },
        builder: (context, state) {
          if (state is PostDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is PostDetailError) {
            return _buildErrorState(state.message, _loadPostWithToken);
          }
          
          // If we still don't have a post and not loading, show loading
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
    
    // Always show content if we have a cached post
    return _buildPostDetailContent(context, _loadedPost!);
  }
  
  Widget _buildErrorState(String message, VoidCallback onRetry) {
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
            'Error loading content',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostDetailContent(BuildContext context, PostDetailEntity post) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Sticky Header
                SliverPersistentHeader(
                  pinned: true,
                  floating: false,
                  delegate: _PostDetailStickyHeaderDelegate(
                    onSearchTap: _navigateToSearch,
                  ),
                ),

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

                // Comments List from Local State
                _buildCommentsSection(),

                // Bottom spacing
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),

          // Comment Input
          _buildCommentInput(context, post),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    // Use local state instead of BLoC state to avoid conflicts
    if (!_commentsLoaded && _commentsError == null && _isLoadingComments) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_commentsError != null && !_commentsLoaded) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load comments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _commentsError!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadCommentsWithToken,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_localComments.isEmpty && _commentsLoaded) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: Text('No comments yet. Be the first to comment!'),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Show loading indicator for the last item if loading more comments
          if (index == _localComments.length && _isLoadingComments && _commentsLoaded) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (index >= _localComments.length) {
            return const SizedBox.shrink();
          }

          final comment = _localComments[index];
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 5,
            ),
            child: UserPostWidget(
              disableActions: false,
              post: comment,
              token: _token!,
              userId: _userId!,
            ),
          );
        },
        childCount: _localComments.length + (_isLoadingComments && _commentsLoaded ? 1 : 0),
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

          // Post Content with clickable links and hashtags
          RichText(
            text: TextSpan(
              children: _buildClickableTextSpans(
                post.content, 
                Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),

          const SizedBox(height: 15),

          LikeStateListener(
            postId: post.postId,
            builder: (context, likeState) {
              final currentLikeStatus = likeState?.isLiked ?? _isPostLikedByUser(post);
              final currentLikeCount = likeState?.likeCount ?? (widget.currentLikeCount ?? post.likeCount);
              
              return LikeCommentShareRow(
                postId: post.postId,
                initialLikeStatus: currentLikeStatus,
                initialLikeCount: currentLikeCount,
                size: 22,
                activeColor: Colors.red,
                showCount: false,
                token: _token!,
                userId: _userId!,
                showCommentButton: false,
              );
            },
          ),

          const SizedBox(height: 15),

          LikeStateListener(
            postId: post.postId,
            builder: (context, likeState) {
              final currentLikeCount = likeState?.likeCount ?? (widget.currentLikeCount ?? post.likeCount);
              
              return RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineMedium!.secondary(context),
                  children: [
                    TextSpan(text: '${_loadedPost?.commentCount ?? 0} replies'),
                    if (currentLikeCount > 0) ...[
                      const TextSpan(text: ' • '),
                      TextSpan(text: '${_formatLikeCount(currentLikeCount)} likes'),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  Widget _buildCommentInput(BuildContext context, PostDetailEntity post) {
    return Container(
      padding: const EdgeInsets.only(left: 18, right: 18, top: 10,bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onTertiary,
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 50,
                  maxHeight: 120, // About 4 lines (30px per line)
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onTertiary,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).textTheme.headlineMedium!.secondary(context).color!,
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.only(right: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Current user's profile picture
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: _currentUser != null 
                          ? UserImageIcon(author: _currentUser!, padding: 0)
                          : Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 24,
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                              ),
                            ),
                    ),
                    // Expandable text field
                    Expanded(
                      child: TextField(
                        key: post.postId.isNotEmpty
                            ? Key('comment_input_${post.postId}')
                            : null,
                        controller: _commentController,
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: null, // Allow unlimited lines
                        minLines: 1, // Start with single line
                        textInputAction: TextInputAction.newline,
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _submitComment(value.trim());
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Comment',
                          hintStyle: Theme.of(
                            context,
                          ).textTheme.bodyLarge!.secondary(context),
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, 
                            vertical: 16,
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    // Send button
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _commentController,
                      builder: (context, value, child) {
                        return value.text.trim().isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 8, right: 8),
                                child: IconButton(
                                  onPressed: () {
                                    if (_commentController.text.trim().isNotEmpty) {
                                      _submitComment(_commentController.text.trim());
                                    }
                                  },
                                  icon: Icon(
                                    Icons.send,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                ),
                              )
                            : const SizedBox(width: 8);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitComment(String content) {
    if (content.trim().isEmpty) return;

    final createPostData = CreatePostEntity(
      content: content.trim(),
      parentPostId: widget.postId,
    );

    // Add the comment via the BLoC
    context.read<PostsBloc>().add(
      CreatePost(token: _token!, postData: createPostData),
    );

    // Clear the input field
    _commentController.clear();

    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Adding comment...'),
        duration: Duration(seconds: 1),
      ),
    );
  }


  String _formatLikeCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  bool _isPostLikedByUser(PostDetailEntity post) {
    // Use the isLikedByUser field from the server response (most reliable)
    final serverLikeStatus = post.isLikedByUser;
    
    // If we have a current like status passed from the parent (home screen), use that instead
    // This ensures consistency when navigating from a screen where the user just liked/unliked
    final finalLikeStatus = widget.currentLikeStatus ?? serverLikeStatus;
    
    debugPrint('PostDetail: Checking like status - postId: ${post.postId}, userId: $_userId, serverLiked: $serverLikeStatus, passedLikeStatus: ${widget.currentLikeStatus}, finalStatus: $finalLikeStatus');
    
    return finalLikeStatus;
  }
}

// Sticky Header Delegate for Post Detail Page
class _PostDetailStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onSearchTap;

  _PostDetailStickyHeaderDelegate({required this.onSearchTap});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Calculate the shrink progress (0.0 to 1.0)
    final progress = shrinkOffset / maxExtent;
    final clampedProgress = progress.clamp(0.0, 1.0);
    
    // Interpolate heights for logo and search icon
    final logoHeight = 30.0 - (8.0 * clampedProgress); // 30 -> 22
    final searchHeight = 25.0 - (7.0 * clampedProgress); // 25 -> 18
    final containerHeight = maxExtent - (shrinkOffset.clamp(0.0, maxExtent - minExtent));

    return Container(
      height: containerHeight,
      color: Theme.of(context).colorScheme.onTertiary,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Nepika Logo
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            child: Image.asset(
              'assets/images/nepika_logo_image.png',
              height: logoHeight,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          // Back Button
          Positioned(
            left: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.all(0),
              child:CustomBackButton()
            ),
          ),

          // Search Icon
          Positioned(
            right: 0,
            child: GestureDetector(
              onTap: onSearchTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/icons/search_icon.png',
                  height: searchHeight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 70.0; // Full height
  
  @override
  double get minExtent => 50.0; // Minimum height when sticky

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}