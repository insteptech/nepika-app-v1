import 'package:flutter/material.dart';

/// Reusable shimmer overlay widget for image analysis states
class ShimmerOverlay extends StatefulWidget {
  final bool isActive;
  final bool showCompletion;
  final Duration duration;
  final List<Color> colors;
  final Widget? child;
  final VoidCallback? onCompletionFinished;

  const ShimmerOverlay({
    super.key,
    required this.isActive,
    this.showCompletion = false,
    this.duration = const Duration(milliseconds: 1800),
    this.colors = const [
      Colors.transparent,
      Colors.white10,
      Colors.white24,
      Colors.white38,
      Colors.white24,
      Colors.white10,
      Colors.transparent,
    ],
    this.child,
    this.onCompletionFinished,
  });

  @override
  State<ShimmerOverlay> createState() => _ShimmerOverlayState();
}

class _ShimmerOverlayState extends State<ShimmerOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _completionController;
  late Animation<double> _completionAnimation;
  bool _showingCompletion = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    // Completion animation controller
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _completionAnimation = CurvedAnimation(
      parent: _completionController,
      curve: Curves.easeInOut,
    );

    if (widget.isActive) {
      _startShimmer();
    }
  }

  @override
  void didUpdateWidget(ShimmerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle completion animation trigger
    if (widget.showCompletion && !oldWidget.showCompletion && !_showingCompletion) {
      _showCompletionAnimation();
    }
    
    // Handle normal shimmer start/stop
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive && !_showingCompletion) {
        _startShimmer();
      } else if (!widget.isActive && !widget.showCompletion) {
        _stopShimmer();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  void _startShimmer() {
    if (!_animationController.isAnimating) {
      debugPrint('🎬 Starting shimmer animation');
      _animationController.repeat();
    }
  }

  void _stopShimmer() {
    debugPrint('⏹️ Stopping shimmer animation');
    _animationController.stop();
    _animationController.reset();
  }

  void _showCompletionAnimation() async {
    setState(() {
      _showingCompletion = true;
    });
    
    debugPrint('✅ Starting completion animation');
    
    // Stop regular shimmer
    _animationController.stop();
    
    // Play completion animation
    await _completionController.forward();
    
    // Wait a moment then finish
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Call completion callback
    if (widget.onCompletionFinished != null) {
      widget.onCompletionFinished!();
    }
    
    // Reset state
    _completionController.reset();
    setState(() {
      _showingCompletion = false;
    });
    
    debugPrint('🎉 Completion animation finished');
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive && !_showingCompletion) {
      return widget.child ?? const SizedBox.shrink();
    }

    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        
        // Show completion animation or regular shimmer
        if (_showingCompletion)
          _buildCompletionAnimation()
        else
          _buildShimmerAnimation(),
      ],
    );
  }

  Widget _buildShimmerAnimation() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-1.0, -1.0),
              end: const Alignment(1.0, 1.0),
              stops: [
                (_animation.value - 0.5).clamp(0.0, 1.0),
                (_animation.value - 0.3).clamp(0.0, 1.0),
                (_animation.value - 0.1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.1).clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
                (_animation.value + 0.5).clamp(0.0, 1.0),
              ],
              colors: widget.colors,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletionAnimation() {
    return AnimatedBuilder(
      animation: _completionAnimation,
      builder: (context, child) {
        // Create a "scan complete" flash effect
        final opacity = (1.0 - _completionAnimation.value) * 0.8;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5 * _completionAnimation.value,
              colors: [
                Colors.white.withValues(alpha: opacity),
                Colors.lightBlue.shade50.withValues(alpha: opacity * 0.6),
                Colors.transparent,
              ],
              stops: [0.0, 0.7, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Widget that displays analyzing text with animation
class AnalyzingText extends StatefulWidget {
  final bool isVisible;
  final String text;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const AnalyzingText({
    super.key,
    required this.isVisible,
    this.text = 'Analyzing Image...',
    this.textStyle,
    this.padding,
  });

  @override
  State<AnalyzingText> createState() => _AnalyzingTextState();
}

class _AnalyzingTextState extends State<AnalyzingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    if (widget.isVisible) {
      _fadeController.forward();
    }
  }

  @override
  void didUpdateWidget(AnalyzingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _fadeController.forward();
      } else {
        _fadeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - _fadeAnimation.value)),
            child: Container(
              width: double.infinity,
              padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                widget.text,
                style: widget.textStyle ?? const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}