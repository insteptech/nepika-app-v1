import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme.dart';

/// A widget that displays skin condition results in a vertical list format.
/// Each row shows: [Condition Name] [Percentage] [Details button]
/// Supports expand/collapse functionality similar to ConditionsSection.
class ConditionsListSection extends StatefulWidget {
  final Map<String, dynamic>? latestConditionResult;
  final Function(String)? onConditionTap;
  final int initialVisibleCount;

  const ConditionsListSection({
    super.key,
    this.latestConditionResult,
    this.onConditionTap,
    this.initialVisibleCount = 3,
  });

  @override
  State<ConditionsListSection> createState() => _ConditionsListSectionState();
}

class _ConditionsListSectionState extends State<ConditionsListSection> {
  bool _isExpanded = false;

  String _formatConditionName(String name) {
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
    if (widget.latestConditionResult == null ||
        widget.latestConditionResult!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Convert and sort by percentage (highest first)
    final conditions = widget.latestConditionResult!.entries
        .where((entry) => entry.value is num)
        .map((entry) => MapEntry(entry.key, (entry.value as num).toDouble()))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final hasMoreItems = conditions.length > widget.initialVisibleCount;
    final visibleConditions = _isExpanded
        ? conditions
        : conditions.take(widget.initialVisibleCount).toList();

    // Calculate heights for animation
    const rowHeight = 52.0;
    final collapsedHeight = (widget.initialVisibleCount * rowHeight) +
        ((widget.initialVisibleCount - 1) * 1.0); // divider height
    final expandedHeight = (conditions.length * rowHeight) +
        ((conditions.length - 1) * 1.0);
    final containerHeight = _isExpanded ? expandedHeight : collapsedHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: hasMoreItems ? containerHeight + (hasMoreItems ? 48 : 0) : null,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: visibleConditions.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                itemBuilder: (context, index) {
                  final condition = visibleConditions[index];
                  return _ConditionRow(
                    conditionName: _formatConditionName(condition.key),
                    rawConditionName: condition.key,
                    percentage: condition.value,
                    onDetailsTap: () =>
                        widget.onConditionTap?.call(condition.key),
                  );
                },
              ),
            ),
            // View More/Less button with gradient overlay
            if (hasMoreItems)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: _isExpanded ? 48 : 80,
                child: Container(
                  decoration: _isExpanded
                      ? null
                      : BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: 0.0),
                              Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: 0.8),
                              Theme.of(context).colorScheme.surface,
                            ],
                          ),
                        ),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onTertiary
                                  .withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.blueGrey.withValues(alpha: 0.6),
                                width: 0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isExpanded ? 'View Less' : 'View More',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.hint(context),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.hint(context)
                                      .color!,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ConditionRow extends StatelessWidget {
  final String conditionName;
  final String rawConditionName;
  final double percentage;
  final VoidCallback? onDetailsTap;

  const _ConditionRow({
    required this.conditionName,
    required this.rawConditionName,
    required this.percentage,
    this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDetailsTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Condition Name (expanded to take available space)
            Expanded(
              flex: 3,
              child: Text(
                conditionName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Percentage
            SizedBox(
              width: 60,
              child: Text(
                '${percentage.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getPercentageColor(percentage, context),
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            // Details button
            GestureDetector(
              onTap: onDetailsTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Details',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPercentageColor(double percentage, BuildContext context) {
    if (percentage >= 70) {
      return const Color(0xFFF44336); // Red for high severity
    } else if (percentage >= 40) {
      return const Color(0xFFFF9800); // Orange for medium
    } else {
      return const Color(0xFF4CAF50); // Green for low
    }
  }
}
