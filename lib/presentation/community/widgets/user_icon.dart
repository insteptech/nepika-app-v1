import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/domain/community/entities/community_entities.dart';

class UserImageIcon extends StatelessWidget {
  final AuthorEntity author;
  
  final int padding;

  const UserImageIcon({
    super.key,
    required this.author,
    this.padding = 0,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = author.avatarUrl;

    return GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.communityUserProfile,
            arguments: {'userId': author.id},
          );
        },  
      child: Container(
        height: 40,
        width: 40,
        margin: EdgeInsets.all(padding.toDouble()),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary,
        ),
        child: avatarUrl.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  avatarUrl,
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        'assets/images/user_default_image_1.png',
                        height: 10,
                        color: Theme.of(context).colorScheme.onSecondary,
                        fit: BoxFit.scaleDown,
                      ),
                    );
                  },
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  'assets/images/nepika_logo_image.png',
                  height: 10,
                  color: Theme.of(context).colorScheme.onSecondary,
                  fit: BoxFit.scaleDown,
                ),
              ),
      ),
    );
  }
}
