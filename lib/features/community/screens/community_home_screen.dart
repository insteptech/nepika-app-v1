import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/config/constants/app_constants.dart';
import '../../../../domain/community/entities/community_entities.dart';
import '../bloc/blocs/posts_bloc.dart';
import '../bloc/events/posts_event.dart';
import '../bloc/states/posts_state.dart';
import '../bloc/blocs/profile_bloc.dart';
import '../bloc/events/profile_event.dart';
import '../bloc/states/profile_state.dart';
import '../components/posts_error.dart' as components;
import '../widgets/user_post_widget.dart';
import '../widgets/create_post_widget.dart';
import '../widgets/post_skeleton_loader.dart';
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
  CommunityProfileEntity? _currentUserProfile;

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
          _loadUserProfile();
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

  void _loadUserProfile() {
    if (_token != null && _userId != null) {
      context.read<ProfileBloc>().add(
        GetCommunityProfile(token: _token!, userId: _userId!),
      );
    }
  }

  void _setupPagination() {
    _scrollController.addListener(() {
      // Only proceed if we have a valid scroll position
      if (!_scrollController.hasClients) return;

      final position = _scrollController.position;
      final state = context.read<PostsBloc>().state;

      // Early return if state is not PostsLoaded
      if (state is! PostsLoaded) return;

      // Check if we're near the bottom (75% scrolled or within 200px)
      // More aggressive triggering to ensure pagination works smoothly
      final scrollThreshold = position.maxScrollExtent * 0.75;
      final pixelThreshold = position.maxScrollExtent - 200;
      final isNearBottom = position.pixels >= scrollThreshold ||
                          position.pixels >= pixelThreshold;

      // Debounce logic: prevent rapid requests (500ms cooldown)
      final now = DateTime.now();
      final canLoad = _lastLoadTime == null ||
                     now.difference(_lastLoadTime!).inMilliseconds > 500;

      // Only trigger if all conditions are met:
      // 1. Near the bottom (75% or within 200px)
      // 2. Has more posts to load
      // 3. Not already loading
      // 4. Has valid token
      // 5. Has at least one post
      // 6. Cooldown period passed
      final shouldLoad = isNearBottom &&
                        state.posts.isNotEmpty &&
                        state.hasMorePosts &&
                        !state.isLoadingMore &&
                        _token != null &&
                        canLoad;

      if (shouldLoad) {
        debugPrint('🔄 CommunityHome: Loading more posts');
        debugPrint('  📊 Current: ${state.posts.length} posts, page ${state.currentPage}');
        debugPrint('  ⏭️  Loading: page ${state.currentPage + 1}');
        debugPrint('  📍 Scroll: ${(position.pixels / position.maxScrollExtent * 100).toStringAsFixed(0)}%');

        _lastLoadTime = now;
        context.read<PostsBloc>().add(
          LoadMoreCommunityPosts(
            token: _token!,
            page: state.currentPage + 1,
          ),
        );
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
        child: MultiBlocListener(
          listeners: [
            BlocListener<ProfileBloc, ProfileState>(
              listener: (context, state) {
                if (state is CommunityProfileLoaded && state.profile.isSelf) {
                  setState(() {
                    _currentUserProfile = state.profile;
                  });
                } else if (state is CommunityProfileError) {
                  debugPrint('Error loading user profile: ${state.message}');
                }
              },
            ),
          ],
          child: BlocBuilder<PostsBloc, PostsState>(
            buildWhen: (previous, current) {
              return current is PostsLoading ||
                     current is PostsLoaded ||
                     current is PostsError;
            },
            builder: (context, state) {
            // Show full-screen loading only on initial load
            if (state is PostsLoading) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Add small padding at top
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
                      currentUserProfile: _currentUserProfile,
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),

                  // Loading skeletons in feed area only
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 3,
                        itemBuilder: (context, index) => const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: SinglePostSkeleton(),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            if (state is PostsError) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 1),
                  ),

                  SliverPersistentHeader(
                    pinned: true,
                    floating: false,
                    delegate: CommunityHeader(
                      onSearchTap: _navigateToSearch,
                    ),
                  ),

                  SliverPersistentHeader(
                    pinned: true,
                    floating: false,
                    delegate: _CreatePostSection(
                      onCreatePostTap: _navigateToCreatePost,
                      token: _token!,
                      userId: _userId!,
                      currentUserProfile: _currentUserProfile,
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),

                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: components.PostsError(
                      message: state.message,
                      onRetry: _loadInitialPosts,
                    ),
                  ),
                ],
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
                        currentUserProfile: _currentUserProfile,
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

            // Fallback loading state
            return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPostsList(List<PostEntity> posts, bool hasMorePosts, bool isLoadingMore) {
    if (posts.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: components.PostsEmpty(
          message: 'No posts in your community yet',
          actionText: 'Create First Post',
          onAction: _navigateToCreatePost,
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
              // Show skeleton loader when actively loading more posts
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: SinglePostSkeleton(),
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
  final CommunityProfileEntity? currentUserProfile;

  _CreatePostSection({
    required this.onCreatePostTap,
    required this.token,
    required this.userId,
    this.currentUserProfile,
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
            currentUserProfile: currentUserProfile,
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