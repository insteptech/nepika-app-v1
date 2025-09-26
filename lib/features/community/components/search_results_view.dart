import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/blocs/user_search_bloc.dart';
import '../bloc/events/user_search_event.dart';
import '../bloc/states/user_search_state.dart';
import 'search_skeleton_loader.dart';
import 'user_search_card.dart';

/// Search results view component handling different search states
/// Follows Single Responsibility Principle - only handles search results display
class SearchResultsView extends StatelessWidget {
  final TextEditingController searchController;
  final String token;

  const SearchResultsView({
    super.key,
    required this.searchController,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 160,
      child: BlocBuilder<UserSearchBloc, UserSearchState>(
        builder: (context, state) {
          if (state is UserSearchV2Loading) {
            return const SearchSkeletonLoader();
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
                return UserSearchCard(
                  user: user,
                  token: token,
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
                      final query = searchController.text.trim();
                      if (query.isNotEmpty) {
                        context.read<UserSearchBloc>().add(
                          SearchUsersV2(
                            token: token,
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