import 'package:flutter/material.dart';

class DailyRoutineSection extends StatelessWidget {
  final Map<String, dynamic>? dailyRoutine;
  final bool isLoading;

  const DailyRoutineSection({
    super.key,
    this.dailyRoutine,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Handle all possible race conditions and invalid states
    if (isLoading || !_isValidDailyRoutineData(dailyRoutine)) {
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
    final dynamic rawProgress = dailyRoutine!['progress'];
    final double progress = _sanitizeProgress(rawProgress);
    final String unit = dailyRoutine!['unit']?.toString() ?? '%';
    final bool completed = dailyRoutine!['completed'] == true;
    final theme = Theme.of(context);
    
    // Calculate display values
    final bool hasProgress = progress > 0;
    final String displayText = _getDisplayText(progress, unit, completed, hasProgress);
    final double progressValue = _calculateProgressValue(progress, completed);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onTertiary,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Image.asset(
            'assets/icons/calender_icon.png',
            width: 37,
            height: 37,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 30),
          Flexible(
            child: Text(
              displayText,
              style: Theme.of(context).textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 30),
          // Only show progress bar if there's actual progress or completion
          if (hasProgress || completed)
            Expanded(
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(completed, hasProgress, theme),
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(6),
              ),
            )
          else
            // Show empty space when no progress to maintain layout
            const Expanded(child: SizedBox()),
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
  String _getDisplayText(double progress, String unit, bool completed, bool hasProgress) {
    if (completed && hasProgress) {
      return 'Daily Routine Complete';
    } else if (hasProgress) {
      // Format progress to remove unnecessary decimal places
      final String formattedProgress = progress % 1 == 0 
        ? progress.toInt().toString() 
        : progress.toStringAsFixed(1);
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
  Color _getProgressColor(bool completed, bool hasProgress, ThemeData theme) {
    if (completed && hasProgress) {
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