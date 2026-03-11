import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/constants/app_constants.dart';
import '../../../../core/config/constants/routes.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../domain/community/entities/community_entities.dart';
import '../bloc/blocs/followers_bloc.dart';
import '../bloc/events/followers_event.dart';
import '../bloc/states/followers_state.dart';

class FollowersListScreen extends StatefulWidget {
  final String userId;
  final String username;
  final bool isFollowers;

  const FollowersListScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.isFollowers,
  });

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: widget.isFollowers ? 0 : 1,
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.onTertiary,
        appBar: AppBar(
          title: Text(
            widget.username,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.onTertiary,
          elevation: 0,
          forceMaterialTransparency: true,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Followers'),
              Tab(text: 'Following'),
            ],
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey[600],
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: TabBarView(
          children: [
            BlocProvider(
              create: (context) => di.sl<FollowersBloc>(),
              child: FollowersListView(
                userId: widget.userId,
                isFollowers: true,
              ),
            ),
            BlocProvider(
              create: (context) => di.sl<FollowersBloc>(),
              child: FollowersListView(
                userId: widget.userId,
                isFollowers: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FollowersListView extends StatefulWidget {
  final String userId;
  final bool isFollowers;

  const FollowersListView({
    super.key,
    required this.userId,
    required this.isFollowers,
  });

  @override
  State<FollowersListView> createState() => _FollowersListViewState();
}

class _FollowersListViewState extends State<FollowersListView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _token;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initialize();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.accessTokenKey);
    if (_token != null && mounted) {
      context.read<FollowersBloc>().add(FetchFollowersList(
        token: _token!,
        userId: widget.userId,
        isFollowers: widget.isFollowers,
      ));
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      final state = context.read<FollowersBloc>().state;
      if (state is FollowersListLoaded && state.hasMore && state is! FollowersListLoadingMore) {
        if (_token != null) {
          context.read<FollowersBloc>().add(LoadMoreFollowers(
            token: _token!,
            userId: widget.userId,
            isFollowers: widget.isFollowers,
          ));
        }
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_token != null && mounted) {
        context.read<FollowersBloc>().add(SearchFollowers(
          token: _token!,
          userId: widget.userId,
          isFollowers: widget.isFollowers,
          query: _searchController.text,
        ));
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search ${widget.isFollowers ? 'followers' : 'following'}...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<FollowersBloc, FollowersState>(
            builder: (context, state) {
              if (state is FollowersListLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is FollowersListError) {
                return Center(child: Text('Error: ${state.message}'));
              } else if (state is FollowersListLoaded) {
                final users = state.filteredUsers;
                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      state.searchQuery != null && state.searchQuery!.isNotEmpty
                          ? 'No users found for "${state.searchQuery}"'
                          : 'No users yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }
                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length + (state.hasMore ? 1 : 0),
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index < users.length) {
                      return _FollowerUserCard(
                        user: users[index],
                        token: _token ?? '',
                        isFollowersList: widget.isFollowers,
                      );
                    } else {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }
}

class _FollowerUserCard extends StatelessWidget {
  final CommunityProfileEntity user;
  final String token;
  final bool isFollowersList;

  const _FollowerUserCard({
    required this.user,
    required this.token,
    required this.isFollowersList,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: GestureDetector(
        onTap: () => _navigateToProfile(context),
        child: CircleAvatar(
          radius: 24,
          backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
              ? NetworkImage(user.profileImageUrl!)
              : null,
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          child: (user.profileImageUrl == null || user.profileImageUrl!.isEmpty)
              ? Text(
                  user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
      ),
      title: GestureDetector(
        onTap: () => _navigateToProfile(context),
        child: Row(
          children: [
            Text(
              '@${user.username}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (user.isVerified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, size: 16, color: Colors.blue),
            ],
          ],
        ),
      ),
      subtitle: user.bio != null && user.bio!.isNotEmpty
          ? Text(
              user.bio!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            )
          : null,
      trailing: (!user.isSelf && isFollowersList)
          ? BlocBuilder<FollowersBloc, FollowersState>(
              builder: (context, state) {
                return GestureDetector(
                  onTap: () {
                    context.read<FollowersBloc>().add(ToggleFollowUserInList(
                      token: token,
                      userId: user.userId,
                      currentFollowStatus: user.isFollowing,
                    ));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: user.isFollowing ? Colors.grey[200] : Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      user.isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(
                        color: user.isFollowing ? Colors.black : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.communityUserProfile,
      arguments: {'userId': user.userId},
    );
  }
}
