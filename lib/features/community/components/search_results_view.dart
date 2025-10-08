import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/community/entities/community_entities.dart';
import '../bloc/blocs/user_search_bloc.dart';
import '../bloc/events/user_search_event.dart';
import '../bloc/states/user_search_state.dart';
import 'search_skeleton_loader.dart';
import 'user_search_card.dart';
import 'recent_searches_view.dart';

/// Search results view component handling different search states
/// Follows Single Responsibility Principle - only handles search results display
class SearchResultsView extends StatefulWidget {
  final TextEditingController searchController;
  final String token;

  const SearchResultsView({
    super.key,
    required this.searchController,
    required this.token,
  });

  @override
  State<SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends State<SearchResultsView> {
  List<UserSearchResultEntity>? _lastSearchResults;

  bool get _hasActiveSearch => widget.searchController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 160,
      child: BlocBuilder<UserSearchBloc, UserSearchState>(
        builder: (context, state) {
          // Show recent searches when no active search and no current search state
          if (!_hasActiveSearch && state is! UserSearchV2Loading && state is! UserSearchV2Loaded && state is! UserSearchV2Error) {
            return RecentSearchesView(
              token: widget.token,
              onRecentSearchSelected: () {
                // Clear search when user selects from recent searches
                widget.searchController.clear();
              },
            );
          }

          if (state is UserSearchV2Loading) {
            return const SearchSkeletonLoader();
          } else if (state is UserSearchV2Loaded) {
            // Store the search results for follow actions
            _lastSearchResults = state.users;
            
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
                return UserSearchCard(
                  user: user,
                  token: widget.token,
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
                      final query = widget.searchController.text.trim();
                      if (query.isNotEmpty) {
                        context.read<UserSearchBloc>().add(
                          SearchUsersV2(
                            token: widget.token,
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
          } else if (state is UserFollowToggling || 
                     state is UserFollowToggled || 
                     state is UserFollowError) {
            // For follow states, preserve the last search results
            if (_lastSearchResults != null && _lastSearchResults!.isNotEmpty) {
              return ListView.builder(
                itemCount: _lastSearchResults!.length,
                itemBuilder: (context, index) {
                  final user = _lastSearchResults![index];
                  return UserSearchCard(
                    user: user,
                    token: widget.token,
                  );
                },
              );
            }
            // If no previous results and no active search, show recent searches
            if (!_hasActiveSearch) {
              return RecentSearchesView(
                token: widget.token,
                onRecentSearchSelected: () {
                  widget.searchController.clear();
                },
              );
            }
            // If active search but no results, show empty state
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
          } else {
            // Default state - show recent searches if no active search
            if (!_hasActiveSearch) {
              return RecentSearchesView(
                token: widget.token,
                onRecentSearchSelected: () {
                  widget.searchController.clear();
                },
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
    );
  }
}