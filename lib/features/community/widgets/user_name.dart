import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/domain/community/entities/community_entities.dart';
import 'package:nepika/features/community/widgets/professional_badge.dart';

class UserNameWithNavigation extends StatelessWidget {
  final PostEntity? post;
  final PostDetailEntity? postDetail;

  const UserNameWithNavigation({super.key, this.post, this.postDetail});

  @override
  Widget build(BuildContext context) {
    final fullName = post?.username ?? postDetail?.author.fullName ?? 'User';
    final userId = post?.userId ?? postDetail?.author.id;
    final isProfessional = post?.isSkincareProfessional ?? postDetail?.author.isSkincareProfessional ?? false;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context, rootNavigator: true).pushNamed(
            AppRoutes.communityUserProfile,
            arguments: {'userId': userId},
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    fullName,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isProfessional) const ProfessionalBadge(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}