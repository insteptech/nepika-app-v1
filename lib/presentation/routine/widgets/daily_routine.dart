import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/routes.dart';

class DailyRoutineSection extends StatefulWidget {
  final Map<String, dynamic>? dailyRoutine;
  final bool isLoading;

  const DailyRoutineSection({
    super.key,
    this.dailyRoutine,
    this.isLoading = false,
  });

  @override
  State<DailyRoutineSection> createState() => _DailyRoutineSectionState();
}

class _DailyRoutineSectionState extends State<DailyRoutineSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _tickAnimation;
  bool _showTickAnimation = false;
  bool _previousCompletedState = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _tickAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DailyRoutineSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkForCompletionChange();
  }

  void _checkForCompletionChange() {
    if (widget.dailyRoutine != null) {
      final bool currentCompleted = widget.dailyRoutine!['completed'] == true;
      
      // If routine was just completed (transitioned from false to true)
      if (!_previousCompletedState && currentCompleted) {
        _triggerCompletionAnimation();
      }
      
      _previousCompletedState = currentCompleted;
    }
  }

  void _triggerCompletionAnimation() {
    setState(() {
      _showTickAnimation = true;
    });
    
    // Start the tick animation
    _animationController.forward();
    
    // Hide the tick animation after 2-3 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _showTickAnimation = false;
        });
        _animationController.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Handle all possible race conditions and invalid states
    if (widget.isLoading || !_isValidDailyRoutineData(widget.dailyRoutine)) {
      return _buildSkeletonCard(context: context);
    }

    return _buildDailyRoutineCard(context: context);
  }

  /// Validates if daily routine data is in a usable state
  bool _isValidDailyRoutineData(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return false;
    }

    // Check if essential data structure exists
    // Allow progress to be null/missing (will default to 0)
    return data.containsKey('progress') || 
           data.containsKey('completed') || 
           data.containsKey('unit');
  }

  Widget _buildDailyRoutineCard({required BuildContext context}) {
    // Safely extract and validate progress data
    final dynamic rawProgress = widget.dailyRoutine!['progress'];
    final bool hasRoutines = widget.dailyRoutine!['has_routines'];
    final double progress = _sanitizeProgress(rawProgress);
    final String unit = widget.dailyRoutine!['unit']?.toString() ?? '%';
    final bool completed = widget.dailyRoutine!['completed'] == true;
    final theme = Theme.of(context);
    
    // Calculate display values
    final String displayText = _getDisplayText(progress, unit, completed, hasRoutines);
    final double progressValue = _calculateProgressValue(progress, completed);
    final bool showProgress = progress > 0 || completed;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onTertiary,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Calendar icon
          Image.asset(
            'assets/icons/calender_icon.png',
            width: 37,
            height: 37,
            color: theme.colorScheme.primary,
          ),
          
          // Text section
          Flexible(
            child: Text(
              displayText,
              style: theme.textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          
          // Progress and tick section
          Row(
            children: [
              // Progress bar
if (!completed && !_showTickAnimation)
              SizedBox(
                width: 100,
                child:AnimatedOpacity(
                  opacity: showProgress ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 300),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(completed, theme),
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
              ),

              // const SizedBox(width: 12),

              // Completion tick animation - always present for consistent layout
              if (completed && hasRoutines)
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

              if (!hasRoutines)
                GestureDetector(  
                  onTap: () {
                    Navigator.pushNamed(
                        context,
                        AppRoutes.dashboardAddRoutine,
                      );
                  },
                  child:  Image.asset(
                          'assets/icons/add_icon.png',
                          width: 20,
                          height: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                )
            ],
          ),
        ],
      ),
    );
  }

  /// Sanitizes progress value to ensure it's valid
  double _sanitizeProgress(dynamic rawProgress) {
    if (rawProgress == null) return 0.0;
    
    try {
      final double value = rawProgress is String 
        ? double.tryParse(rawProgress) ?? 0.0
        : rawProgress.toDouble();
      
      // Clamp progress between 0 and 100
      return value.clamp(0.0, 100.0);
    } catch (e) {
      return 0.0;
    }
  }

  /// Gets appropriate display text based on progress state
  String _getDisplayText(double progress, String unit, bool completed, bool hasRoutines) {
    if (completed && hasRoutines) {
      return 'Completed';
    } else if (!hasRoutines) {
      return 'Setup Routine Steps';
    }else if (progress > 0) {
      // Format progress to remove unnecessary decimal places
      String formattedProgress = progress % 1 == 0 
        ? progress.toInt().toString() 
        : progress.toStringAsFixed(1);
      formattedProgress = formattedProgress.split('.')[0];
      return '$formattedProgress$unit Complete';
    } else {
      return 'Daily Routine';
    }
  }

  /// Calculates the progress value for the indicator
  double _calculateProgressValue(double progress, bool completed) {
    if (completed) {
      return 1.0;
    } else if (progress > 0) {
      return (progress / 100).clamp(0.0, 1.0);
    } else {
      return 0.0;
    }
  }

  /// Gets appropriate color for progress indicator
  Color _getProgressColor(bool completed, ThemeData theme) {
    if (completed) {
      return Colors.green;
    } else {
      return theme.colorScheme.primary;
    }
  }

  Widget _buildSkeletonCard({required BuildContext context}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onTertiary,
        borderRadius: BorderRadius.circular(20),

      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const SizedBox(width: 12),
          // Skeleton icon
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: _buildShimmerEffect(),
          ),
          const SizedBox(width: 30),
          // Skeleton text
          Container(
            width: 120,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: _buildShimmerEffect(),
          ),
          const SizedBox(width: 30),
          // Skeleton progress bar
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
              ),
              child: _buildShimmerEffect(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return AnimatedBuilder(
          animation: AlwaysStoppedAnimation(value),
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.grey[300]!,
                    Colors.grey[100]!,
                    Colors.grey[300]!,
                  ],
                  stops: [
                    (value - 0.3).clamp(0.0, 1.0),
                    value.clamp(0.0, 1.0),
                    (value + 0.3).clamp(0.0, 1.0),
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        );
      },
    );
  }
}