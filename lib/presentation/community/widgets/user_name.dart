import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/domain/community/entities/community_entities.dart';
import 'package:nepika/presentation/community/pages/user_profile.dart';

class UserNameWithNavigation extends StatelessWidget {
  final PostEntity? post;
  final PostDetailEntity? postDetail;

  const UserNameWithNavigation({super.key, this.post, this.postDetail});

  @override
  Widget build(BuildContext context) {
    final fullName =
        post?.author.fullName ?? postDetail?.author.fullName ?? 'User';

    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.communityUserProfile,
            arguments: {'userId': post?.author.id ?? postDetail?.author.id},
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fullName,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
