import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/config/constants/app_constants.dart';
import '../../../../core/config/constants/routes.dart';
import '../../../../core/widgets/navigation/navigation_components.dart';
import '../../../../core/widgets/notification_permission_dialog.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
    _checkNotificationPermissions();
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

  void _checkNotificationPermissions() {
    // Use a post-frame callback to ensure the widget is built before showing dialog
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        // Wait a bit for the screen to settle
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (mounted) {
          await NotificationPermissionHelper.showPermissionDialogIfNeeded(context);
        }
      }
    });
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

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _onDrawerItemTap(int index) {
    Navigator.of(context).pop(); // Close drawer first
    
    switch (index) {
      case 0: // Home
        // Already on community home, just refresh
        _refreshPosts();
        break;
      case 1: // Search
        _navigateToSearch();
        break;
      case 2: // Community Settings
        debugPrint('🚨 Navigating to: ${CommunityRoutes.communitySettings}');
        Navigator.of(context, rootNavigator: true).pushNamed(CommunityRoutes.communitySettings);
        break;
      case 3: // Dashboard
        Navigator.of(context, rootNavigator: true).pushNamed(AppRoutes.dashboardHome);
        break;
    }
  }

  void _onUserInfoTap() {
    Navigator.of(context).pop(); // Close drawer first
Navigator.of(context, rootNavigator: true).pushNamed(
            AppRoutes.communityUserProfile,
            arguments: {'userId': _userId!},
          );
            }

  List<DrawerItem> _buildDrawerItems() {
    return [
      const DrawerItem(
        title: 'Home',
        icon: Icons.home_outlined,
      ),
      const DrawerItem(
        title: 'Search',
        icon: Icons.search_outlined,
      ),
      const DrawerItem(
        title: 'Community Settings',
        icon: Icons.settings_outlined,
      ),
      const DrawerItem(
        title: 'Dashboard',
        icon: Icons.dashboard_outlined,
      ),
    ];
  }

  Widget _buildCommunityDrawer() {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.onTertiary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          bottomLeft: Radius.circular(0),
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // User Info Section (Clickable)
              _buildUserInfoSection(),
              
              // First Divider
              _buildDivider(),
              
              // Navigation Menu Items
              _buildMenuItems(),
              
              // Full width divider line
              _buildFullWidthDivider(),
              
              // Other Links section
              _buildOtherLinksSection(),
              
              // Add some bottom spacing instead of Spacer
              const SizedBox(height: 40),
              
              // Create Post Button at bottom
              _buildCreatePostButton(),
              
              // Additional bottom padding to ensure content is accessible
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _onUserInfoTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.person,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Name only (no email as per your modification)
              Expanded(
                child: Text(
                  _currentUserProfile?.username ?? 'Community User',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Arrow indicator
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 1,
      width: double.infinity,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
    );
  }

  Widget _buildMenuItems() {
    return Column(
      children: _buildDrawerItems().asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _onDrawerItemTap(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 24,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFullWidthDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 1,
      width: double.infinity,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
    );
  }

  Widget _buildOtherLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Small dull heading
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            'Other Links',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
        
        // Edit Profile
        _buildOtherLinkItem(
          title: 'Edit Profile',
          icon: Icons.edit_outlined,
          onTap: () async {
            Navigator.of(context).pop(); // Close drawer
            
            if (_token != null) {
              // Navigate to edit profile screen using CommunityNavigation
              await CommunityNavigation.navigateToEditProfile(
                context,
                token: _token!,
                currentUsername: _currentUserProfile?.username,
                currentBio: _currentUserProfile?.bio,
                currentProfileImage: _currentUserProfile?.profileImageUrl,
              );
            } else {
              // Show error if token is not available
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Unable to edit profile. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        
        // Blocked Users
        _buildOtherLinkItem(
          title: 'Blocked Users',
          icon: Icons.block_outlined,
          onTap: () {
            Navigator.of(context).pop(); // Close drawer
            // Navigate to blocked users screen
            Navigator.of(context, rootNavigator: true).pushNamed(AppRoutes.blockedUsers);
          },
        ),
        
        // Reports
        // _buildOtherLinkItem(
        //   title: 'Reports',
        //   icon: Icons.report_outlined,
        //   onTap: () {
        //     Navigator.of(context).pop(); // Close drawer
        //     // Navigate to reports screen
        //     Navigator.of(context, rootNavigator: true).pushNamed('/reports');
        //   },
        // ),
      ],
    );
  }

  Widget _buildOtherLinkItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePostButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context).pop(); // Close drawer
          _navigateToCreatePost();
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          foregroundColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Create Post',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
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
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.onTertiary,
      drawer: _buildCommunityDrawer(),
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
                      onMenuTap: _openDrawer,
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
                      onMenuTap: _openDrawer,
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
                        onMenuTap: _openDrawer,
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