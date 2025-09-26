import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/constants/routes.dart';
import '../../../../domain/community/entities/community_entities.dart';
import '../bloc/blocs/user_search_bloc.dart';
import '../bloc/events/user_search_event.dart';
import '../bloc/states/user_search_state.dart';

/// User search result card component with follow functionality
/// Follows Single Responsibility Principle - only handles user card display and follow interaction
class UserSearchCard extends StatelessWidget {
  final UserSearchResultEntity user;
  final String token;

  const UserSearchCard({
    super.key,
    required this.user,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Navigable Avatar
          _UserSearchImageIcon(user: user),
          const SizedBox(width: 12),

          // Navigable User Info
          _UserSearchNameWithNavigation(user: user),

          // Follow Button - Only show if not self
          if (!user.isSelf)
            BlocBuilder<UserSearchBloc, UserSearchState>(
              builder: (context, state) {
                // Start with the user's initial following status from the entity
                bool isFollowing = user.isFollowing;
                bool isLoading = false;
                
                // Check if this specific user is in a loading state
                if (state is UserFollowToggling && state.userId == user.id) {
                  isLoading = true;
                } else if (state is UserFollowToggled && state.userId == user.id) {
                  // Update the following status based on the latest state
                  isFollowing = state.isFollowing;
                } else if (state is UserFollowError && state.userId == user.id) {
                  // Handle error state - the BLoC should have already reverted the state
                  isLoading = false;
                  // Keep the current isFollowing state from user entity
                }

                return GestureDetector(
                  onTap: isLoading ? null : () {
                    context.read<UserSearchBloc>().add(ToggleUserFollow(
                      token: token,
                      userId: user.id,
                      currentlyFollowing: isFollowing,
                    ));
                  },
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isFollowing ? Colors.grey[200] : Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isFollowing ? Colors.black : Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: TextStyle(
                                color: isFollowing ? Colors.black : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// User image icon with navigation functionality for search results
class _UserSearchImageIcon extends StatelessWidget {
  final UserSearchResultEntity user;

  const _UserSearchImageIcon({required this.user});

  @override
  Widget build(BuildContext context) {
    final profileImageUrl = user.profileImageUrl ?? '';
    final hasValidUrl = profileImageUrl.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.communityUserProfile,
            arguments: {'userId': user.id},
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: CircleAvatar(
          radius: 24,
          backgroundImage: hasValidUrl ? NetworkImage(profileImageUrl) : null,
          backgroundColor: hasValidUrl 
              ? Colors.transparent 
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          child: !hasValidUrl
              ? Text(
                  user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// User name with navigation functionality for search results
class _UserSearchNameWithNavigation extends StatelessWidget {
  final UserSearchResultEntity user;

  const _UserSearchNameWithNavigation({required this.user});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.communityUserProfile,
            arguments: {'userId': user.id},
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '@${user.username}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (user.isVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified,
                    size: 16,
                    color: Colors.blue,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${user.followersCount} followers',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            // const SizedBox(height: 2),
            // Text(
            //   'Joined ${_formatDate(user.createdAt)}',
            //   style: TextStyle(color: Colors.grey[600], fontSize: 12),
            // ),
          ],
        ),
      ),
    );
  }

}