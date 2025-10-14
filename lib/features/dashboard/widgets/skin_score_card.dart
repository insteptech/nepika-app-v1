import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme.dart';

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return (month >= 1 && month <= 12) ? months[month - 1] : 'Unknown';
}

class SkinScoreCard extends StatelessWidget {
  final Map<String, dynamic>? skinScore;
  final bool isLoading;

  const SkinScoreCard({
    super.key,
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
        // boxShadow: [
        //   BoxShadow(
        //     color: colorScheme.shadow.withValues(alpha: 0.08),
        //     blurRadius: 20,
        //     offset: const Offset(0, 10),
        //   ),
        // ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your skin score',
            style: textTheme.bodyLarge!.secondary(context).copyWith(
              fontSize: 13
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                '$score',
                style: textTheme.headlineMedium?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
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
            'Last updated:', style: textTheme.bodyMedium!.secondary(context),),

          Text(
              formattedDate,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: textTheme.bodyMedium!.secondary(context),
            ),
          // Expanded(
          //   child: Text(
          //     formattedDate,
          //     overflow: TextOverflow.ellipsis,
          //     softWrap: true,
          //     style: textTheme.bodyMedium!.secondary(context),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.onTertiary,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your skin score',
            style: textTheme.bodyLarge!.secondary(context).copyWith(fontSize: 13),
          ),
          const SizedBox(height: 8),
          // Skeleton for score
          Container(
            width: 60,
            height: 24,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last updated:',
                style: textTheme.bodyMedium!.secondary(context),
              ),
              const SizedBox(height: 4),
              // Skeleton for date
              Container(
                width: 120,
                height: 10,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}