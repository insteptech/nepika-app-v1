import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/presentation/community/widgets/like_button.dart';
import 'package:nepika/presentation/community/pages/post_detail_page_integration.dart';

class LikeCommentShareRow extends StatefulWidget {
  final String postId;
  final bool initialLikeStatus;
  final int initialLikeCount;
  final double? size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showCount;
  final String? token;
  final String? userId;
  final Function(bool isLiked, int newLikeCount)? onLikeStatusChanged;
  final bool? currentLikeStatus;
  final int? currentLikeCount;

  const LikeCommentShareRow({
    super.key,
    required this.postId,
    required this.initialLikeStatus,
    required this.initialLikeCount,
    this.size = 24,
    this.activeColor = Colors.red,
    this.inactiveColor,
    this.showCount = false,
    this.token,
    this.userId,
    this.onLikeStatusChanged,
    this.currentLikeStatus,
    this.currentLikeCount,
  });


  @override
  State<LikeCommentShareRow> createState() => _LikeCommentShareRowState();
}

class _LikeCommentShareRowState extends State<LikeCommentShareRow> {
  void _onLikeStatusChanged(bool isLiked, int newLikeCount) {
    widget.onLikeStatusChanged?.call(isLiked, newLikeCount);
  }

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
          onLikeStatusChanged: _onLikeStatusChanged,
        ),
        InkWell(
          onTap: () {
            if (widget.token != null && widget.userId != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PostDetailPageIntegration(
                    token: widget.token!,
                    postId: widget.postId,
                    userId: widget.userId!,
                    currentLikeStatus: widget.currentLikeStatus ?? widget.initialLikeStatus,
                    currentLikeCount: widget.currentLikeCount ?? widget.initialLikeCount,
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              'assets/icons/comment_icon.png',
              height: 18,
              color: Theme.of(context).textTheme.bodyMedium!.primary(context).color,
            ),
          ),
        ),
        InkWell(
          onTap: () {
            // Share functionality
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              'assets/icons/send_icon.png',
              height: 16,
              color: Theme.of(context).textTheme.bodyMedium!.primary(context).color,
            ),
          ),
        ),
      ],
    );
  }
}
