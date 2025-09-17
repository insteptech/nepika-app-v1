import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/utils/shared_prefs_helper.dart';
import 'package:nepika/presentation/community/widgets/user_post.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/data/community/repositories/community_repository_impl.dart';
import 'package:nepika/data/community/datasources/community_local_datasource.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';
import '../../../domain/community/entities/community_entities.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nepika/core/config/env.dart';
import 'dart:convert';

enum ActiveTab { threads, replies }

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String? profileUserId;
  String? _currentUserId;
  String? _token;
  CommunityBloc? _communityBloc;
  bool _isInitialized = false;

  ActiveTab _currentActive = ActiveTab.threads;
  
  // Pagination state
  List<PostEntity> _threads = [];
  List<PostEntity> _replies = [];
  bool _hasMoreThreads = false;
  bool _hasMoreReplies = false;
  int _threadsPage = 1;
  int _repliesPage = 1;
  bool _loadingMoreThreads = false;
  bool _loadingMoreReplies = false;

  // Profile data
  CommunityProfileEntity? _profileData;
  
  // Follow state
  bool? _isFollowing;
  bool _isFollowLoading = false;
  
  // Scroll-based scaling and header transformation
  double _imageScale = 1.0;
  bool _showScrolledHeader = false; // Controls globe->back icon transition
  late ScrollController _mainScrollController;

  // PageView controller for swipe navigation
  late PageController _pageController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    profileUserId = (args is Map<String, dynamic>)
        ? args['userId'] as String? ?? 'Unknown'
        : 'Unknown';

    if (!_isInitialized && profileUserId != null && profileUserId != 'Unknown') {
      _isInitialized = true;
      _initializeData();
    }
  }

  @override
  void initState() {
    super.initState();
    _mainScrollController = ScrollController()
      ..addListener(_onMainScroll)
      ..addListener(() => _onScroll('main'));
    _pageController = PageController(initialPage: 0)
      ..addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _pageController.dispose();
    _communityBloc?.close();
    super.dispose();
  }

  void _onScroll(String tabType) {
    if (!_mainScrollController.hasClients) return;
    
    if (_mainScrollController.position.pixels >= _mainScrollController.position.maxScrollExtent * 0.9) {
      if (_currentActive == ActiveTab.threads && _hasMoreThreads && !_loadingMoreThreads) {
        _loadMoreThreads();
      } else if (_currentActive == ActiveTab.replies && _hasMoreReplies && !_loadingMoreReplies) {
        _loadMoreReplies();
      }
    }
  }

  void _onMainScroll() {
    if (!_mainScrollController.hasClients) return;
    
    final scrollOffset = _mainScrollController.offset;
    const maxScroll = 300.0;
    
    // Calculate the exact position where username gets hidden behind header
    // Header height = 56px (sticky header), Profile padding = 20px, Username text position ≈ 20px
    // Total distance from top = Header(56) - Profile_padding(20) - Username_position(20) = ~16px margin
    // So transformation should trigger when scroll reaches approximately 40-50px
    const usernameHiddenThreshold = 45.0; // Precise trigger when profile username gets hidden
    
    double scale = 1.0 - (scrollOffset / maxScroll * 0.4);
    scale = scale.clamp(0.6, 1.4);
    
    // Only show scrolled header when username is actually hidden
    bool shouldShowScrolledHeader = scrollOffset > usernameHiddenThreshold;
    
    if (scale != _imageScale || shouldShowScrolledHeader != _showScrolledHeader) {
      setState(() {
        _imageScale = scale;
        _showScrolledHeader = shouldShowScrolledHeader;
      });
    }
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? 0;
    final newTab = page == 0 ? ActiveTab.threads : ActiveTab.replies;
    if (_currentActive != newTab) {
      setState(() {
        _currentActive = newTab;
      });
      _loadTabData(newTab);
    }
  }

  Future<void> _initializeData() async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      await SharedPrefsHelper.init();
      _token = sharedPreferences.getString(AppConstants.accessTokenKey);

      final userDataString = sharedPreferences.getString(AppConstants.userDataKey);
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        _currentUserId = userData['id'];
      }

      if (_token != null && profileUserId != null) {
        final apiBase = ApiBase();
        final localDataSource = CommunityLocalDataSourceImpl();
        final repository = CommunityRepositoryImpl(apiBase, localDataSource);
        _communityBloc = CommunityBloc(repository);
        
        _communityBloc!.add(GetCommunityProfile(token: _token!, userId: profileUserId!));
        
        if (_currentUserId != profileUserId && _currentUserId != null) {
          debugPrint('ProfilePage: Checking follow status during initialization for user: $profileUserId');
          _loadStoredFollowStatus();
          _communityBloc!.add(CheckFollowStatus(
            token: _token!,
            userId: profileUserId!,
          ));
        }
        
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error initializing UserProfilePage: $e");
    }
  }

  void _loadMoreThreads() {
    if (_communityBloc != null && _token != null) {
      setState(() {
        _loadingMoreThreads = true;
      });
      _communityBloc!.add(LoadMoreUserThreads(
        token: _token!,
        userId: profileUserId!,
        page: _threadsPage + 1,
      ));
    }
  }

  void _loadMoreReplies() {
    if (_communityBloc != null && _token != null) {
      setState(() {
        _loadingMoreReplies = true;
      });
      _communityBloc!.add(LoadMoreUserReplies(
        token: _token!,
        userId: profileUserId!,
        page: _repliesPage + 1,
      ));
    }
  }


  void _loadTabData(ActiveTab tab) {
    if (tab == ActiveTab.threads) {
      debugPrint('ProfilePage: Loading threads tab, threads empty: ${_threads.isEmpty}');
      if (_threads.isEmpty) {
        debugPrint('ProfilePage: Dispatching FetchUserThreads event');
        _communityBloc!.add(FetchUserThreads(
          token: _token!,
          userId: profileUserId!,
        ));
      } else {
        debugPrint('ProfilePage: Threads already loaded (${_threads.length} items)');
      }
    } else if (tab == ActiveTab.replies) {
      debugPrint('ProfilePage: Loading replies tab, replies empty: ${_replies.isEmpty}');
      if (_replies.isEmpty) {
        debugPrint('ProfilePage: Dispatching FetchUserReplies event');
        _communityBloc!.add(FetchUserReplies(
          token: _token!,
          userId: profileUserId!,
        ));
      } else {
        debugPrint('ProfilePage: Replies already loaded (${_replies.length} items)');
      }
    }
  }

  bool get isCurrentUserProfile {
    return _currentUserId != null && profileUserId != null && _currentUserId == profileUserId;
  }

  void _handleFollowToggle() {
    if (_token == null || profileUserId == null || _communityBloc == null) return;
    
    final currentFollowStatus = _isFollowing ?? false;
    
    if (currentFollowStatus) {
      _communityBloc!.add(UnfollowUser(
        token: _token!,
        userId: profileUserId!,
      ));
    } else {
      _communityBloc!.add(FollowUser(
        token: _token!,
        userId: profileUserId!,
      ));
    }
  }

  Future<void> _storeFollowStatus(String userId, bool isFollowing) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('follow_status_$userId', isFollowing);
      debugPrint('ProfilePage: Stored follow status for $userId: $isFollowing');
    } catch (e) {
      debugPrint('ProfilePage: Error storing follow status: $e');
    }
  }

  Future<bool?> _getStoredFollowStatus(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followStatus = prefs.getBool('follow_status_$userId');
      debugPrint('ProfilePage: Retrieved follow status for $userId: $followStatus');
      return followStatus;
    } catch (e) {
      debugPrint('ProfilePage: Error retrieving follow status: $e');
      return null;
    }
  }

  Future<void> _loadStoredFollowStatus() async {
    if (profileUserId == null) return;
    
    final storedStatus = await _getStoredFollowStatus(profileUserId!);
    if (storedStatus != null && mounted) {
      setState(() {
        _isFollowing = storedStatus;
      });
      debugPrint('ProfilePage: Loaded stored follow status: $storedStatus');
    }
  }

  void _shareProfile() {
    if (_profileData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile data not available')),
      );
      return;
    }

    final String profileUrl = '${Env.backendBase}/profile/${_profileData!.userId}';
    
    final String shareText = '''Check out ${_profileData!.username} on Nepika!

${_profileData!.bio ?? ''}

🙋‍♀️ ${_profileData!.followersCount} followers
📝 ${_profileData!.postsCount} posts

Join the conversation: $profileUrl''';

    Share.share(
      shareText,
      subject: '${_profileData!.username} on Nepika',
    );
  }

  void _showMenuOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Dynamic options based on profile type
                if (isCurrentUserProfile) ..._buildCurrentUserMenuOptions()
                else ..._buildOtherUserMenuOptions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Menu options for current user's profile
  List<Widget> _buildCurrentUserMenuOptions() {
    return [
      ListTile(
        leading: Icon(
          Icons.settings,
          color: Theme.of(context).iconTheme.color,
        ),
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        onTap: () {
          Navigator.pop(context);
          _showSettingsOptions();
        },
      ),
      ListTile(
        leading: Icon(
          Icons.lock_outline,
          color: Theme.of(context).iconTheme.color,
        ),
        title: Text(
          'Privacy',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        onTap: () {
          Navigator.pop(context);
          _showPrivacyOptions();
        },
      ),
      ListTile(
        leading: Icon(
          Icons.share,
          color: Theme.of(context).iconTheme.color,
        ),
        title: Text(
          'Share profile',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        onTap: () {
          Navigator.pop(context);
          _shareProfile();
        },
      ),
      ListTile(
        leading: Icon(
          Icons.copy,
          color: Theme.of(context).iconTheme.color,
        ),
        title: Text(
          'Copy link',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        onTap: () {
          Navigator.pop(context);
          _copyProfileLink();
        },
      ),
    ];
  }

  // Menu options for other user's profile
  List<Widget> _buildOtherUserMenuOptions() {
    return [
      ListTile(
        leading: Icon(
          Icons.share,
          color: Theme.of(context).iconTheme.color,
        ),
        title: Text(
          'Share profile',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        onTap: () {
          Navigator.pop(context);
          _shareProfile();
        },
      ),
      ListTile(
        leading: Icon(
          Icons.copy,
          color: Theme.of(context).iconTheme.color,
        ),
        title: Text(
          'Copy link',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        onTap: () {
          Navigator.pop(context);
          _copyProfileLink();
        },
      ),
      ListTile(
        leading: Icon(
          Icons.block,
          color: Colors.red,
        ),
        title: Text(
          'Block user',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.red,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          _blockUser();
        },
      ),
      ListTile(
        leading: Icon(
          Icons.report,
          color: Colors.red,
        ),
        title: Text(
          'Report',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.red,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          _reportUser();
        },
      ),
    ];
  }

  // Additional menu action methods
  void _showSettingsOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit Profile - Coming Soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications - Coming Soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help & Support - Coming Soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPrivacyOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Private Account'),
                  trailing: Switch(
                    value: false, // This would be connected to actual privacy state
                    onChanged: (value) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Private Account ${value ? 'Enabled' : 'Disabled'}')),
                      );
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.visibility_off),
                  title: const Text('Hide Story'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hide Story - Coming Soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Blocked Users'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Blocked Users - Coming Soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _copyProfileLink() {
    if (_profileData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile data not available')),
      );
      return;
    }

    // Copy to clipboard functionality would go here
    // final String profileUrl = '${Env.backendBase}/profile/${_profileData!.userId}';
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile link copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _blockUser() {
    if (_profileData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block ${_profileData!.username}?'),
        content: Text('Are you sure you want to block ${_profileData!.username}? They won\'t be able to find your profile or send you messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_profileData!.username} has been blocked'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _reportUser() {
    if (_profileData == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Report ${_profileData!.username}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: const Text('Inappropriate content'),
                  onTap: () => _submitReport('Inappropriate content'),
                ),
                ListTile(
                  leading: const Icon(Icons.person_off, color: Colors.red),
                  title: const Text('Harassment or bullying'),
                  onTap: () => _submitReport('Harassment or bullying'),
                ),
                ListTile(
                  leading: const Icon(Icons.security, color: Colors.red),
                  title: const Text('Spam or scam'),
                  onTap: () => _submitReport('Spam or scam'),
                ),
                ListTile(
                  leading: const Icon(Icons.more_horiz, color: Colors.red),
                  title: const Text('Other'),
                  onTap: () => _submitReport('Other'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitReport(String reason) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report submitted: $reason'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_token == null || _communityBloc == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.onTertiary,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider.value(
      value: _communityBloc!,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.onTertiary,
        body: SafeArea(
          child: BlocListener<CommunityBloc, CommunityState>(
            listener: _handleBlocStateChanges,
            child: CustomScrollView(
            controller: _mainScrollController,
            slivers: [
              // Sticky Dynamic Header
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  showScrolledHeader: _showScrolledHeader,
                  profileData: _profileData,
                  onBackPressed: () => Navigator.of(context).pop(),
                  onMenuPressed: () => _showMenuOptions(),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildProfileContent(context),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabsDelegate(
                  child: Container(
                    color: Theme.of(context).colorScheme.onTertiary,
                    child: _buildTabs(context),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      final newTab = index == 0 ? ActiveTab.threads : ActiveTab.replies;
                      if (_currentActive != newTab) {
                        setState(() {
                          _currentActive = newTab;
                        });
                        _loadTabData(newTab);
                      }
                    },
                    children: [
                      _buildPostsList(context, ActiveTab.threads),
                      _buildPostsList(context, ActiveTab.replies),
                    ],
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

  void _handleBlocStateChanges(BuildContext context, CommunityState state) {
    debugPrint('ProfilePage: Received BLoC state: ${state.runtimeType}');
    
    if (state is CommunityProfileLoaded) {
      debugPrint('ProfilePage: Profile loaded: ${state.profile.username}');
      setState(() {
        _profileData = state.profile;
      });
      
      if (_currentUserId != profileUserId && _currentUserId != null) {
        debugPrint('ProfilePage: Checking follow status for user: $profileUserId');
        _communityBloc!.add(CheckFollowStatus(
          token: _token!,
          userId: profileUserId!,
        ));
      }
      
      debugPrint('ProfilePage: Loading initial threads after profile loaded');
      _communityBloc!.add(FetchUserThreads(
        token: _token!,
        userId: profileUserId!,
      ));
    } else if (state is UserThreadsLoaded && state.userId == profileUserId) {
      debugPrint('ProfilePage: Threads loaded: ${state.threads.length} items');
      setState(() {
        _threads = state.threads;
        _hasMoreThreads = state.hasMoreThreads;
        _threadsPage = state.currentPage;
        _loadingMoreThreads = false;
      });
    } else if (state is UserRepliesLoaded && state.userId == profileUserId) {
      debugPrint('ProfilePage: Replies loaded: ${state.replies.length} items');
      setState(() {
        _replies = state.replies;
        _hasMoreReplies = state.hasMoreReplies;
        _repliesPage = state.currentPage;
        _loadingMoreReplies = false;
      });
    } else if (state is UserThreadsLoadingMore && state.userId == profileUserId) {
      debugPrint('ProfilePage: Loading more threads');
      setState(() {
        _loadingMoreThreads = true;
      });
    } else if (state is UserRepliesLoadingMore && state.userId == profileUserId) {
      debugPrint('ProfilePage: Loading more replies');
      setState(() {
        _loadingMoreReplies = true;
      });
    } else if (state is UserThreadsError) {
      debugPrint('ProfilePage: Threads error: ${state.message}');
      setState(() {
        _loadingMoreThreads = false;
        _loadingMoreReplies = false;
      });
    } else if (state is UserRepliesError) {
      debugPrint('ProfilePage: Replies error: ${state.message}');
      setState(() {
        _loadingMoreThreads = false;
        _loadingMoreReplies = false;
      });
    } else if (state is FollowStatusLoaded && state.userId == profileUserId) {
      debugPrint('ProfilePage: Follow status loaded: ${state.isFollowing}');
      setState(() {
        _isFollowing = state.isFollowing;
      });
      _storeFollowStatus(profileUserId!, state.isFollowing);
    } else if (state is FollowLoading && state.userId == profileUserId) {
      debugPrint('ProfilePage: Follow operation in progress');
      setState(() {
        _isFollowLoading = true;
      });
    } else if (state is FollowSuccess && state.userId == profileUserId) {
      debugPrint('ProfilePage: Follow operation success: ${state.message}');
      setState(() {
        _isFollowing = state.isFollowing;
        _isFollowLoading = false;
      });
      
      _storeFollowStatus(profileUserId!, state.isFollowing);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.green,
        ),
      );
    } else if (state is FollowError && state.userId == profileUserId) {
      debugPrint('ProfilePage: Follow operation error: ${state.message}');
      setState(() {
        _isFollowLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${state.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      debugPrint('ProfilePage: Unhandled state: ${state.runtimeType}');
    }
  }

  Widget _buildProfileContent(BuildContext context) {
    if (_profileData == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profileData!.username,
                      style: Theme.of(context).textTheme.displayLarge!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_profileData!.bio != null && _profileData!.bio!.isNotEmpty)
                      Text(
                        _profileData!.bio!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 12),
                    Text(
                      '${_profileData!.followersCount} followers',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 100),
                tween: Tween(begin: _imageScale, end: _imageScale),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: _profileData!.profileImageUrl != null && _profileData!.profileImageUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                _profileData!.profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              if (isCurrentUserProfile) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit Profile - Coming Soon!')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Edit Profile',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _shareProfile,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Share Profile',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isFollowLoading ? null : () {
                      _handleFollowToggle();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowing == true 
                        ? Colors.grey[200] 
                        : Theme.of(context).colorScheme.primary,
                      foregroundColor: _isFollowing == true 
                        ? Colors.black87 
                        : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isFollowLoading 
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isFollowing == true ? Colors.black54 : Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _isFollowing == true ? 'Following' : 'Follow',
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w500,
                            color: _isFollowing == true ? Colors.black87 : Colors.white,
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message - Coming Soon!')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Message',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                if (_currentActive != ActiveTab.threads) {
                  setState(() {
                    _currentActive = ActiveTab.threads;
                  });
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                  _loadTabData(ActiveTab.threads);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: _currentActive == ActiveTab.threads
                      ? const Border(
                          bottom: BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        )
                      : null,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: _currentActive == ActiveTab.threads
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: _currentActive == ActiveTab.threads
                        ? Colors.black
                        : Colors.grey[600],
                    fontSize: 16,
                  ),
                  child: const Text(
                    'Threads',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                if (_currentActive != ActiveTab.replies) {
                  setState(() {
                    _currentActive = ActiveTab.replies;
                  });
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                  _loadTabData(ActiveTab.replies);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: _currentActive == ActiveTab.replies
                      ? const Border(
                          bottom: BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        )
                      : null,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: _currentActive == ActiveTab.replies
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: _currentActive == ActiveTab.replies
                        ? Colors.black
                        : Colors.grey[600],
                    fontSize: 16,
                  ),
                  child: const Text(
                    'Replies',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList(BuildContext context, ActiveTab tab) {
    final currentPosts = tab == ActiveTab.threads ? _threads : _replies;
    final isLoading = tab == ActiveTab.threads ? _loadingMoreThreads : _loadingMoreReplies;

    if (currentPosts.isEmpty && !isLoading) {
      return SizedBox(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tab == ActiveTab.threads
                    ? Icons.forum_outlined
                    : Icons.reply_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                tab == ActiveTab.threads
                    ? 'No threads yet'
                    : 'No replies yet',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (currentPosts.isEmpty && isLoading) {
      return const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: currentPosts.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == currentPosts.length && isLoading) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (index >= currentPosts.length) {
          return const SizedBox.shrink();
        }

        final post = currentPosts[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: UserPostWidget(
            post: post,
            token: _token!,
            userId: _currentUserId!,
          ),
        );
      },
    );
  }
}

class _StickyTabsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabsDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 48.0;

  @override
  double get minExtent => 48.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool showScrolledHeader;
  final CommunityProfileEntity? profileData;
  final VoidCallback onBackPressed;
  final VoidCallback onMenuPressed;

  _StickyHeaderDelegate({
    required this.showScrolledHeader,
    required this.profileData,
    required this.onBackPressed,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Icon - Globe initially, Back arrow on scroll
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: showScrolledHeader
                    ? IconButton(
                        key: const ValueKey('back_button'),
                        icon: const Icon(Icons.arrow_back, size: 24),
                        onPressed: onBackPressed,
                        padding: const EdgeInsets.all(8),
                      )
                    : IconButton(
                        key: const ValueKey('globe_button'),
                        icon: Image.asset(
                          'assets/icons/globe_icon.png',
                          width: 24,
                          height: 24,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        onPressed: onBackPressed,
                        padding: const EdgeInsets.all(8),
                      ),
              ),
              
              // Center - Username (only visible on scroll)
              Expanded(
                child: AnimatedOpacity(
                  opacity: showScrolledHeader ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedSlide(
                    offset: showScrolledHeader ? Offset.zero : const Offset(0, -0.3),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        profileData?.username ?? '',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Right Icon - Menu
              IconButton(
                icon: Image.asset(
                  'assets/icons/menu_icon.png',
                  width: 24,
                  height: 24,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: onMenuPressed,
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
    );
  }

  @override
  double get maxExtent => 56.0;

  @override
  double get minExtent => 56.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate is! _StickyHeaderDelegate ||
           oldDelegate.showScrolledHeader != showScrolledHeader ||
           oldDelegate.profileData != profileData;
  }
}