import 'package:flutter/material.dart';
import '../../../core/services/recent_searches_service.dart';
import '../../../domain/community/entities/community_entities.dart';
import '../../../core/config/constants/routes.dart';

/// Recent searches view component showing saved user searches
/// Follows existing profile result structure with remove functionality
class RecentSearchesView extends StatefulWidget {
  final String token;
  final VoidCallback? onRecentSearchSelected;

  const RecentSearchesView({
    super.key,
    required this.token,
    this.onRecentSearchSelected,
  });

  @override
  State<RecentSearchesView> createState() => _RecentSearchesViewState();
}

class _RecentSearchesViewState extends State<RecentSearchesView> {
  List<UserSearchResultEntity> _recentSearches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final searches = await RecentSearchesService.getRecentSearches();
      if (mounted) {
        setState(() {
          _recentSearches = searches;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('RecentSearchesView: Error loading recent searches: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeRecentSearch(String userId) async {
    await RecentSearchesService.removeRecentSearch(userId);
    await _loadRecentSearches(); // Refresh the list
  }

  Future<void> _clearAllRecentSearches() async {
    await RecentSearchesService.clearAllRecentSearches();
    await _loadRecentSearches(); // Refresh the list
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Recent Searches'),
        content: const Text('Are you sure you want to clear all recent searches?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllRecentSearches();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_recentSearches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No recent searches',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header with Clear All button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent searches',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              TextButton(
                onPressed: _showClearConfirmation,
                child: Text(
                  'Clear all',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Recent searches list
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final user = _recentSearches[index];
              return _RecentSearchCard(
                user: user,
                onRemove: () => _removeRecentSearch(user.id),
                onTap: () {
                  widget.onRecentSearchSelected?.call();
          Navigator.of(context, rootNavigator: true).pushNamed(
            AppRoutes.communityUserProfile,
            arguments: {'userId': user.id},
          );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Recent search card component following existing profile result structure
class _RecentSearchCard extends StatelessWidget {
  final UserSearchResultEntity user;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _RecentSearchCard({
    required this.user,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                // User Avatar
                _RecentSearchImageIcon(user: user),
                const SizedBox(width: 12),

                // User Info (expandable)
                Expanded(
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
                    ],
                  ),
                ),

                // Remove button
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey[600],
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// User image icon for recent searches (reuses existing pattern)
class _RecentSearchImageIcon extends StatelessWidget {
  final UserSearchResultEntity user;

  const _RecentSearchImageIcon({required this.user});

  @override
  Widget build(BuildContext context) {
    final profileImageUrl = user.profileImageUrl ?? '';
    final hasValidUrl = profileImageUrl.isNotEmpty;

    return CircleAvatar(
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
    );
  }
}