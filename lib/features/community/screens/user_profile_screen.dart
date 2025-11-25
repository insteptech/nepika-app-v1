import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/shared_prefs_helper.dart';
import '../widgets/user_post_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/constants/app_constants.dart';
import '../bloc/blocs/profile_bloc.dart';
import '../bloc/events/profile_event.dart';
import '../bloc/states/profile_state.dart';
import '../../../domain/community/entities/community_entities.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/config/env.dart';
import 'dart:convert';
import '../utils/community_navigation.dart';
import '../widgets/post_skeleton_loader.dart';

enum ActiveTab { threads, replies }

class UserProfileScreen extends StatefulWidget {
  final String? userId;
  
  const UserProfileScreen({
    super.key,
    this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String? profileUserId;
  String? _currentUserId;
  String? _token;
  ProfileBloc? _profileBloc;
  bool _isInitialized = false;
  DateTime? _lastLoadTime; // Prevent rapid loading requests

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
  
  // Profile error state
  String? _profileError;
  
  // Follow state
  bool? _isFollowing;
  bool _isFollowLoading = false;
  
  // Scroll-based scaling and header transformation
  double _imageScale = 1.0;
  bool _showScrolledHeader = false; // Controls globe->back icon transition
  late ScrollController _mainScrollController;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Use widget parameter first, then route arguments as fallback
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      profileUserId = widget.userId;
    } else {
      final args = ModalRoute.of(context)?.settings.arguments;
      profileUserId = (args is Map<String, dynamic>)
          ? args['userId'] as String? ?? 'Unknown'
          : 'Unknown';
    }

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
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _profileBloc?.close();
    super.dispose();
  }

