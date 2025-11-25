import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/config/constants/routes.dart';

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
  final bool showSheildImage;
  final bool isLoading;

  const SkinScoreCard({super.key, this.skinScore, this.isLoading = false, this.showSheildImage = true});

  void _showSkinScoreInfoBottomSheet(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'About Your Skin Score',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'What is Skin Score?',
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A numerical rating (0-100) that represents your overall skin health. It\'s calculated by analyzing detected skin conditions, their severity, and how many areas are affected.',
              style: textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'How to read your score:',
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoPoint(
              context,
              'Higher Score',
              'Fewer skin concerns detected, healthier skin condition',
            ),
            const SizedBox(height: 10),
            _buildInfoPoint(
              context,
              'Lower Score',
              'More concerns detected or higher severity issues',
            ),
            const SizedBox(height: 10),
            _buildInfoPoint(
              context,
              'Change Arrow',
              'Shows if your skin improved (↑) or declined (↓) since last scan',
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context,rootNavigator: true).pushNamed(AppRoutes.faceScanInfo);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Learn More About Face Scan',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPoint(BuildContext context, String title, String description) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textTheme.bodyMedium?.color,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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

        formattedDate = showSheildImage ? '$day $month $year, $hour12:$minute $amPm' : '$day $month, $hour12:$minute $amPm';
      } catch (e) {
        formattedDate = 'Invalid date';
      }
    }

    final bool isNegative = change < 0;
    final Color changeColor = isNegative
        ? colorScheme.error
        : colorScheme.secondary;
    final IconData changeIcon = isNegative
        ? Icons.arrow_drop_down
        : Icons.arrow_drop_up;

    return Container(
      width: double.infinity,
      height: 154,
      decoration: BoxDecoration(
        color: colorScheme.onTertiary,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    showSheildImage?'Your skin score':'Skin Score',
                  maxLines: 2,
                    style: textTheme.bodyLarge!
                        .secondary(context)
                        .copyWith(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _showSkinScoreInfoBottomSheet(context),
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: textTheme.bodyLarge!.secondary(context).color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Text(
                      '$score',
                      style: textTheme.headlineMedium?.copyWith(
                        fontSize: 35,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.secondary,
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
              ),
              // const Spacer(),
              Text(
                'Last updated:',
                style: textTheme.bodyMedium!.secondary(context),
              ),

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
          if (showSheildImage)
            SizedBox(
              width: 100,
              child: Image.asset('assets/images/sheild_image.png')
              ),
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.onTertiary,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                    showSheildImage?'Your skin score':'Skin Score',
                style: textTheme.bodyLarge!
                    .secondary(context)
                    .copyWith(fontSize: 13),
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
                    width: 100,
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

          if (showSheildImage)
            SizedBox(
              width: 100,
              child: Image.asset('assets/images/sheild_image.png'),
            ),
        ],
      ),
    );
  }
}
