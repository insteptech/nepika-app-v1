import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/features/dashboard/widgets/dashboard_navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../bloc/notification_bloc.dart';
import '../bloc/notification_state.dart';
import '../bloc/notification_event.dart';
import '../widgets/notification_item.dart';
import '../widgets/notification_filter_tabs.dart';
import '../../../domain/notifications/entities/notification_entities.dart';
import '../../../core/widgets/back_button.dart';
import '../../../core/config/constants/app_constants.dart';
import '../../community/utils/community_navigation.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  // ------------------------------------------------------------
  // USER DATA
  // ------------------------------------------------------------

  String? _token;
  String? _userId;

  // ------------------------------------------------------------
  // NAVBAR ANIMATION
  // ------------------------------------------------------------

  late AnimationController _navBarAnimationController;
  late Animation<double> _navBarAnimation;

  bool _isNavBarVisible = true;
  final double _scrollThreshold = 10.0;

  // ------------------------------------------------------------
  // SCROLL CONTROLLER
  // ------------------------------------------------------------
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  final ScrollController _scrollController = ScrollController();
  double _lastOffset = 0.0;

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _loadUserData();
    _initializeNavBarAnimation();

    _scrollController.addListener(_onScroll);

    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      try {
        final bloc = context.read<NotificationBloc>();
        final state = bloc.state;



        int unread = 0;

        if (state is NotificationLoaded) unread = state.unreadCount;
        if (state is NotificationDisconnected) unread = state.unreadCount;

        if (unread > 0) {
          bloc.add(const MarkAllNotificationsAsSeen());
        }
      } catch (e) {
        debugPrint('Error marking notifications as seen: $e');
      }
    });
  }

  @override
  void dispose() {
    _navBarAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // NAVBAR ANIMATION SETUP
  // ------------------------------------------------------------

  void _initializeNavBarAnimation() {
    _navBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );

    _navBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _navBarAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // CRITICAL FIX: Initialize animation to forward (visible) state
    _navBarAnimationController.value = 1.0;
  }

  // ------------------------------------------------------------
  // SCROLL LOGIC
  // ------------------------------------------------------------

  void _onScroll() {
    if (!mounted) return;

    double offset = _scrollController.offset;
    double delta = offset - _lastOffset;

    // Only trigger animation if scroll delta exceeds threshold
    if (delta.abs() > _scrollThreshold) {
      if (delta > 0) {
        // scrolling DOWN → hide
        if (_isNavBarVisible) {
          setState(() => _isNavBarVisible = false);
          _navBarAnimationController.reverse();
        }
      } else {
        // scrolling UP → show
        if (!_isNavBarVisible) {
          setState(() => _isNavBarVisible = true);
          _navBarAnimationController.forward();
        }
      }
      _lastOffset = offset;
    }
  }

  // ------------------------------------------------------------
  // NAVBAR UI
  // ------------------------------------------------------------

  Widget _buildAnimatedNavBar() {
    return SizeTransition(
      sizeFactor: _navBarAnimation,
      axisAlignment: -1.0, // Anchor animation to bottom
      child: Container(
        height: 80,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: DashboardNavBar(
          selectedIndex: 2,
          onNavBarTap: _onNavBarTap,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // NAVIGATION
  // ------------------------------------------------------------


  String _currentRoute = AppRoutes.communityHome;
  void _onNavBarTap(int index, String route) {
    if (route == AppRoutes.cameraScanGuidence) {
      Navigator.of(context).pushNamed(AppRoutes.cameraScanGuidence);
      return;
    }

    _resetNavBarVisibility();
    setState(() {
      _currentRoute = route;
    });
    
    // Navigator.pushNamed(context, route);

    _navigatorKey.currentState?.pushNamed(route);
  }


  void _resetNavBarVisibility() {
    if (!_isNavBarVisible) {
      setState(() {
        _isNavBarVisible = true;
      });
      _navBarAnimationController.forward();
    }
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: _buildAnimatedNavBar(),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Sticky Activity Header
            SliverPersistentHeader(
              pinned: true,
              delegate: _ActivityHeaderDelegate(
                minHeight: 50,
                maxHeight: 70,
                theme: theme,
              ),
            ),

            // Filter Tabs
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterTabsDelegate(
                height: 60,
                theme: theme,
              ),
            ),

            // NOTIFICATIONS LIST
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                if (state is NotificationLoading ||
                    state is NotificationConnecting) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is NotificationError) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text("Error loading notifications")),
                  );
                }

                List<NotificationEntity> list = [];
                if (state is NotificationLoaded) {
                  list = state.filteredNotifications;
                }
                if (state is NotificationDisconnected) {
                  list = state.notifications;
                }

                if (list.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text("No notifications yet")),
                  );
                }

                return SliverList.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    return NotificationItem(
                      notification: list[i],
                      onTap: () => _handleNotificationTap(list[i]),
                    );
                  },
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // LOAD USER DATA
  // ------------------------------------------------------------

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.accessTokenKey);
      final userData = prefs.getString(AppConstants.userDataKey);

      if (token != null && userData != null) {
        final user = jsonDecode(userData);
        if (mounted) {
          setState(() {
            _token = token;
            _userId = user["id"]?.toString();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // ------------------------------------------------------------
  // NOTIFICATION TAP HANDLER
  // ------------------------------------------------------------

  void _handleNotificationTap(NotificationEntity n) {
    try {
      switch (n.type) {
        case NotificationType.like:
        case NotificationType.reply:
        case NotificationType.mention:
          if (n.postId != null) {
            CommunityNavigation.navigateToPostDetail(
              context,
              postId: n.postId!,
              token: _token,
              userId: _userId,
            );
          }
          break;

        case NotificationType.follow:
        case NotificationType.followRequest:
        case NotificationType.followRequestAccepted:
          CommunityNavigation.navigateToUserProfile(
            context,
            userId: n.actor.id,
          );
          break;

        default:
          break;
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }
}

// ------------------------------------------------------------
// HEADER DELEGATE - FIXED GEOMETRY
// ------------------------------------------------------------

class _ActivityHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final ThemeData theme;

  _ActivityHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.theme,
  });

  @override
  double get minExtent => minHeight;
  
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Calculate progress from 0.0 (expanded) to 1.0 (collapsed)
    final progress = (shrinkOffset / (maxHeight - minHeight)).clamp(0.0, 1.0);

    // Check if header is stuck to top
    final isStuckToTop = shrinkOffset > 0;

    // Responsive font sizes based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // Interpolate font size - responsive to screen size
    final maxFontSize = isSmallScreen ? 26.0 : 32.0;
    final minFontSize = isSmallScreen ? 20.0 : 24.0;
    final fontSize = maxFontSize - (progress * (maxFontSize - minFontSize));

    // Interpolate vertical padding
    final verticalPadding = 10.0 - (progress * 5.0);

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: verticalPadding,
      ),
      child: Row(
        children: [
          // Animated back button (appears when stuck)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isStuckToTop ? 40 : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isStuckToTop ? 1.0 : 0.0,
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: 40,
                child: CustomBackButton(
                  label: '',
                  iconSize: isSmallScreen ? 20 : 24,
                  iconColor: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          // Activity title
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Activity",
                style: TextStyle(
                  color: theme.textTheme.titleLarge?.color,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ActivityHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight;
  }
}

// ------------------------------------------------------------
// FILTER TABS DELEGATE - FIXED GEOMETRY
// ------------------------------------------------------------

class _FilterTabsDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final ThemeData theme;

  _FilterTabsDelegate({
    required this.height,
    required this.theme,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      color: theme.scaffoldBackgroundColor,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 20,
        vertical: isSmallScreen ? 8 : 10,
      ),
      child: const NotificationFilterTabs(),
    );
  }

  @override
  bool shouldRebuild(covariant _FilterTabsDelegate oldDelegate) {
    return height != oldDelegate.height;
  }
}