  void _onScroll(String tabType) {
    // Only proceed if we have a valid scroll position
    if (!_mainScrollController.hasClients) return;

    final position = _mainScrollController.position;

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

    if (_currentActive == ActiveTab.threads) {
      // Only trigger if all conditions are met for threads
      final shouldLoad = isNearBottom &&
                        _threads.isNotEmpty &&
                        _hasMoreThreads &&
                        !_loadingMoreThreads &&
                        _token != null &&
                        canLoad;

      if (shouldLoad) {
        debugPrint('🔄 Profile: Loading more threads');
        debugPrint('  📊 Current: ${_threads.length} threads, page $_threadsPage');
        debugPrint('  ⏭️  Loading: page ${_threadsPage + 1}');
        debugPrint('  📍 Scroll: ${(position.pixels / position.maxScrollExtent * 100).toStringAsFixed(0)}%');

        _lastLoadTime = now;
        _loadMoreThreads();
      }
    } else if (_currentActive == ActiveTab.replies) {
      // Only trigger if all conditions are met for replies
      final shouldLoad = isNearBottom &&
                        _replies.isNotEmpty &&
                        _hasMoreReplies &&
                        !_loadingMoreReplies &&
                        _token != null &&
                        canLoad;

      if (shouldLoad) {
        debugPrint('🔄 Profile: Loading more replies');
        debugPrint('  📊 Current: ${_replies.length} replies, page $_repliesPage');
        debugPrint('  ⏭️  Loading: page ${_repliesPage + 1}');
        debugPrint('  📍 Scroll: ${(position.pixels / position.maxScrollExtent * 100).toStringAsFixed(0)}%');

        _lastLoadTime = now;
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

      // ProfileBloc initialization is now handled in the build method
      // Just trigger a rebuild to ensure the build method runs
      if (_token != null && profileUserId != null && mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error initializing UserProfilePage: $e");
    }
  }

  void _loadMoreThreads() {
    if (_profileBloc != null && _token != null) {
      setState(() {
        _loadingMoreThreads = true;
      });
      _profileBloc!.add(LoadMoreUserThreads(
        token: _token!,
        userId: profileUserId!,
        page: _threadsPage + 1,
      ));
    }
  }

  void _loadMoreReplies() {
    if (_profileBloc != null && _token != null) {
      setState(() {
        _loadingMoreReplies = true;
      });
      _profileBloc!.add(LoadMoreUserReplies(
        token: _token!,
        userId: profileUserId!,
        page: _repliesPage + 1,
      ));
    }
  }


  void _loadTabData(ActiveTab tab) {
    debugPrint('ProfilePage: _loadTabData called for ${tab.name}');
    debugPrint('ProfilePage: Current active tab: ${_currentActive.name}');
    
    if (tab == ActiveTab.threads) {
      debugPrint('ProfilePage: Loading threads tab, threads empty: ${_threads.isEmpty}');
      if (_threads.isEmpty && _profileBloc != null && _token != null) {
        debugPrint('ProfilePage: Dispatching FetchUserThreads event');
        _profileBloc!.add(FetchUserThreads(
          token: _token!,
          userId: profileUserId!,
        ));
      } else {
        debugPrint('ProfilePage: Threads already loaded (${_threads.length} items) or missing dependencies');
      }
    } else if (tab == ActiveTab.replies) {
      debugPrint('ProfilePage: Loading replies tab, replies empty: ${_replies.isEmpty}');
      if (_replies.isEmpty && _profileBloc != null && _token != null) {
        debugPrint('ProfilePage: Dispatching FetchUserReplies event');
        _profileBloc!.add(FetchUserReplies(
          token: _token!,
          userId: profileUserId!,
        ));
      } else {
        debugPrint('ProfilePage: Replies already loaded (${_replies.length} items) or missing dependencies');
      }
    }
  }

  bool get isCurrentUserProfile {
    // Use backend-provided isSelf if available, fallback to manual comparison
    return _profileData?.isSelf ?? (_currentUserId != null && profileUserId != null && _currentUserId == profileUserId);
  }

  void _handleFollowToggle() {
    if (_token == null || profileUserId == null || _profileBloc == null) return;
    
    // Use backend-provided isFollowing if available, fallback to stored value
    final currentFollowStatus = _profileData?.isFollowing ?? _isFollowing ?? false;
    final newFollowStatus = !currentFollowStatus;
    
    // Optimistic update - immediately update UI
    setState(() {
      _isFollowLoading = true;
      _isFollowing = newFollowStatus;
      
      // Also update profile data for immediate UI response
      if (_profileData != null) {
        _profileData = CommunityProfileEntity(
          id: _profileData!.id,
          userId: _profileData!.userId,
          tenantId: _profileData!.tenantId,
          username: _profileData!.username,
          bio: _profileData!.bio,
          profileImageUrl: _profileData!.profileImageUrl,
          bannerImageUrl: _profileData!.bannerImageUrl,
          isPrivate: _profileData!.isPrivate,
          followersCount: _profileData!.followersCount,
          followingCount: _profileData!.followingCount,
          postsCount: _profileData!.postsCount,
          settings: _profileData!.settings,
          isVerified: _profileData!.isVerified,
          isFollowing: newFollowStatus, // Optimistically update
          isSelf: _profileData!.isSelf,
          createdAt: _profileData!.createdAt,
          updatedAt: _profileData!.updatedAt,
        );
      }
    });
    
    if (currentFollowStatus) {
      _profileBloc!.add(UnfollowUser(
        token: _token!,
        userId: profileUserId!,
      ));
    } else {
      _profileBloc!.add(FollowUser(
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
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    final scaffold = ScaffoldMessenger.of(context);
                    navigator.pop();
                    
                    final result = await CommunityNavigation.navigateToEditProfile(
                      context,
                      token: _token ?? '',
                      currentUsername: _profileData?.username,
                      currentBio: _profileData?.bio,
                      currentProfileImage: _profileData?.profileImageUrl,
                    );
                    
                    if (result != null && mounted) {
                      // Handle the updated profile data
                      scaffold.showSnackBar(
                        const SnackBar(
                          content: Text('Profile updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      // Optionally refresh the profile data
                      if (_token != null && profileUserId != null && _profileBloc != null) {
                        _profileBloc!.add(GetCommunityProfile(token: _token!, userId: profileUserId!));
                      }
                    }
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
    if (_token == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.onTertiary,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show profile not found screen if there's an error
    if (_profileError != null) {
      return _buildProfileNotFound(context);
    }

    // Try to get ProfileBloc from context, handle gracefully if not available
    try {
      final profileBloc = context.read<ProfileBloc>();
      // Update the stored reference and initialize if we got it for the first time
      if (_profileBloc == null) {
        _profileBloc = profileBloc;
        // Trigger initialization now that we have the ProfileBloc
        if (profileUserId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              profileBloc.add(GetCommunityProfile(token: _token!, userId: profileUserId!));
              
              if (_currentUserId != profileUserId && _currentUserId != null) {
                debugPrint('ProfilePage: Loading stored follow status for user: $profileUserId');
                _loadStoredFollowStatus();
                // Note: Backend now provides follow status in profile response, no need for separate API call
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('ProfilePage: ProfileBloc not available yet: $e');
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.onTertiary,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onTertiary,
      body: SafeArea(
        child: BlocListener<ProfileBloc, ProfileState>(
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
                  currentActiveTab: _currentActive,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildPostsList(context, _currentActive),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBlocStateChanges(BuildContext context, ProfileState state) {
    debugPrint('ProfilePage: Received BLoC state: ${state.runtimeType}');
    
    if (state is CommunityProfileLoaded) {
      debugPrint('ProfilePage: Profile loaded: ${state.profile.username}');
      setState(() {
        _profileData = state.profile;
        _profileError = null; // Clear any previous error
      });
      
      // Note: Backend now provides follow status in profile response, no need for separate API call
      
      debugPrint('ProfilePage: Loading initial threads after profile loaded');
      _profileBloc!.add(FetchUserThreads(
        token: _token!,
        userId: profileUserId!,
      ));
    } else if (state is CommunityProfileError && state.userId == profileUserId) {
      debugPrint('ProfilePage: Profile error: ${state.message}');
      setState(() {
        _profileError = state.message;
        _profileData = null; // Clear any previous profile data
      });
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
        
        // Update the profile data's follow status to sync with the backend
        if (_profileData != null) {
          _profileData = CommunityProfileEntity(
            id: _profileData!.id,
            userId: _profileData!.userId,
            tenantId: _profileData!.tenantId,
            username: _profileData!.username,
            bio: _profileData!.bio,
            profileImageUrl: _profileData!.profileImageUrl,
            bannerImageUrl: _profileData!.bannerImageUrl,
            isPrivate: _profileData!.isPrivate,
            followersCount: _profileData!.followersCount,
            followingCount: _profileData!.followingCount,
            postsCount: _profileData!.postsCount,
            settings: _profileData!.settings,
            isVerified: _profileData!.isVerified,
            isFollowing: state.isFollowing, // Update the follow status
            isSelf: _profileData!.isSelf,
            createdAt: _profileData!.createdAt,
            updatedAt: _profileData!.updatedAt,
          );
        }
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
        // Revert the optimistic update on error
        _isFollowing = state.wasFollowing;
        
        // Also revert profile data
        if (_profileData != null) {
          _profileData = CommunityProfileEntity(
            id: _profileData!.id,
            userId: _profileData!.userId,
            tenantId: _profileData!.tenantId,
            username: _profileData!.username,
            bio: _profileData!.bio,
            profileImageUrl: _profileData!.profileImageUrl,
            bannerImageUrl: _profileData!.bannerImageUrl,
            isPrivate: _profileData!.isPrivate,
            followersCount: _profileData!.followersCount,
            followingCount: _profileData!.followingCount,
            postsCount: _profileData!.postsCount,
            settings: _profileData!.settings,
            isVerified: _profileData!.isVerified,
            isFollowing: state.wasFollowing, // Revert to original status
            isSelf: _profileData!.isSelf,
            createdAt: _profileData!.createdAt,
            updatedAt: _profileData!.updatedAt,
          );
        }
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

  Widget _buildProfileNotFound(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onTertiary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.onTertiary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Profile'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Profile not found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _profileError?.contains('404') == true 
                    ? 'This user doesn\'t exist or the profile has been removed.'
                    : _profileError ?? 'Unable to load profile. Please try again.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Go Back'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Retry loading profile
                      if (_token != null && profileUserId != null && _profileBloc != null) {
                        setState(() {
                          _profileError = null;
                        });
                        _profileBloc!.add(GetCommunityProfile(
                          token: _token!,
                          userId: profileUserId!,
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
                    onPressed: () async {
                      final scaffold = ScaffoldMessenger.of(context);
                      
                      final result = await CommunityNavigation.navigateToEditProfile(
                        context,
                        token: _token ?? '',
                        currentUsername: _profileData?.username,
                        currentBio: _profileData?.bio,
                        currentProfileImage: _profileData?.profileImageUrl,
                      );
                      
                      if (result != null && mounted) {
                        // Handle the updated profile data
                        scaffold.showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        // Optionally refresh the profile data
                        if (_token != null && profileUserId != null && _profileBloc != null) {
                          _profileBloc!.add(GetCommunityProfile(token: _token!, userId: profileUserId!));
                        }
                      }
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
                      backgroundColor: (_profileData?.isFollowing ?? _isFollowing) == true 
                        ? Colors.grey[200] 
                        : Theme.of(context).colorScheme.primary,
                      foregroundColor: (_profileData?.isFollowing ?? _isFollowing) == true 
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
                              (_profileData?.isFollowing ?? _isFollowing) == true ? Colors.black54 : Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          (_profileData?.isFollowing ?? _isFollowing) == true ? 'Following' : 'Follow',
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w500,
                            color: (_profileData?.isFollowing ?? _isFollowing) == true ? Colors.black87 : Colors.white,
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
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    debugPrint('ProfilePage: Building tabs with active tab: ${_currentActive.name}');
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
                debugPrint('ProfilePage: Threads tab tapped');
                if (_currentActive != ActiveTab.threads) {
                  debugPrint('ProfilePage: Switching to Threads tab');
                  setState(() {
                    _currentActive = ActiveTab.threads;
                  });
                  _loadTabData(ActiveTab.threads);
                } else {
                  debugPrint('ProfilePage: Threads tab already active');
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: _currentActive == ActiveTab.threads
                      ? Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        )
                      : null,
                ),
                child: AnimatedDefaultTextStyle(
                  // textHeightBehavior: TextHeightBehavior(
                  //   applyHeightToFirstAscent: false,
                  //   applyHeightToLastDescent: false,
                  // ),
                  duration: const Duration(milliseconds: 200),
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: _currentActive == ActiveTab.threads
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: _currentActive == ActiveTab.threads
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                    fontSize: 16,
                  ),
                  child: Text(
                    'Threads',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                debugPrint('ProfilePage: Replies tab tapped');
                if (_currentActive != ActiveTab.replies) {
                  debugPrint('ProfilePage: Switching to Replies tab');
                  setState(() {
                    _currentActive = ActiveTab.replies;
                  });
                  _loadTabData(ActiveTab.replies);
                } else {
                  debugPrint('ProfilePage: Replies tab already active');
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: _currentActive == ActiveTab.replies
                      ? Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        )
                      : null,
                ),
                child: AnimatedDefaultTextStyle(
                  // textHeightBehavior: TextHeightBehavior(
                  //   applyHeightToFirstAscent: false,
                  //   applyHeightToLastDescent: false,
                  // ),
                  duration: const Duration(milliseconds: 200),
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: _currentActive == ActiveTab.replies
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: _currentActive == ActiveTab.replies
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                    fontSize: 16,
                  ),
                  child: const Text(
                    'Replies',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1,
                    ),
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
    final hasMore = tab == ActiveTab.threads ? _hasMoreThreads : _hasMoreReplies;

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

    return Column(
      children: [
        ...currentPosts.map((post) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: UserPostWidget(
              post: post,
              token: _token!,
              userId: _currentUserId!,
            ),
          );
        }),
        if (isLoading && hasMore)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SinglePostSkeleton(),
          ),
      ],
    );
  }
}

class _StickyTabsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final ActiveTab currentActiveTab;

  _StickyTabsDelegate({
    required this.child,
    required this.currentActiveTab,
  });

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
    if (oldDelegate is _StickyTabsDelegate) {
      return currentActiveTab != oldDelegate.currentActiveTab;
    }
    return true;
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
        color: Theme.of(context).colorScheme.onTertiary,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).scaffoldBackgroundColor,
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