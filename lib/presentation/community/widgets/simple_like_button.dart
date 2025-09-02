import 'package:flutter/material.dart';

class SimpleLikeButton extends StatefulWidget {
  final String postId;
  final bool initialLikeStatus;
  final int initialLikeCount;
  final double? size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showCount;

  const SimpleLikeButton({
    super.key,
    required this.postId,
    required this.initialLikeStatus,
    required this.initialLikeCount,
    this.size = 22,
    this.activeColor = Colors.red,
    this.inactiveColor,
    this.showCount = false,
  });

  @override
  State<SimpleLikeButton> createState() => _SimpleLikeButtonState();
}

class _SimpleLikeButtonState extends State<SimpleLikeButton> {
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialLikeStatus;
    _likeCount = widget.initialLikeCount;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
    });
    
    // Show a simple message for now
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isLiked ? 'Post liked!' : 'Post unliked!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleLike,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isLiked
                ? Image.asset(
                    'assets/icons/filled/heart_icon.png',
                    width: widget.size,
                    height: widget.size,
                    color: widget.activeColor,
                  )
                : Image.asset(
                    'assets/icons/heart_icon.png',
                    width: widget.size,
                    height: widget.size,
                    color: widget.inactiveColor ?? Colors.grey[700],
                  ),
            if (widget.showCount) ...[
              const SizedBox(width: 4),
              Text(
                _formatLikeCount(_likeCount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatLikeCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
