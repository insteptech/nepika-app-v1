import 'package:flutter/material.dart';
import 'package:nepika/core/utils/debug_logger.dart';
import '../../../../core/config/constants/routes.dart';
import '../../../../domain/community/entities/community_entities.dart';

/// User avatar widget with navigation to user profile
/// Follows Single Responsibility Principle - only handles user avatar display
class UserAvatar extends StatelessWidget {
  final AuthorEntity author;
  final double size;
  final int padding;

  const UserAvatar({
    super.key,
    required this.author,
    this.size = 40,
    this.padding = 0,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = author.avatarUrl;
    final hasValidUrl = avatarUrl.isNotEmpty;


   
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToProfile(context),
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          height: size,
          width: size,
          margin: EdgeInsets.all(padding.toDouble()),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasValidUrl 
                ? Colors.transparent 
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            border: Border.all(
              color: hasValidUrl 
                  ? Colors.transparent 
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: hasValidUrl
              ? ClipOval(
                  child: Image.network(
                    avatarUrl,
                    height: size,
                    width: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultIcon(context);
                    },
                  ),
                )
              : _buildDefaultIcon(context),
        ),
      ),
    );
  }

  Widget _buildDefaultIcon(BuildContext context) {
    return Center(
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
          Navigator.of(context, rootNavigator: true).pushNamed(
            AppRoutes.communityUserProfile,
            arguments: {'userId': author.id},
          );
  }
}