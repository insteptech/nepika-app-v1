// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:nepika/core/utils/shared_prefs_helper.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:nepika/core/config/constants/app_constants.dart';
// import 'package:nepika/core/api_base.dart';
// import 'package:nepika/data/community/repositories/community_repository_impl.dart';
// import 'package:nepika/data/community/datasources/community_local_datasource.dart';
// import '../widgets/profile_header.dart';
// import '../widgets/profile_info.dart';
// import '../widgets/tabs_header.dart';
// import '../widgets/feed_section.dart';
// import '../widgets/bottom_nav.dart';
// import '../bloc/community_bloc.dart';
// import '../bloc/community_event.dart';
// import '../bloc/community_state.dart';
// import '../../../domain/community/entities/community_entities.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:nepika/core/config/env.dart';
// import 'dart:convert';

// class ThreadsProfilePage extends StatefulWidget {
//   const ThreadsProfilePage({super.key});

//   @override
//   State<ThreadsProfilePage> createState() => _ThreadsProfilePageState();
// }

// class _ThreadsProfilePageState extends State<ThreadsProfilePage>
//     with TickerProviderStateMixin {
//   // Controllers
//   late ScrollController _scrollController;
//   late PageController _feedPageController;
  
//   // Animation controllers
//   late AnimationController _nameTransitionController;
//   late Animation<double> _nameOpacity;
  
//   // API integration state
//   String? profileUserId;
//   String? _currentUserId;
//   String? _token;
//   CommunityBloc? _communityBloc;
//   bool _isInitialized = false;

//   // State variables
//   int _activeTabIndex = 0;
//   bool _isNameInHeader = false;
//   bool _isBottomNavVisible = true;
//   double _lastScrollPosition = 0.0;
  
//   // Profile data
//   CommunityProfileEntity? _profileData;
//   List<PostEntity> _threads = [];
//   List<PostEntity> _replies = [];
//   bool _loadingThreads = false;
//   bool _loadingReplies = false;
//   bool _hasMoreThreads = false;
//   bool _hasMoreReplies = false;
//   int _threadsPage = 1;
//   int _repliesPage = 1;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final args = ModalRoute.of(context)?.settings.arguments;
//     profileUserId = (args is Map<String, dynamic>)
//         ? args['userId'] as String? ?? 'Unknown'
//         : 'Unknown';

//     if (!_isInitialized && profileUserId != null && profileUserId != 'Unknown') {
//       _isInitialized = true;
//       _initializeData();
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _initializeControllers();
//     _setupAnimations();
//     _setupScrollListener();
//   }

//   void _initializeControllers() {
//     _scrollController = ScrollController();
//     _feedPageController = PageController(
//       initialPage: 0,
//       viewportFraction: 1.0, // Each page takes full width
//     );
//     _nameTransitionController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//   }

//   void _setupAnimations() {
//     _nameOpacity = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _nameTransitionController,
//       curve: Curves.easeInOut,
//     ));
//   }

//   void _setupScrollListener() {
//     _scrollController.addListener(() {
//       final scrollPosition = _scrollController.offset;
//       const nameTransitionThreshold = 180.0;
      
//       // Handle name transition
//       if (scrollPosition > nameTransitionThreshold && !_isNameInHeader) {
//         setState(() => _isNameInHeader = true);
//         _nameTransitionController.forward();
//       } else if (scrollPosition <= nameTransitionThreshold && _isNameInHeader) {
//         setState(() => _isNameInHeader = false);
//         _nameTransitionController.reverse();
//       }
      
//       // Handle bottom nav visibility
//       final scrollDelta = scrollPosition - _lastScrollPosition;
//       const scrollThreshold = 10.0;
      
//       if (scrollDelta > scrollThreshold && _isBottomNavVisible) {
//         setState(() => _isBottomNavVisible = false);
//       } else if (scrollDelta < -scrollThreshold && !_isBottomNavVisible) {
//         setState(() => _isBottomNavVisible = true);
//       }
      
//       _lastScrollPosition = scrollPosition;
//     });
//   }

//   void _onTabChanged(int index) {
//     if (_activeTabIndex != index) {
//       setState(() => _activeTabIndex = index);
//       _feedPageController.animateToPage(
//         index,
//         duration: const Duration(milliseconds: 250), // Faster animation
//         curve: Curves.easeOutCubic, // Smoother curve
//       );
      
