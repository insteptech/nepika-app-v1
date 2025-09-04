import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme.dart';

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
        return name.split('_').map((word) => 
          word.isNotEmpty 
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : word
        ).join(' ').trim();
    }
  }

  Color _getConditionColor(String condition, BuildContext context) {
    // Return different colors based on condition type
    switch (condition.toLowerCase().trim()) {
      case 'acne':
        return const Color(0xFFE53E3E);
      case 'dry':
      case 'dry ':
        return const Color(0xFF3182CE);
      case 'normal':
        return const Color(0xFF38A169);
      case 'wrinkle':
        return const Color(0xFFD69E2E);
      case 'dark_circles':
        return const Color(0xFF805AD5);
      case 'pigmentation':
        return const Color(0xFFDD6B20);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedName = _formatConditionName(conditionName);
    final conditionColor = _getConditionColor(conditionName, context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.39,
        height: 180,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
            width: 1,
          ),
          // boxShadow: [
          //   BoxShadow(
          //     color: Theme.of(context).shadowColor.withOpacity(0.08),
          //     blurRadius: 8,
          //     offset: const Offset(0, 2),
          //   ),
          // ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Condition name
              Text(
                formattedName,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.start,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              Spacer(),
              // Percentage with circular indicator
              // Column(
              //   children: [
              //     Container(
              //       width: 50,
              //       height: 50,
              //       decoration: BoxDecoration(
              //         shape: BoxShape.circle,
              //         color: conditionColor.withOpacity(0.1),
              //         border: Border.all(
              //           color: conditionColor.withOpacity(0.3),
              //           width: 2,
              //         ),
              //       ),
              //       child: Center(
              //         child: Text(
              //           '${percentage.toStringAsFixed(0)}%',
              //           style: Theme.of(context).textTheme.titleSmall?.copyWith(
              //             fontWeight: FontWeight.w700,
              //             color: conditionColor,
              //           ),
              //         ),
              //       ),
              //     ),
              //   ],
              // ),


              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 5),
              
              // View details link
              GestureDetector(
                onTap: onTap,
                child: Text(
                  'Details',
                  style: Theme.of(context).textTheme.bodyLarge?.hint(context).copyWith(
                    decoration: TextDecoration.combine([
                      TextDecoration.underline,
                    ]),
                    decorationColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}