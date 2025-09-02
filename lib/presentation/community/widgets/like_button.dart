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

  const LikeButton({
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
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLoading = false;
  Timer? _debounceTimer;
  String? _token;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialLikeStatus;
    _likeCount = widget.initialLikeCount;
    _loadUserData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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
    if (_isLoading || _token == null || _userId == null) {
      debugPrint('LikeButton: Cannot toggle like - missing data or loading');
      return;
    }

    // Cancel any existing timer
    _debounceTimer?.cancel();

    // Optimistically update UI
    final wasLiked = _isLiked;
    final previousCount = _likeCount;

    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
      _isLoading = true;
    });

    // Debounce the API call
    _debounceTimer = Timer(const Duration(seconds: 1), () async {
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

        // Wait a bit for the API call, then reset loading state
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('LikeButton: Error dispatching event: $e');
        // Revert optimistic update on error
        if (mounted) {
          setState(() {
            _isLiked = wasLiked;
            _likeCount = previousCount;
            _isLoading = false;
          });

          // Show error message if possible
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to ${_isLiked ? 'like' : 'unlike'} post'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
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
    return GestureDetector(
      onTap: _toggleLike,
      child: Container(
        padding: const EdgeInsets.all(0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: _isLoading ? 0.5 : 1.0,
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
                ),
                if (_isLoading)
                  SizedBox(
                    width: widget.size! * 0.6,
                    height: widget.size! * 0.6,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.activeColor ?? Colors.red,
                      ),
                    ),
                  ),
              ],
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
