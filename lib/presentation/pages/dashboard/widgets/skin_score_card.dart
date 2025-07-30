import 'package:flutter/material.dart';

String _monthName(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return (month >= 1 && month <= 12) ? months[month - 1] : 'Unknown';
}

class SkinScoreCard extends StatelessWidget {
  final Map<String, dynamic>? skinScore;
  final bool isLoading;

  const SkinScoreCard({
    this.skinScore,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    // Show skeleton when loading or when skinScore is null/empty
    if (isLoading || skinScore == null || skinScore!.isEmpty) {
      return _buildSkeletonCard(context);
    }
    final int score = skinScore!['score'] ?? 0;
    final int change = skinScore!['change'] ?? 0;
    final String updatedAtRaw = skinScore!['lastUpdated'] ?? 'N/A';

    String formattedDate = 'N/A';
    if (updatedAtRaw.isNotEmpty) {
      try {
        final utcDate = DateTime.parse(updatedAtRaw).toUtc();
        final localDate = utcDate.toLocal();

        final day = localDate.day;
        final month = _monthName(localDate.month);
        final year = localDate.year;

        final hour24 = localDate.hour;
        final minute = localDate.minute.toString().padLeft(2, '0');
        final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
        final amPm = hour24 >= 12 ? 'PM' : 'AM';

        formattedDate = '$day $month $year, $hour12:$minute $amPm';
      } catch (e) {
        formattedDate = 'Invalid date';
      }
    }

    final bool isNegative = change < 0;
    final Color changeColor = isNegative ? colorScheme.error : colorScheme.secondary;
    final IconData changeIcon = isNegative
        ? Icons.arrow_drop_down
        : Icons.arrow_drop_up;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.onTertiary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your skin score',
            style: textTheme.bodyLarge
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '$score',
                style: textTheme.headlineMedium?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${change > 0 ? '+' : ''}$change',
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: changeColor,
                ),
              ),
              Icon(changeIcon, color: changeColor, size: 20),
            ],
          ),
          const Spacer(),
          Text(
            'Last updated:',
            style: textTheme.bodyMedium
          ),
          Text(
            formattedDate,
            style: textTheme.bodyMedium
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.onTertiary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your skin score',
            style: textTheme.bodyLarge
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Skeleton for score (backend data)
              Container(
                width: 60,
                height: 30,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _buildShimmerEffect(),
              ),
              const SizedBox(width: 8),
              // Skeleton for change value (backend data)
              Container(
                width: 40,
                height: 16,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _buildShimmerEffect(),
              ),
              const SizedBox(width: 4),
              // Skeleton for change icon (backend data)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _buildShimmerEffect(),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last updated:',
            style: textTheme.bodyMedium
              ),
              const SizedBox(height: 2),
              // Skeleton for date (backend data)
              Container(
                width: 160,
                height: 12,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _buildShimmerEffect(),
              ),
            ],
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