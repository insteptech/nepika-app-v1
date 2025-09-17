import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/utils/shared_prefs_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';

class LikeButton extends StatefulWidget {
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
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> with TickerProviderStateMixin {
  bool _isLiked = false;
  int _likeCount = 0;
  Timer? _debounceTimer;
  String? _token;
  String? _userId;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialLikeStatus;
    _likeCount = widget.initialLikeCount;
    debugPrint('LikeButton: Initialized with postId: ${widget.postId}, initialLikeStatus: ${widget.initialLikeStatus}, initialLikeCount: ${widget.initialLikeCount}');
    _loadUserData();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Create pump animation (scale up then down)
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      await SharedPrefsHelper.init();
      _token = sharedPreferences.getString(AppConstants.accessTokenKey);
      final user = sharedPreferences.getString(AppConstants.userDataKey);

      if (user != null) {
        final userMap = jsonDecode(user);
        _userId = userMap['id']; // Extract just the string ID
        debugPrint(
          'LikeButton: Loaded user data - token: ${_token != null ? 'present' : 'null'}, userId: $_userId',
        );
      } else {
        debugPrint('LikeButton: No user data found');
      }
    } catch (e) {
      debugPrint('LikeButton: Error loading user data: $e');
    }
  }

  void _toggleLike() {
    if (_token == null || _userId == null) {
      debugPrint('LikeButton: Cannot toggle like - missing data');
      return;
    }

    // Cancel any existing timer
    _debounceTimer?.cancel();

    // Optimistically update UI with instant feedback
    final wasLiked = _isLiked;
    final previousCount = _likeCount;

    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
    });

    // Notify parent widget about the like status change
    widget.onLikeStatusChanged?.call(_isLiked, _likeCount);

    // Trigger pump animation only when liking
    if (_isLiked) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }

    // Debounce the API call (background operation)
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      try {
        final bloc = context.read<CommunityBloc>();
        if (_isLiked) {
          // Like the post
          bloc.add(LikePost(token: _token!, postId: widget.postId));
        } else {
          // Unlike the post
          bloc.add(UnlikePost(token: _token!, postId: widget.postId));
        }
      } catch (e) {
        debugPrint('LikeButton: Error dispatching event: $e');
        // Revert optimistic update on error
        if (mounted) {
          setState(() {
            _isLiked = wasLiked;
            _likeCount = previousCount;
          });

          // Notify parent widget about the reverted status
          widget.onLikeStatusChanged?.call(_isLiked, _likeCount);

          // Show error message if possible
          try {
            String errorMessage = 'Failed to update like status';
            
            // Check for specific error types
            if (e.toString().contains('500')) {
              errorMessage = 'Please create your community profile first to like posts';
            } else if (e.toString().contains('401') || e.toString().contains('403')) {
              errorMessage = 'Authentication error. Please log in again';
            } else if (e.toString().contains('404')) {
              errorMessage = 'Post not found';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          } catch (snackbarError) {
            debugPrint('LikeButton: Could not show snackbar: $snackbarError');
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggleLike,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: _isLiked
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
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium!.primary(context).color,
                        ),
                );
              },
            ),
            if (widget.showCount) ...[
              const SizedBox(width: 4),
              Text(
                _formatLikeCount(_likeCount),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
