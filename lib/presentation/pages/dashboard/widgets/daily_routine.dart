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
    // Show skeleton when loading or when dailyRoutine is null/empty
    if (isLoading || dailyRoutine == null || dailyRoutine!.isEmpty) {
      return _buildSkeletonCard(context: context);
    }

    return _buildDailyRoutineCard(context: context);
  }

  Widget _buildDailyRoutineCard({required BuildContext context}) {
    final double progress = (dailyRoutine!['progress'] ?? 0).toDouble();
    final String unit = dailyRoutine!['unit'] ?? '%';
    final bool completed = dailyRoutine!['completed'] ?? false;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: completed ? Colors.green[50] :  theme.colorScheme.onTertiary,
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
          Text(
            progress > 0 ? '$progress$unit Complete' : 'Daily Routine',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(width: 30),
          Expanded(
            child: LinearProgressIndicator(
              value: completed ? 1.0 : progress / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                completed ? Colors.green : Theme.of(context).colorScheme.primary,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
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