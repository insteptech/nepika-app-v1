import 'package:flutter/material.dart';

class SliderButton extends StatefulWidget {
  final String? text;
  final VoidCallback? onSlideComplete;
  final VoidCallback? onSlideReset;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? sliderColor;
  final Color? textColor;
  final IconData? icon;
  final double? borderRadius;
  final bool enabled;
  final bool isCompleted;

  const SliderButton({
    super.key,
    this.text,
    this.onSlideComplete,
    this.onSlideReset,
    this.width = 280,
    this.height = 40,
    this.backgroundColor = const Color(0xFF3898ED),
    this.sliderColor = Colors.white,
    this.textColor = Colors.white,
    this.icon,
    this.borderRadius = 20,
    this.enabled = true,
    this.isCompleted = false,
  });

  @override
  State<SliderButton> createState() => _SliderButtonState();
}

class _SliderButtonState extends State<SliderButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  double _sliderPosition = 0.0;
  bool _isSliding = false;
  bool _isCompleted = false;

  // Slider dimensions for small standard button
  static const double _sliderSize = 32.0;
  static const double _padding = 4.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Initialize position based on completed state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isCompleted) {
        setState(() {
          _sliderPosition = _maxSlideDistance;
          _isCompleted = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double get _maxSlideDistance => (widget.width! - _sliderSize - (2 * _padding));

  void _onPanStart(DragStartDetails details) {
    if (!widget.enabled) return;
    _isSliding = true;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enabled || !_isSliding) return;

    setState(() {
      _sliderPosition += details.delta.dx;
      _sliderPosition = _sliderPosition.clamp(0.0, _maxSlideDistance);
    });

    // Check direction and completion thresholds
    if (!_isCompleted && _sliderPosition >= _maxSlideDistance * 0.9) {
      _completeSlide();
    } else if (_isCompleted && _sliderPosition <= _maxSlideDistance * 0.1) {
      _resetSlide();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.enabled) return;
    
    _isSliding = false;
    
    // Snap to appropriate position based on current state and position
    if (!_isCompleted) {
      if (_sliderPosition >= _maxSlideDistance * 0.5) {
        // Snap to completed position
        _animateToPosition(_maxSlideDistance);
        _completeSlide();
      } else {
        // Snap back to start
        _animateToPosition(0.0);
      }
    } else {
      if (_sliderPosition <= _maxSlideDistance * 0.5) {
        // Snap to reset position
        _animateToPosition(0.0);
        _resetSlide();
      } else {
        // Snap back to completed position
        _animateToPosition(_maxSlideDistance);
      }
    }
  }

  void _completeSlide() {
    if (_isCompleted) return;
    
    setState(() {
      _isCompleted = true;
      _sliderPosition = _maxSlideDistance;
    });

    // Call completion callback
    widget.onSlideComplete?.call();
  }

  void _resetSlide() {
    if (!_isCompleted) return;
    
    setState(() {
      _isCompleted = false;
      _sliderPosition = 0.0;
    });

    // Call reset callback
    widget.onSlideReset?.call();
  }

  void _animateToPosition(double position) {
    final startPosition = _sliderPosition;
    final endPosition = position;
    
    _animationController.reset();
    _slideAnimation = Tween<double>(
      begin: startPosition,
      end: endPosition,
    ).animate(_animationController);
    
    _slideAnimation.addListener(() {
      setState(() {
        _sliderPosition = _slideAnimation.value;
      });
    });
    
    _animationController.forward();
  }


  @override
  Widget build(BuildContext context) {
    final double sliderLeft = _padding + _sliderPosition;
    
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius!),
      ),
      child: Stack(
        children: [
          // Background text
          if (widget.text != null)
            Positioned.fill(
              child: Center(
                child: Text(
                  widget.text!,
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          
          // Slider circle
          AnimatedPositioned(
            duration: _isSliding ? Duration.zero : const Duration(milliseconds: 10),
            left: sliderLeft,
            top: _padding,
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Container(
                width: _sliderSize,
                height: _sliderSize,
                decoration: BoxDecoration(
                  color: widget.sliderColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: AnimatedRotation(
                  turns: _isCompleted ? 0.99 : 0.0, // 90 degrees rotation when completed
                  duration: const Duration(milliseconds: 700),
                  child: widget.icon != null
                      ? Icon(
                          widget.icon,
                          color: widget.backgroundColor,
                          size: 16,
                        )
                      : Icon(
                          _isCompleted ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                          color: const Color(0xFF3898ED),
                          size: 16,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}