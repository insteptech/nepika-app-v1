import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A step in the guided tour
class TourStep {
  final String title;
  final String description;
  final GlobalKey targetKey;
  final Alignment tooltipAlignment;
  final EdgeInsets tooltipOffset;

  const TourStep({
    required this.title,
    required this.description,
    required this.targetKey,
    this.tooltipAlignment = Alignment.bottomCenter,
    this.tooltipOffset = const EdgeInsets.only(top: 20),
  });
}

/// Guided tour overlay that highlights specific elements
class GuidedTourOverlay {
  static OverlayEntry? _overlayEntry;
  static int _currentStep = 0;
  static List<TourStep> _steps = [];
  static VoidCallback? _onComplete;

  /// Start the guided tour
  static Future<void> startTour({
    required BuildContext context,
    required List<TourStep> steps,
    VoidCallback? onComplete,
  }) async {
    if (steps.isEmpty) return;

    _steps = steps;
    _currentStep = 0;
    _onComplete = onComplete;

    _showOverlay(context);
  }

  /// Show the overlay for current step
  static void _showOverlay(BuildContext context) {
    _removeOverlay();

    final currentStep = _steps[_currentStep];
    
    _overlayEntry = OverlayEntry(
      builder: (context) => _TourOverlayWidget(
        step: currentStep,
        currentStepIndex: _currentStep,
        totalSteps: _steps.length,
        onNext: () => _nextStep(context),
        onSkip: () => _skipTour(),
        onPrevious: _currentStep > 0 ? () => _previousStep(context) : null,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Move to next step
  static void _nextStep(BuildContext context) {
    if (_currentStep < _steps.length - 1) {
      _currentStep++;
      _showOverlay(context);
    } else {
      _completeTour();
    }
  }

  /// Move to previous step
  static void _previousStep(BuildContext context) {
    if (_currentStep > 0) {
      _currentStep--;
      _showOverlay(context);
    }
  }

  /// Skip the entire tour
  static void _skipTour() {
    _completeTour();
  }

  /// Complete the tour and cleanup
  static void _completeTour() {
    _removeOverlay();
    _onComplete?.call();
  }

  /// Remove the current overlay
  static void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

/// The actual overlay widget that renders the tour step
class _TourOverlayWidget extends StatefulWidget {
  final TourStep step;
  final int currentStepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback? onPrevious;

  const _TourOverlayWidget({
    required this.step,
    required this.currentStepIndex,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
    this.onPrevious,
  });

  @override
  State<_TourOverlayWidget> createState() => _TourOverlayWidgetState();
}

class _TourOverlayWidgetState extends State<_TourOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getTargetRect();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _getTargetRect() {
    final RenderBox? renderBox =
        widget.step.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      setState(() {
        _targetRect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                // Dimmed background with highlight cutout
                _buildBackgroundOverlay(),
                
                // Tooltip
                if (_targetRect != null) _buildTooltip(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _HighlightPainter(
          targetRect: _targetRect,
          highlightRadius: 8.0,
        ),
      ),
    );
  }

  Widget _buildTooltip() {
    final screenSize = MediaQuery.of(context).size;
    final targetRect = _targetRect!;
    
    // Calculate tooltip position
    double tooltipLeft = 20.0;
    double tooltipTop = targetRect.bottom + widget.step.tooltipOffset.top;
    double tooltipRight = 20.0;
    
    // Adjust position based on target location
    if (tooltipTop + 200 > screenSize.height - 100) {
      // Show above target if not enough space below
      tooltipTop = targetRect.top - 200 - widget.step.tooltipOffset.top;
    }

    return Positioned(
      left: tooltipLeft,
      right: tooltipRight,
      top: tooltipTop,
      child: _buildTooltipContent(),
    );
  }

  Widget _buildTooltipContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (widget.currentStepIndex + 1) / widget.totalSteps,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${widget.currentStepIndex + 1}/${widget.totalSteps}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Title
          Text(
            widget.step.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Description
          Text(
            widget.step.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action buttons
          Row(
            children: [
              // Previous button
              if (widget.onPrevious != null)
                TextButton(
                  onPressed: widget.onPrevious,
                  child: Text(
                    'Previous',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              
              const Spacer(),
              
              // Skip button
              TextButton(
                onPressed: widget.onSkip,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Next/Done button
              ElevatedButton(
                onPressed: widget.onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.currentStepIndex == widget.totalSteps - 1 ? 'Done' : 'Next',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the dimmed background with highlight cutout
class _HighlightPainter extends CustomPainter {
  final Rect? targetRect;
  final double highlightRadius;

  _HighlightPainter({
    required this.targetRect,
    required this.highlightRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Draw the dimmed background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    if (targetRect != null) {
      // Create a clear cutout for the highlighted element
      final highlightPaint = Paint()
        ..color = Colors.transparent
        ..blendMode = BlendMode.clear;

      final highlightRect = RRect.fromRectAndRadius(
        targetRect!.inflate(8.0),
        Radius.circular(highlightRadius),
      );

      canvas.drawRRect(highlightRect, highlightPaint);

      // Add a subtle border around the highlight
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRRect(highlightRect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Manager class for handling tour preferences
class TourPreferences {
  static const String _faceScanTourKey = 'has_seen_face_scan_tour';

  /// Check if user has seen the face scan tour
  static Future<bool> hasSeenFaceScanTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_faceScanTourKey) ?? false;
  }

  /// Mark the face scan tour as seen
  static Future<void> markFaceScanTourAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_faceScanTourKey, true);
  }

  /// Reset the tour (for testing purposes)
  static Future<void> resetFaceScanTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_faceScanTourKey);
  }
}