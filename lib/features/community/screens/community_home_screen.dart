import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/config/constants/app_constants.dart';
import '../../../../domain/community/entities/community_entities.dart';
import '../bloc/blocs/posts_bloc.dart';
import '../bloc/events/posts_event.dart';
import '../bloc/states/posts_state.dart';
import '../components/posts_loading.dart' as components;
import '../components/posts_error.dart' as components;
import '../widgets/user_post_widget.dart';
import '../widgets/create_post_widget.dart';
import '../utils/community_navigation.dart';
import 'community_header.dart';

/// Main community home screen following clean architecture principles
/// Focused only on displaying the community feed
class CommunityHomeScreen extends StatefulWidget {
  const CommunityHomeScreen({
    super.key,
  });

  @override
  State<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _token;
  String? _userId;
  bool _isLoading = true;
  DateTime? _lastLoadTime; // Prevent rapid loading requests

  @override
  void initState() {
    super.initState();
    _loadUserDataAndPosts();
    _setupPagination();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDataAndPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.accessTokenKey);
      final userData = prefs.getString(AppConstants.userDataKey);
      
      if (token != null && userData != null && mounted) {
        final userDataJson = jsonDecode(userData);
        setState(() {
          _token = token;
          _userId = userDataJson['id']?.toString();
          _isLoading = false;
        });
        
        if (_token != null) {
          _loadInitialPosts();
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadInitialPosts() {
    if (_token != null) {
      context.read<PostsBloc>().add(
        FetchCommunityPosts(token: _token!),
      );
    }
  }

  void _setupPagination() {
    _scrollController.addListener(() {
      // Only proceed if we have a valid scroll position
      if (!_scrollController.hasClients) return;
      
      final position = _scrollController.position;
      final state = context.read<PostsBloc>().state;
      
      // Check if we're near the last post (more responsive than waiting for absolute bottom)
      // Trigger when user scrolls to 80% of available content or within 100px of bottom
      final scrollThreshold = position.maxScrollExtent * 0.8;
      final isNearBottom = position.pixels >= scrollThreshold || 
                          position.pixels >= (position.maxScrollExtent - 100);
      
      // Only trigger if:
      // 1. We're near the bottom (80% scrolled or within 100px of bottom)
      // 2. We have more posts to load (based on API response)
      // 3. We're not already loading more
      // 4. We have a valid token
      // 5. We have at least one post (avoid empty list issues)
      // 6. At least 1 second has passed since last load (prevent rapid requests)
      final now = DateTime.now();
      final canLoad = _lastLoadTime == null || 
                     now.difference(_lastLoadTime!).inMilliseconds > 1000;
      
      if (isNearBottom && 
          state is PostsLoaded && 
          state.posts.isNotEmpty &&
          state.hasMorePosts && 
          !state.isLoadingMore &&
          _token != null &&
          canLoad) {
        
        debugPrint('CommunityHome: Auto-loading more posts');
        debugPrint('  - Current posts: ${state.posts.length}');
        debugPrint('  - Has more posts: ${state.hasMorePosts}');
        debugPrint('  - Current page: ${state.currentPage}');
        debugPrint('  - Loading page: ${state.currentPage + 1}');
        
        _lastLoadTime = now; // Update last load time
        context.read<PostsBloc>().add(
          LoadMoreCommunityPosts(
            token: _token!,
            page: state.currentPage + 1,
          ),
        );
      } else {
        // Debug why loading didn't trigger
        if (state is PostsLoaded && state.hasMorePosts && !isNearBottom) {
          debugPrint('CommunityHome: Not loading - not near bottom yet');
          debugPrint('  - Scroll progress: ${(position.pixels / position.maxScrollExtent * 100).toStringAsFixed(1)}%');
        }
      }
    });
  }

  Future<void> _refreshPosts() async {
    if (_token != null) {
      // Use the new refresh with cache clear for pull-to-refresh
      context.read<PostsBloc>().add(
        RefreshWithCacheClear(token: _token!),
      );
      
      // Wait for the refresh to complete
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  void _navigateToSearch() async {
    await CommunityNavigation.navigateToSearch(context);
    // Refresh posts when returning from search
    if (mounted) {
      _refreshPosts();
    }
  }

  void _navigateToCreatePost() async {
    await CommunityNavigation.navigateToCreatePost(
      context,
      token: _token,
      userId: _userId,
    );
    // Refresh posts when returning
    if (mounted) {
      _refreshPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_token == null || _userId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Authentication required',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onTertiary,
      body: SafeArea(
        child: BlocBuilder<PostsBloc, PostsState>(
          buildWhen: (previous, current) {
            return current is PostsLoading ||
                   current is PostsLoaded ||
                   current is PostsError;
          },
          builder: (context, state) {
            if (state is PostsLoading) {
              return const components.PostsLoading(message: 'Loading community posts...');
            }
            
            if (state is PostsError) {
              return components.PostsError(
                message: state.message,
                onRetry: _loadInitialPosts,
              );
            }
            
            if (state is PostsLoaded) {
              final posts = state.posts;
              final hasMorePosts = state.hasMorePosts;
              final isLoadingMore = state.isLoadingMore;

              return RefreshIndicator(
                onRefresh: _refreshPosts,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Add small padding at top to ensure pull-to-refresh works
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 1),
                    ),
                    
                    // Sticky Header
                    SliverPersistentHeader(
                      pinned: true,
                      floating: false,
                      delegate: CommunityHeader(
                        onSearchTap: _navigateToSearch,
                      ),
                    ),

                    // Create Post Section
                    SliverPersistentHeader(
                      pinned: true,
                      floating: false,
                      delegate: _CreatePostSection(
                        onCreatePostTap: _navigateToCreatePost,
                        token: _token!,
                        userId: _userId!,
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 20),
                    ),

                    // Posts List
                    _buildPostsList(posts, hasMorePosts, isLoadingMore),
                  ],
                ),
              );
            }

            return const components.PostsLoading();
          },
        ),
      ),
    );
  }

  Widget _buildPostsList(List<PostEntity> posts, bool hasMorePosts, bool isLoadingMore) {
    if (posts.isEmpty) {
      return const SliverToBoxAdapter(
        child: components.PostsEmpty(
          message: 'No posts in your community yet',
          actionText: 'Create First Post',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index < posts.length) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: UserPostWidget(
                  post: posts[index],
                  token: _token!,
                  userId: _userId!,
                ),
              );
            } else if (isLoadingMore && hasMorePosts) {
              // Only show loader when actively loading more posts
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return null;
          },
          childCount: posts.length + (isLoadingMore && hasMorePosts ? 1 : 0),
        ),
      ),
    );
  }
}

// Create Post Section Delegate
class _CreatePostSection extends SliverPersistentHeaderDelegate {
  final VoidCallback onCreatePostTap;
  final String token;
  final String userId;

  _CreatePostSection({
    required this.onCreatePostTap,
    required this.token,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = shrinkOffset / maxExtent;
    final clampedProgress = progress.clamp(0.0, 1.0);
    
    final containerHeight = maxExtent - (maxExtent * 0.3 * clampedProgress);

    return Container(
      height: containerHeight,
      color: Theme.of(context).colorScheme.onTertiary,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context)
                  .textTheme
                  .headlineMedium!
                  .color!
                  .withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: Center(
          child: CreatePostWidget(
            onCreatePostTap: onCreatePostTap,
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 70.0;
  
  @override
  double get minExtent => 49.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}