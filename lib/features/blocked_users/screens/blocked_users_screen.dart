import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/constants/app_constants.dart';
import '../../../core/widgets/back_button.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../domain/blocked_users/entities/blocked_user_entities.dart';
import '../bloc/blocked_users_bloc.dart';
import '../bloc/blocked_users_event.dart';
import '../bloc/blocked_users_state.dart';
import '../widgets/blocked_user_item.dart';
import '../widgets/blocked_users_empty_state.dart';
import '../../routine/widgets/sticky_header_delegate.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _token;
  late BlockedUsersBloc _blockedUsersBloc;

  @override
  void initState() {
    super.initState();
    debugPrint('🔍 BlockedUsersScreen: initState called');
    
    // Initialize the bloc directly
    try {
      _blockedUsersBloc = di.sl<BlockedUsersBloc>();
      debugPrint('🔍 BlockedUsersScreen: Successfully created bloc instance: $_blockedUsersBloc');
    } catch (e) {
      debugPrint('🔍 BlockedUsersScreen: Error creating bloc: $e');
      rethrow;
    }
    
    // Add a small delay to ensure proper initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🔍 BlockedUsersScreen: Post frame callback - loading user data');
      _loadUserData();
    });
    
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _blockedUsersBloc.close();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      debugPrint('🔍 BlockedUsersScreen: Loading user data...');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.accessTokenKey);
      final userData = prefs.getString(AppConstants.userDataKey);

      debugPrint('🔍 BlockedUsersScreen: Token exists: ${token != null}, UserData exists: ${userData != null}');

      if (token != null && userData != null && mounted) {
        setState(() {
          _token = token;
        });

        // Fetch blocked users
        if (mounted) {
          debugPrint('🔍 BlockedUsersScreen: Dispatching FetchBlockedUsers event...');
          _blockedUsersBloc.add(FetchBlockedUsers(token: token));
          debugPrint('🔍 BlockedUsersScreen: Event dispatched successfully to direct bloc instance');
        }
      } else {
        debugPrint('🔍 BlockedUsersScreen: Missing token or userData, cannot fetch blocked users');
      }
    } catch (e) {
      debugPrint('🔍 BlockedUsersScreen: Error loading user data: $e');
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        // Load more when near bottom
        final state = _blockedUsersBloc.state;
        if (state is BlockedUsersLoaded && 
            state.hasMore && 
            !state.isLoadingMore &&
            _token != null) {
          _blockedUsersBloc.add(LoadMoreBlockedUsers(token: _token!));
        }
      }
    });
  }

  Future<void> _onRefresh() async {
    if (_token != null) {
      _blockedUsersBloc.add(RefreshBlockedUsers(token: _token!));
    }
  }

  void _handleUnblockUser(BlockedUserEntity user) {
    if (_token != null) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unblock User'),
          content: Text('Are you sure you want to unblock ${user.username ?? 'this user'}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _blockedUsersBloc.add(UnblockUser(
                  token: _token!,
                  userId: user.userId,
                  username: user.username ?? 'Unknown User',
                ));
              },
              child: const Text('Unblock'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider<BlockedUsersBloc>.value(
      value: _blockedUsersBloc,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: BlocConsumer<BlockedUsersBloc, BlockedUsersState>(
            listener: (context, state) {
              if (state is UserUnblocked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${state.username} has been unblocked'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else if (state is UnblockUserFailed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to unblock ${state.username}: ${state.error}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            builder: (context, state) {
              return _buildContent(context, state, theme);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, BlockedUsersState state, ThemeData theme) {
    // Extract state data
    List<BlockedUserEntity> users = [];
    int total = 0;
    bool isLoadingMore = false;
    String? unblockingUserId;
    bool isLoading = state is BlockedUsersLoading;
    bool isEmpty = state is BlockedUsersEmpty;
    bool isError = state is BlockedUsersError;

    if (state is BlockedUsersLoaded) {
      users = state.users;
      total = state.total;
      isLoadingMore = state.isLoadingMore;
    } else if (state is UnblockingUser) {
      users = state.currentUsers;
      unblockingUserId = state.userId;
      total = users.length;
    } else if (state is UserUnblocked) {
      users = state.updatedUsers;
      total = state.updatedTotal;
    } else if (state is UnblockUserFailed) {
      users = state.currentUsers;
      total = users.length;
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Initial back button area (same as add routine)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const CustomBackButton(),
                  const SizedBox(height: 15), // Same spacing as add routine
                ],
              ),
            ),
          ),
          
          // Sticky header (same config as add routine)
          SliverPersistentHeader(
            pinned: true,
            delegate: StickyHeaderDelegate(
              minHeight: 40, // Same as add routine
              maxHeight: 40, // Same as add routine
              isFirstHeader: true,
              title: "Blocked Users",
              child: Container(
                color: theme.scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.centerLeft,
                child: Text(
                  "Blocked Users",
                  style: theme.textTheme.displaySmall, // Same style as add routine
                ),
              ),
            ),
          ),

          // ALL content in ONE SliverToBoxAdapter (same pattern as add routine)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8), // Same spacing as add routine
                  
                  // Content based on state
                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (isEmpty)
                    const BlockedUsersEmptyState()
                  else if (isError)
                    Container(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      padding: const EdgeInsets.all(24.0),
                      child: () {
                        final errorState = state as BlockedUsersError;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              errorState.isNetworkError ? Icons.wifi_off : Icons.error_outline,
                              size: 64,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              errorState.isNetworkError ? 'No Internet Connection' : 'Something went wrong',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              errorState.message,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _onRefresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                            ),
                          ],
                        );
                      }(),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User count
                        Text(
                          total == 1 ? '1 blocked user' : '$total blocked users',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Users list
                        ...users.map((user) {
                          final isUnblocking = unblockingUserId == user.userId;
                          return BlockedUserItem(
                            user: user,
                            isUnblocking: isUnblocking,
                            onUnblock: () => _handleUnblockUser(user),
                          );
                        }),
                        
                        // Loading more indicator
                        if (isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
                  
                  const SizedBox(height: 100), // Same bottom spacing as add routine
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}