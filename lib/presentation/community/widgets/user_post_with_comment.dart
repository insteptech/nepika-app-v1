import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/utils/shared_prefs_helper.dart';
import 'package:nepika/domain/community/entities/community_entities.dart';
import 'package:nepika/presentation/community/pages/post_detail_page_integration.dart';
import 'package:nepika/presentation/community/widgets/like_comment_share_row.dart';
import 'package:nepika/presentation/community/widgets/user_icon.dart';
import 'package:nepika/presentation/community/widgets/user_name.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPostWithComment extends StatefulWidget {
  final PostDetailEntity? thread;
  final String? token;
  final String? userId;
  final ReplyEntity? reply;

  const UserPostWithComment({
    super.key,
    this.thread,
    this.token,
    this.userId,
    this.reply,
  });

  @override
  State<UserPostWithComment> createState() => _UserPostWithCommentState();
}

class _UserPostWithCommentState extends State<UserPostWithComment> {
  bool get isLiked {
    return widget.thread!.likes.any((like) => like.userId == widget.userId);
  }

  String _timeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.thread!;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                UserImageIcon(author: post.author),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 3,
                  height: 63,
                  color: Theme.of(context).textTheme.bodyMedium!
                      .secondary(context)
                      .color!
                      .withValues(alpha: 0.2),
                ),
              ],
            ),

            SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        post.author.fullName,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),

                      Text(
                        _timeAgo(post.createdAt),
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodyMedium!
                            .secondary(context)
                            .copyWith(fontWeight: FontWeight.w300),
                      ),

                      const SizedBox(width: 10),

                      Icon(
                        Icons.more_horiz,
                        size: 22,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),

                  GestureDetector(
                    onTap: () async {
                      final sharedPreferences =
                          await SharedPreferences.getInstance();
                      await SharedPrefsHelper.init();
                      final token = sharedPreferences.getString(
                        AppConstants.accessTokenKey,
                      );

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PostDetailPageIntegration(
                            token: token!,
                            postId: post.postId,
                            userId: post.author.id,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      post.content,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w300),
                    ),
                  ),

                  const SizedBox(height: 15),
                  LikeCommentShareRow(
                    postId: post.postId,
                    initialLikeStatus: isLiked,
                    initialLikeCount: post.likeCount,
                    size: 18,
                    activeColor: Colors.red,
                    showCount: false,
                  ),
                  const SizedBox(height: 10),
                  post.likeCount > 0
                      ? Text(
                          "${post.likeCount} ${post.likeCount == 1 ? 'Like' : 'Likes'}",
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium!.secondary(context),
                        )
                      : const SizedBox.shrink(),

                  Text(
                    '${post.commentCount} replies',
                    textAlign: TextAlign.start,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium!.secondary(context),
                  ),

                  SizedBox(height: 5)
                ],
              ),
            ),
          ],
        ),

        // SizedBox(
        //   width: double.infinity,
        //   child: Text(
        //     '${post.commentCount} replies',
        //     textAlign: TextAlign.start,
        //     style: Theme.of(
        //       context,
        //     ).textTheme.headlineMedium!.secondary(context),
        //   ),
        // ),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserImageIcon(author: post.author),

            SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        post.author.fullName,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),

                      Text(
                        _timeAgo(post.createdAt),
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodyMedium!
                            .secondary(context)
                            .copyWith(fontWeight: FontWeight.w300),
                      ),

                      const SizedBox(width: 10),

                      Icon(
                        Icons.more_horiz,
                        size: 22,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),

                  GestureDetector(
                    onTap: () async {
                      final sharedPreferences =
                          await SharedPreferences.getInstance();
                      await SharedPrefsHelper.init();
                      final token = sharedPreferences.getString(
                        AppConstants.accessTokenKey,
                      );

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PostDetailPageIntegration(
                            token: token!,
                            postId: post.postId,
                            userId: post.author.id,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      post.content,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w300),
                    ),
                  ),

                  const SizedBox(height: 15),
                  LikeCommentShareRow(
                    postId: post.postId,
                    initialLikeStatus: isLiked,
                    initialLikeCount: post.likeCount,
                    size: 18,
                    activeColor: Colors.red,
                    showCount: false,
                  ),
                  const SizedBox(height: 10),
                  post.likeCount > 0
                      ? Text(
                          "${post.likeCount} ${post.likeCount == 1 ? 'Like' : 'Likes'}",
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium!.secondary(context),
                        )
                      : const SizedBox.shrink(),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
