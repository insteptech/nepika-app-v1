import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/domain/community/entities/community_entities.dart';

class UserNameWithNavigation extends StatelessWidget {
  final PostEntity? post;
  final PostDetailEntity? postDetail;

  const UserNameWithNavigation({super.key, this.post, this.postDetail});

  @override
  Widget build(BuildContext context) {
    final fullName = post?.username ?? postDetail?.author.fullName ?? 'User';
    final userId = post?.userId ?? postDetail?.author.id;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.communityUserProfile,
            arguments: {'userId': userId},
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
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
