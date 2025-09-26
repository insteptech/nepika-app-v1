import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/constants/app_constants.dart';
import '../../../core/utils/shared_prefs_helper.dart';
import '../bloc/blocs/user_search_bloc.dart';
import '../bloc/events/user_search_event.dart';
import '../components/index.dart';
import '../utils/community_state_recovery_mixin.dart';

/// Independent User Search Screen
/// 
/// This screen can be used independently without requiring any parameters.
/// It automatically:
/// - Loads user token from SharedPreferences
/// - Uses existing UserSearchBloc from the context (provided by CommunityProviders)
/// - Handles all user search functionality with modular components
/// 
/// Usage Examples:
/// 
/// 1. Simple Navigation:
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(builder: (context) => const CommunitySearchScreen()),
/// );
/// ```
/// 
/// 2. Named Route:
/// ```dart
/// Navigator.of(context).pushNamed('/community-search');
/// ```
class CommunitySearchScreen extends StatefulWidget {
  const CommunitySearchScreen({super.key});

  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> with CommunityStateRecoveryMixin {
  final TextEditingController _searchController = TextEditingController();
  String? _token;
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
      context.read<UserSearchBloc>().add(ClearUserSearch());
      return;
    }
    
    // Start new debounce timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_token != null && query.isNotEmpty) {
        dispatchAfterListeners(() {
          debugPrint('CommunitySearchScreen: Dispatching search for query: "$query"');
          context.read<UserSearchBloc>().add(
            SearchUsersV2(token: _token!, query: query),
          );
        });
      }
    });
  }

  Future<void> _initializeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await SharedPrefsHelper.init();
      _token = prefs.getString(AppConstants.accessTokenKey);
      
      if (mounted) {
        setState(() {});
        
        // Try to recover existing user search state after token is loaded
        if (_token != null) {
          recoverStateAfterBuild(() {
            final stateRecovered = recoverUserSearchState((users) {
              debugPrint('CommunitySearchScreen: Recovered search state with ${users.length} users');
              // The SearchResultsView component will handle displaying the recovered users
            });
            
            if (stateRecovered) {
              debugPrint('CommunitySearchScreen: User search state recovered successfully');
            } else {
              debugPrint('CommunitySearchScreen: No existing user search state found');
            }
          });
        }
      }
    } catch (e) {
      debugPrint('CommunitySearchScreen: Error initializing data: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_token == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.onTertiary,
        appBar: AppBar(
          title: Text('Search', style: Theme.of(context).textTheme.bodyLarge),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.onTertiary,
          elevation: 0,
          leading: null,
          forceMaterialTransparency: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onTertiary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Sticky Header
            SliverPersistentHeader(
              pinned: true,
              delegate: SearchHeader(
                searchController: _searchController,
              ),
            ),
            
            // Search Results with error handling
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverToBoxAdapter(
                child: _token != null
                    ? SearchResultsView(
                        searchController: _searchController,
                        token: _token!,
                      )
                    : const Center(
                        child: Text('Unable to load search functionality'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}