//       // Load data if needed
//       if (index == 0 && _threads.isEmpty) {
//         _loadThreads();
//       } else if (index == 1 && _replies.isEmpty) {
//         _loadReplies();
//       }
//     }
//   }

//   void _onFeedPageChanged(int index) {
//     if (_activeTabIndex != index) {
//       setState(() => _activeTabIndex = index);
//     }
//   }

//   Future<void> _initializeData() async {
//     try {
//       final sharedPreferences = await SharedPreferences.getInstance();
//       await SharedPrefsHelper.init();
//       _token = sharedPreferences.getString(AppConstants.accessTokenKey);

//       // Get current user ID
//       final userDataString = sharedPreferences.getString(AppConstants.userDataKey);
//       if (userDataString != null) {
//         final userData = jsonDecode(userDataString);
//         _currentUserId = userData['id'];
//       }

//       if (_token != null && profileUserId != null) {
//         final apiBase = ApiBase();
//         final localDataSource = CommunityLocalDataSourceImpl();
//         final repository = CommunityRepositoryImpl(apiBase, localDataSource);
//         _communityBloc = CommunityBloc(repository);
        
//         // Fetch profile first
//         _communityBloc!.add(GetCommunityProfile(token: _token!, userId: profileUserId!));
        
//         setState(() {});
//       }
//     } catch (e) {
//       debugPrint("Error initializing ThreadsProfilePage: $e");
//     }
//   }

//   void _loadThreads() {
//     if (_communityBloc != null && _token != null && profileUserId != null) {
//       setState(() => _loadingThreads = true);
//       _communityBloc!.add(FetchUserThreads(
//         token: _token!,
//         userId: profileUserId!,
//       ));
//     }
//   }

//   void _loadReplies() {
//     if (_communityBloc != null && _token != null && profileUserId != null) {
//       setState(() => _loadingReplies = true);
//       _communityBloc!.add(FetchUserReplies(
//         token: _token!,
//         userId: profileUserId!,
//       ));
//     }
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _feedPageController.dispose();
//     _nameTransitionController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: Stack(
//         children: [
//           // Main scrollable content
//           CustomScrollView(
//             controller: _scrollController,
//             slivers: [
//               // Profile Header (Sticky Level 1)
//               SliverPersistentHeader(
//                 pinned: true,
//                 delegate: ProfileHeaderDelegate(
//                   userName: _profileData?.username ?? 'User',
//                   nameOpacity: _nameOpacity,
//                   onBackPressed: () => Navigator.pop(context),
//                   onMenuPressed: () => _showMenuOptions(),
//                 ),
//               ),
              
//               // Profile Info Section
//               SliverToBoxAdapter(
//                 child: ProfileInfo(
//                   profileData: widget.profileData,
//                   onEditProfile: _handleEditProfile,
//                   onShareProfile: _handleShareProfile,
//                 ),
//               ),
              
//               // Tabs Header (Sticky Level 2)
//               SliverPersistentHeader(
//                 pinned: true,
//                 delegate: TabsHeaderDelegate(
//                   activeIndex: _activeTabIndex,
//                   onTabChanged: _onTabChanged,
//                 ),
//               ),
              
//               // Feed Section with horizontal scrolling
//               SliverToBoxAdapter(
//                 child: SizedBox(
//                   height: MediaQuery.of(context).size.height - 300, // Adjust based on header heights
//                   child: FeedSection(
//                     pageController: _feedPageController,
//                     threads: _threads,
//                     replies: _replies,
//                     loadingThreads: _loadingThreads,
//                     loadingReplies: _loadingReplies,
//                     onPageChanged: _onFeedPageChanged,
//                     onLoadMoreThreads: _loadThreads,
//                     onLoadMoreReplies: _loadReplies,
//                   ),
//                 ),
//               ),
//             ],
//           ),
          
//           // Bottom Navigation with slide animation
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: BottomNav(
//               activeIndex: 4, // Profile tab is active
//               onTabSelected: (index) {
//                 // Handle navigation to other tabs
//               },
//               isVisible: _isBottomNavVisible,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showMenuOptions() {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.copy),
//               title: const Text('Copy link'),
//               onTap: () => Navigator.pop(context),
//             ),
//             ListTile(
//               leading: const Icon(Icons.report),
//               title: const Text('Report'),
//               onTap: () => Navigator.pop(context),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _handleEditProfile() {
//     // TODO: Navigate to edit profile page
//   }

//   void _handleShareProfile() {
//     // TODO: Implement share functionality
//   }
// }