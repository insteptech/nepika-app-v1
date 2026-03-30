import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/utils/debug_logger.dart';
import 'package:nepika/domain/community/entities/community_entities.dart';

class UserImageIcon extends StatelessWidget {
  final AuthorEntity author;
  final double size;
  final int padding;

  const UserImageIcon({
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
        onTap: () {
          Navigator.of(context, rootNavigator: true).pushNamed(
            AppRoutes.communityUserProfile,
            arguments: {'userId': author.id},
          );
        },
        borderRadius: BorderRadius.circular(20),
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
}