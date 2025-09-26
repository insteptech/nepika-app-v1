import 'package:flutter/material.dart';
import 'like_state_listener.dart';

class LikeButton extends StatelessWidget {
  final String postId;
  final bool initialLikeStatus;
  final int initialLikeCount;
  final double? size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showCount;
  final Function(bool isLiked, int newLikeCount)? onLikeStatusChanged;

  const LikeButton({
    super.key,
    required this.postId,
    required this.initialLikeStatus,
    required this.initialLikeCount,
    this.size = 24,
    this.activeColor = Colors.red,
    this.inactiveColor,
    this.showCount = false,
    this.onLikeStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LikeStateListener(
      postId: postId,
      builder: (context, likeState) {
        final currentIsLiked = likeState?.isLiked ?? initialLikeStatus;
        final currentLikeCount = likeState?.likeCount ?? initialLikeCount;
        
        return SynchronizedLikeButton(
          postId: postId,
          fallbackLikeStatus: currentIsLiked,
          fallbackLikeCount: currentLikeCount,
          size: size,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          showCount: showCount,
          padding: const EdgeInsets.all(8.0),
          onError: (error) {
            try {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            } catch (e) {
              debugPrint('LikeButton: Could not show snackbar: $e');
            }
          },
        );
      },
    );
  }
}