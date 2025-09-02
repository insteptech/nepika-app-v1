import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/presentation/community/widgets/like_button.dart';

class LikeCommentShareRow extends StatefulWidget {
  final String postId;
  final bool initialLikeStatus;
  final int initialLikeCount;
  final double? size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showCount;

  const LikeCommentShareRow({
    super.key,
    required this.postId,
    required this.initialLikeStatus,
    required this.initialLikeCount,
    this.size = 24,
    this.activeColor = Colors.red,
    this.inactiveColor,
    this.showCount = false,
  });


  @override
  State<LikeCommentShareRow> createState() => _LikeCommentShareRowState();
}

class _LikeCommentShareRowState extends State<LikeCommentShareRow> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        LikeButton(
          postId: widget.postId,
          initialLikeStatus: widget.initialLikeStatus,
          initialLikeCount: widget.initialLikeCount,
          size: widget.size,
          activeColor: widget.activeColor,
          showCount: widget.showCount,
        ),
        const SizedBox(width: 15),
        Image.asset(
          'assets/icons/comment_icon.png',
          height: 18,
          color: Theme.of(context).textTheme.bodyMedium!.primary(context).color,
        ),
        const SizedBox(width: 15),
        Image.asset(
          'assets/icons/send_icon.png',
          height: 16,
          color: Theme.of(context).textTheme.bodyMedium!.primary(context).color,
        ),
      ],
    );
  }
}
