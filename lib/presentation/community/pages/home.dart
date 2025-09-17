import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/widgets/back_button.dart';
import 'package:nepika/domain/community/entities/community_entities.dart';
import 'package:nepika/presentation/community/widgets/user_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/data/community/datasources/community_local_datasource.dart';
import 'package:nepika/presentation/community/widgets/create_post.dart';
import 'package:nepika/presentation/community/widgets/page_header.dart';
import 'package:nepika/presentation/community/widgets/user_post.dart';
import '../../../data/community/repositories/community_repository_impl.dart';
import '../../../core/api_base.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';
import 'user_search_page.dart';
import 'create_post_page.dart';

class CommunityHomePage extends StatefulWidget {
  final String token;
  final String userId;

  const CommunityHomePage({
    super.key,
    required this.token,
    required this.userId,
  });

  @override
  State<CommunityHomePage> createState() => _CommunityHomePageState();
}

class _CommunityHomePageState extends State<CommunityHomePage> {
  late CommunityBloc _communityBloc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _communityBloc = CommunityBloc(CommunityRepositoryImpl(ApiBase(), CommunityLocalDataSourceImpl()));
    _communityBloc.add(FetchCommunityPosts(token: widget.token));

    // Setup pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure the bloc is properly connected when dependencies change
    // This helps prevent blank screen issues after navigation
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = _communityBloc.state;
      if (state is CommunityPostsLoaded && state.hasMorePosts) {
        _communityBloc.add(
          LoadMoreCommunityPosts(
            token: widget.token,
            page: state.currentPage + 1,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _communityBloc.close();
    super.dispose();
  }

  void _navigateToSearch() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: _communityBloc,
          child: UserSearchPage(),
        ),
      ),
    );
    
    // Refresh posts when returning from search
    if (mounted) {
      _communityBloc.add(RefreshCommunityPosts(token: widget.token));
    }
  }

  void _navigateToCreatePost() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: _communityBloc,
          child: CreatePostPage(
            token: widget.token,
            userId: widget.userId,
          ),
        ),
      ),
    );

    // Always refresh posts when returning
    // This ensures the home screen state is properly restored
    if (mounted) {
      _communityBloc.add(RefreshCommunityPosts(token: widget.token));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _communityBloc,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: BlocBuilder<CommunityBloc, CommunityState>(
            bloc: _communityBloc,
            buildWhen: (previous, current) {
              return current is CommunityPostsLoading ||
                     current is CommunityPostsLoaded ||
                     current is CommunityPostsLoadingMore ||
                     current is CommunityPostsError;
            },
            builder: (context, state) {
              if (state is CommunityPostsLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is CommunityPostsLoaded ||
                  state is CommunityPostsLoadingMore) {
                final posts = state is CommunityPostsLoaded
                    ? state.posts
                    : (state as CommunityPostsLoadingMore).currentPosts;
                final hasMorePosts = state is CommunityPostsLoaded
                    ? state.hasMorePosts
                    : true;

                return RefreshIndicator(
                  onRefresh: () async {
                    _communityBloc.add(
                      RefreshCommunityPosts(token: widget.token),
                    );
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Normal Header that becomes sticky when scrolled
                      SliverPersistentHeader(
                        pinned: true,
                        floating: false,
                        delegate: _StickyHeaderDelegate(
                          onSearchTap: _navigateToSearch,
                        ),
                      ),

                      // Normal Create Post Widget that becomes sticky
                      SliverPersistentHeader(
                        pinned: true,
                        floating: false,
                        delegate: _StickyCreatePostDelegate(
                          onCreatePostTap: _navigateToCreatePost,
                          token: widget.token,
                          userId: widget.userId,
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: SizedBox(height: 20),
                      ),
                      // Posts List
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index < posts.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: UserPostWidget(
                                    post: posts[index],
                                    token: widget.token,
                                    userId: widget.userId,
                                  ),
                                );
                              } else if (hasMorePosts) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return null;
                            },
                            childCount: posts.length + (hasMorePosts ? 1 : 0),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else if (state is CommunityPostsError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading posts',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _communityBloc.add(
                            FetchCommunityPosts(token: widget.token),
                          );
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }
}

// Sticky Header Delegate for Nepika Logo
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onSearchTap;

  _StickyHeaderDelegate({required this.onSearchTap});

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
      color: Theme.of(context).scaffoldBackgroundColor,
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
              child: CustomBackButton()
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

// Sticky Create Post Delegate
class _StickyCreatePostDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onCreatePostTap;
  final String token;
  final String userId;

  _StickyCreatePostDelegate({
    required this.onCreatePostTap,
    required this.token,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = shrinkOffset / maxExtent;
    final clampedProgress = progress.clamp(0.0, 1.0);
    
    // Reduce container height by percentage on scroll
    final containerHeight = maxExtent - (maxExtent * 0.3 * clampedProgress); // Reduce by 30%
    final avatarSize = 55.0 - (15.0 * clampedProgress); // Avatar size: 55 -> 40
    final fontSize = 16.0 - (3.0 * clampedProgress); // Reduce font size: 16 -> 13

    return Container(
      height: containerHeight,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        // Remove margins - purely height-based
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context)
                  .textTheme
                  .headlineMedium!
                  .secondary(context)
                  .color!
                  .withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: _BuildCreatePostContent(
          onCreatePostTap: onCreatePostTap,
          avatarSize: avatarSize,
          fontSize: fontSize,
          token: token,
          userId: userId,
        ),
      ),
    );
  }

  @override
  double get maxExtent => 70.0; // Initial height
  
  @override
  double get minExtent => 49.0; // 30% reduction: 70 - (70 * 0.3) = 49

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

// Create Post Content Widget with User Image
class _BuildCreatePostContent extends StatefulWidget {
  final VoidCallback onCreatePostTap;
  final double avatarSize;
  final double fontSize;
  final String token;
  final String userId;

  const _BuildCreatePostContent({
    required this.onCreatePostTap,
    required this.avatarSize,
    required this.fontSize,
    required this.token,
    required this.userId,
  });

  @override
  State<_BuildCreatePostContent> createState() => _BuildCreatePostContentState();
}

class _BuildCreatePostContentState extends State<_BuildCreatePostContent> {
  String? _userAvatar;
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      final userDataString = sharedPrefs.getString(AppConstants.userDataKey);
      
      if (userDataString != null && mounted) {
        final userData = jsonDecode(userDataString);
        setState(() {
          _username = userData['username'] ?? 'User';
          _userAvatar = userData['profileImageUrl'];
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onCreatePostTap,
      child: Row(
    
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
            UserImageIcon(
              author:   AuthorEntity(
                id: widget.userId, 
                fullName: widget.userId, 
                avatarUrl: ''
              ),
            ),
            SizedBox(width: 15),
            // Create Post Text
          Expanded(
            child: Text(
                'Create a new Post...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
          ),
          
          const SizedBox(width: 10),
          
          // Share Icon
          GestureDetector(
            onTap: widget.onCreatePostTap,
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Image.asset(
                'assets/icons/share_icon.png',
                height: 20,
              ),
            ),
          ), 
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    final hasValidUrl = _userAvatar?.isNotEmpty == true;
    
    return Container(
      height: widget.avatarSize,
      width: widget.avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasValidUrl 
            ? Colors.transparent 
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        border: Border.all(
          color: hasValidUrl 
              ? Colors.transparent 
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: hasValidUrl
          ? ClipOval(
              child: Image.network(
                _userAvatar!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultIcon(context);
                },
              ),
            )
          : _buildFallbackAvatar(),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: Center(
        child: _buildDefaultIcon(context),
      ),
    );
  }

  Widget _buildDefaultIcon(BuildContext context) {
    return Icon(
        Icons.person,
        size: 22,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
      );
  }
}
