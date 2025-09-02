import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/data/community/repositories/community_repository_impl.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query.isNotEmpty && _token != null) {
        _communityBloc.add(
          SearchUsers(token: _token!, query: query),
        );
      } else {
        _communityBloc.add(ClearUserSearch());
      }
    });
  }

  Future<void> _initializeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(AppConstants.accessTokenKey);
      
      // Initialize BLoC with repository
      final apiBase = ApiBase();
      final repository = CommunityRepositoryImpl(apiBase);
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
        appBar: AppBar(
          title: Text('Search', style: Theme.of(context).textTheme.bodyLarge),
          centerTitle: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          forceMaterialTransparency: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              Container( 
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
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
                            controller: _searchController,
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
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Search Results
              Expanded(
                child: BlocBuilder<CommunityBloc, CommunityState>(
                  builder: (context, state) {
                    if (state is UserSearchLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is UserSearchLoaded) {
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
                          return _UserSearchCard(user: user);
                        },
                      );
                    } else if (state is UserSearchError) {
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
                                if (_searchController.text.isNotEmpty && _token != null) {
                                  _communityBloc.add(
                                    SearchUsers(
                                      token: _token!,
                                      query: _searchController.text.trim(),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _UserSearchCard extends StatelessWidget {
  final SearchUserEntity user;

  const _UserSearchCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundImage:
                user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                ? NetworkImage(user.avatarUrl!)
                : null,
            backgroundColor: Colors.grey[300],
            child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                ? Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
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
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.bio!,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Follow Button
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: user.isFollowing ? Colors.grey[200] : Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                user.isFollowing ? 'Following' : 'Follow',
                style: TextStyle(
                  color: user.isFollowing ? Colors.black : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
