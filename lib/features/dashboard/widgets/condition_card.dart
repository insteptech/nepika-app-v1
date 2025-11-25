import 'package:flutter/material.dart';
// import 'package:nepika/core/config/constants/theme.dart';

class ConditionCard extends StatelessWidget {
  final String conditionName;
  final double percentage;
  final VoidCallback? onTap;

  const ConditionCard({
    super.key,
    required this.conditionName,
    required this.percentage,
    this.onTap,
  });

  String _formatConditionName(String name) {
    // Format the condition name to be more readable
    switch (name.toLowerCase().trim()) {
      case 'acne':
        return 'Acne';
      case 'dry':
      case 'dry ':
        return 'Dry Skin';
      case 'normal':
        return 'Normal';
      case 'wrinkle':
        return 'Wrinkles';
      case 'dark_circles':
        return 'Dark Circles';
      case 'pigmentation':
        return 'Pigmentation';
      default:
        // Capitalize first letter and replace underscores with spaces
        return name
            .split('_')
            .map(
              (word) => word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : word,
            )
            .join(' ')
            .trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedName = _formatConditionName(conditionName);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.39,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.8),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // mainAxisSize: MainAxisSize.min,         
                children: [
                  // Condition name - can wrap to 2 lines
                  Text(
                    formattedName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onTertiary,
                      fontSize: 13,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.start,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // const SizedBox(height: 6),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onTertiary,
                              fontSize: 24,
                              height: 1.1,
                            ),
                      ),
                      const SizedBox(height: 6),
                      // View details link
                      GestureDetector(
                        onTap: onTap,
                        child: Text(
                          'Details',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onTertiary,
                                fontSize: 12,
                                decoration: TextDecoration.combine([
                                  TextDecoration.underline,
                                ]),
                                decorationColor: Theme.of(
                                  context,
                                ).colorScheme.onTertiary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  // Percentage
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
