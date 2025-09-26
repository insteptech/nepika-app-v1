import 'dart:async';
import 'package:flutter/material.dart';
import '../managers/like_state_manager.dart';

/// Universal like state listener widget for 100% consistent like synchronization
/// Automatically subscribes to LikeStateManager and updates UI when like state changes
/// This ensures all instances of the same post across all screens stay synchronized
class LikeStateListener extends StatefulWidget {
  final String postId;
  final Widget Function(BuildContext context, LikeState? likeState) builder;
  
  const LikeStateListener({
    super.key,
    required this.postId,
    required this.builder,
  });

  @override
  State<LikeStateListener> createState() => _LikeStateListenerState();
}

class _LikeStateListenerState extends State<LikeStateListener> {
  final LikeStateManager _likeStateManager = LikeStateManager();
  LikeState? _currentLikeState;
  StreamSubscription<LikeStateEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    
    // Get initial state
    _currentLikeState = _likeStateManager.getLikeState(widget.postId);
    
    // Subscribe to state changes for this specific post
    _subscription = _likeStateManager.stateStream
        .where((event) => event.postId == widget.postId)
        .listen((event) {
      if (mounted) {
        setState(() {
          _currentLikeState = event.state;
        });
      }
    });
  }

  @override
  void didUpdateWidget(LikeStateListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If postId changed, update subscription
    if (oldWidget.postId != widget.postId) {
      _subscription?.cancel();
      _currentLikeState = _likeStateManager.getLikeState(widget.postId);
      
      _subscription = _likeStateManager.stateStream
          .where((event) => event.postId == widget.postId)
          .listen((event) {
        if (mounted) {
          setState(() {
            _currentLikeState = event.state;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _currentLikeState);
  }
}

/// Simplified like button that uses LikeStateListener for automatic synchronization
/// Provides consistent UI and behavior across all screens
class UniversalLikeButton extends StatefulWidget {
  final String postId;
  final bool fallbackLikeStatus;
  final int fallbackLikeCount;
  final double? size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showCount;
  final EdgeInsets padding;
  final Function()? onLikePressed;

  const UniversalLikeButton({
    super.key,
    required this.postId,
    required this.fallbackLikeStatus,
    required this.fallbackLikeCount,
    this.size = 28,
    this.activeColor = Colors.red,
    this.inactiveColor,
    this.showCount = true,
    this.padding = const EdgeInsets.all(6.0),
    this.onLikePressed,
  });

  @override
  State<UniversalLikeButton> createState() => _UniversalLikeButtonState();
}

class _UniversalLikeButtonState extends State<UniversalLikeButton> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  
  // Local UI state for instant feedback
  bool? _localLikeStatus;
  int? _localLikeCount;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller for Instagram-style bounce
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Create bounce animation sequence
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    ));
    
    _bounceAnimation = Tween<double>(
      begin: 1.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.bounceOut),
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _triggerLikeAnimation() {
    // Clear any existing animation and start fresh
    _animationController.stop();
    _animationController.reset();
    
    // Start bounce animation on every tap
    _animationController.forward().then((_) {
      _animationController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LikeStateListener(
      postId: widget.postId,
      builder: (context, likeState) {
        // Initialize state if it doesn't exist
        if (likeState == null) {
          final likeStateManager = LikeStateManager();
          likeStateManager.initializePostState(
            postId: widget.postId,
            isLiked: widget.fallbackLikeStatus,
            likeCount: widget.fallbackLikeCount,
          );
        }
        
        // Sync local state with server response (when server confirms)
        if (likeState != null && likeState.source == LikeStateSource.server) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_localLikeStatus != null && _localLikeStatus != likeState.isLiked) {
              // Server response differs from local state, sync it
              setState(() {
                _localLikeStatus = null; // Reset to use server state
                _localLikeCount = null;
              });
            }
          });
        }
        
        // Use local state for instant UI feedback, fall back to global state
        final isLiked = _localLikeStatus ?? (likeState?.isLiked ?? widget.fallbackLikeStatus);
        final likeCount = _localLikeCount ?? (likeState?.likeCount ?? widget.fallbackLikeCount);
        final isLoading = likeState?.isLoading ?? false;
        final hasError = likeState?.error != null;
        
        // Animation will be triggered by tap gesture directly
        
        return GestureDetector(
          onTap: () {
            // Trigger bounce animation immediately on every tap
            _triggerLikeAnimation();
            
            // Toggle local state immediately for instant UI feedback
            setState(() {
              final currentIsLiked = _localLikeStatus ?? isLiked;
              final currentLikeCount = _localLikeCount ?? likeCount;
              
              _localLikeStatus = !currentIsLiked;
              _localLikeCount = _localLikeStatus! ? currentLikeCount + 1 : currentLikeCount - 1;
            });
            
            // Call the like toggle function (background processing)
            widget.onLikePressed?.call();
          },
          child: Padding(
            padding: widget.padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Heart icon with loading/error states
                _buildHeartIcon(
                  isLiked: isLiked,
                  isLoading: isLoading,
                  hasError: hasError,
                  context: context,
                ),
                
                if (widget.showCount) ...[
                  const SizedBox(width: 6),
                  _buildLikeCount(
                    likeCount: likeCount,
                    isLoading: isLoading,
                    hasError: hasError,
                    context: context,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeartIcon({
    required bool isLiked,
    required bool isLoading,
    required bool hasError,
    required BuildContext context,
  }) {
    // No loading indicator needed - background processing is seamless

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Combine scale and bounce for smooth animation
        double scale = 1.0;
        if (_animationController.value <= 0.5) {
          scale = _scaleAnimation.value;
        } else {
          scale = _bounceAnimation.value;
        }
        
        return Transform.scale(
          scale: scale,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(isLiked),
              size: widget.size,
              color: isLiked
                  ? (widget.activeColor ?? Colors.red)
                  : (hasError 
                      ? Colors.grey.withValues(alpha: 0.5)
                      : (widget.inactiveColor ?? Theme.of(context).iconTheme.color)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLikeCount({
    required int likeCount,
    required bool isLoading,
    required bool hasError,
    required BuildContext context,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(
        _formatLikeCount(likeCount),
        key: ValueKey(likeCount),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: hasError 
              ? Colors.grey.withValues(alpha: 0.5)
              : Theme.of(context).textTheme.bodySmall?.color,
          fontWeight: isLoading ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  String _formatLikeCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}

/// Mixin for widgets that need to trigger like actions
/// Provides consistent like handling across all components
mixin LikeActionMixin {
  /// Toggle like status for a post
  /// This automatically syncs across all UI components
  Future<void> toggleLike({
    required String postId,
    required bool currentLikeStatus,
    required int currentLikeCount,
    Function(String)? onError,
  }) async {
    final likeStateManager = LikeStateManager();
    
    await likeStateManager.toggleLike(
      postId: postId,
      currentLikeStatus: currentLikeStatus,
      currentLikeCount: currentLikeCount,
      onError: onError,
    );
  }
}

/// Widget that provides like functionality with automatic state management
/// Use this as a replacement for all existing like buttons
class SynchronizedLikeButton extends StatelessWidget with LikeActionMixin {
  final String postId;
  final bool fallbackLikeStatus;
  final int fallbackLikeCount;
  final double? size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showCount;
  final EdgeInsets padding;
  final Function(String)? onError;

  const SynchronizedLikeButton({
    super.key,
    required this.postId,
    required this.fallbackLikeStatus,
    required this.fallbackLikeCount,
    this.size = 24,
    this.activeColor = Colors.red,
    this.inactiveColor,
    this.showCount = true,
    this.padding = const EdgeInsets.all(8.0),
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return UniversalLikeButton(
      postId: postId,
      fallbackLikeStatus: fallbackLikeStatus,
      fallbackLikeCount: fallbackLikeCount,
      size: size,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      showCount: showCount,
      padding: padding,
      onLikePressed: () async {
        final likeStateManager = LikeStateManager();
        final currentState = likeStateManager.getLikeState(postId);
        
        await toggleLike(
          postId: postId,
          currentLikeStatus: currentState?.isLiked ?? fallbackLikeStatus,
          currentLikeCount: currentState?.likeCount ?? fallbackLikeCount,
          onError: onError,
        );
      },
    );
  }
}