import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/core/widgets/back_button.dart';
import 'package:nepika/data/community/repositories/community_repository_impl.dart';
import 'package:nepika/data/community/datasources/community_local_datasource.dart';
import 'package:nepika/core/api_base.dart';
import '../../../domain/community/entities/community_entities.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';

/// Independent User Search Page
/// 
/// This page can be used independently without requiring any parameters.
/// It automatically:
/// - Loads user token from SharedPreferences
/// - Creates its own BLoC instance
/// - Handles all user search functionality
/// 
/// Usage Examples:
/// 
/// 1. Simple Navigation:
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(builder: (context) => const UserSearchPage()),
/// );
/// ```
/// 
/// 2. Using the Integration Helper:
/// ```dart
/// UserSearchPageIntegration.navigateTo(context);
/// ```
/// 
/// 3. Named Route (add to main.dart routes):
/// ```dart
/// Navigator.of(context).pushNamed('/user-search');
/// ```
class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _token;
  late CommunityBloc _communityBloc;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      _communityBloc.add(ClearUserSearch());
      return;
    }
    
    if (query.length <= 2) {
      // Don't search for queries with 2 or fewer characters
      _communityBloc.add(ClearUserSearch());
      return;
    }
    
    // Start new debounce timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_token != null && query.length > 2) {
        _communityBloc.add(
          SearchUsersV2(token: _token!, query: query),
        );
      }
    });
  }

  Future<void> _initializeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(AppConstants.accessTokenKey);
      
      // Initialize BLoC with repository
      final apiBase = ApiBase();
      final localDataSource = CommunityLocalDataSourceImpl();
      final repository = CommunityRepositoryImpl(apiBase, localDataSource);
      _communityBloc = CommunityBloc(repository);
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('UserSearchPage: Error initializing data: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _communityBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_token == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Search', style: Theme.of(context).textTheme.bodyLarge),
          centerTitle: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: null,
          forceMaterialTransparency: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return BlocProvider<CommunityBloc>(
      create: (context) => _communityBloc,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Sticky Header
              SliverPersistentHeader(
                pinned: true,
                delegate: _SearchStickyHeaderDelegate(
                  searchController: _searchController,
                ),
              ),
              
              // Search Results
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 160,
                    child: BlocBuilder<CommunityBloc, CommunityState>(
                      builder: (context, state) {
                        if (state is UserSearchV2Loading) {
                          return _buildSkeletonLoading();
                        } else if (state is UserSearchV2Loaded) {
                          if (state.users.isEmpty) {
                            return const Center(
                              child: Text(
                                'No users found',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            );
                          }
                          return ListView.builder(
                            itemCount: state.users.length,
                            itemBuilder: (context, index) {
                              final user = state.users[index];
                              return _UserSearchCardV2(
                                user: user,
                                token: _token!,
                                communityBloc: _communityBloc,
                              );
                            },
                          );
                        } else if (state is UserSearchV2Error) {
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
                                  'Error: ${state.message}',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    final query = _searchController.text.trim();
                                    if (query.length > 2 && _token != null) {
                                      _communityBloc.add(
                                        SearchUsersV2(
                                          token: _token!,
                                          query: query,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // Check if we should show minimum character hint
                          final query = _searchController.text.trim();
                          if (query.isNotEmpty && query.length <= 2) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'Type at least 3 characters to search',
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Start typing to search for users',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              // Avatar skeleton
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),

              // User Info skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 200,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),

              // Follow button skeleton
              Container(
                height: 32,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserSearchCardV2 extends StatelessWidget {
  final UserSearchResultEntity user;
  final String token;
  final CommunityBloc communityBloc;

  const _UserSearchCardV2({
    required this.user,
    required this.token,
    required this.communityBloc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                ? NetworkImage(user.profileImageUrl!)
                : null,
            backgroundColor: Colors.grey[300],
            child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                ? Text(
                    user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '@${user.username}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        size: 16,
                        color: Colors.blue,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.followersCount} followers',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Joined ${_formatDate(user.createdAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),

          // Follow Button
          BlocBuilder<CommunityBloc, CommunityState>(
            bloc: communityBloc,
            builder: (context, state) {
              bool isFollowing = user.isFollowing;
              bool isLoading = false;
              
              // Check if this specific user is in a loading state
              if (state is UserFollowToggling && state.userId == user.id) {
                isLoading = true;
              } else if (state is UserFollowToggled && state.userId == user.id) {
                isFollowing = state.isFollowing;
              }

              return GestureDetector(
                onTap: isLoading ? null : () {
                  communityBloc.add(ToggleUserFollow(
                    token: token,
                    userId: user.id,
                    currentlyFollowing: isFollowing,
                  ));
                },
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isFollowing ? Colors.grey[200] : Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isFollowing ? Colors.black : Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            isFollowing ? 'Following' : 'Follow',
                            style: TextStyle(
                              color: isFollowing ? Colors.black : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'today';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }
}

// Sticky Header Delegate for Search Page
class _SearchStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;

  _SearchStickyHeaderDelegate({required this.searchController});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isStuckToTop = shrinkOffset > 0;
    
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: isStuckToTop ? 15 : 0,
        bottom: 10,
      ),
      child: Column(
        children: [
          // Header with back button and title
          Row(
            children: [
              CustomBackButton(
                label: '',
                iconSize: 24,
                iconColor: Theme.of(context).colorScheme.primary,
              ),
              Expanded(
                child: Text(
                  'Search',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(width: 40), // Balance the back button width
            ],
          ),
          
          const SizedBox(height: 15),
          
          // Search Input Field
          Container(
            height: 53,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onTertiary,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Theme.of(context).textTheme.headlineMedium!
                    .secondary(context)
                    .color!,
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.only(right: 3),
            child: TextField(
              controller: searchController,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: Theme.of(
                  context,
                ).textTheme.bodyLarge!.secondary(context),
                fillColor: Colors.transparent,
                prefixIcon: SizedBox(
                  width: 10,
                  height: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Image.asset(
                      'assets/icons/search_icon.png',
                      height: 10,
                      width: 10,
                    ),
                  ),
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 120.0;
  
  @override
  double get minExtent => 120.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

