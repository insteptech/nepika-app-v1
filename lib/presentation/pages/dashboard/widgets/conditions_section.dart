import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'condition_card.dart';

class ConditionsSection extends StatefulWidget {
  final Map<String, dynamic>? latestConditionResult;
  final Function(String)? onConditionTap;

  const ConditionsSection({
    super.key,
    this.latestConditionResult,
    this.onConditionTap,
  });

  @override
  State<ConditionsSection> createState() => _ConditionsSectionState();
}

class _ConditionsSectionState extends State<ConditionsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.latestConditionResult == null || widget.latestConditionResult!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Convert the map to a list of entries and sort by percentage (highest first)
    final conditions = widget.latestConditionResult!.entries
        .where((entry) => entry.value is num)
        .map((entry) => MapEntry(entry.key, (entry.value as num).toDouble()))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate grid dimensions
    const itemsPerRow = 3;
    final totalRows = (conditions.length / itemsPerRow).ceil();
    final visibleRows = _isExpanded ? totalRows : 1.5;
    final cardHeight = 170.0;
    final rowSpacing = 12.0;
    final containerHeight =
        (visibleRows * cardHeight) + ((visibleRows - 1) * rowSpacing) - 40;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const SizedBox(height: 16),
        const SizedBox(height: 40),

        // Grid with expandable container
        Stack(
          children: [
            Container(
              height: containerHeight,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                gridDelegate: const 
                SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: itemsPerRow,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: conditions.length,
                itemBuilder: (context, index) {
                  final condition = conditions[index];
                  return ConditionCard(
                    conditionName: condition.key,
                    percentage: condition.value,
                    onTap: () {
                      if (widget.onConditionTap != null) {
                        widget.onConditionTap!(condition.key);
                      }
                    },
                  );
                },
              ),
            ),
            
            // Single dynamic button with blur background (only show if has more than 1.5 rows)
            if (totalRows > 1.5)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: _isExpanded ? 60 : 80,
                child: Container(
                  decoration: _isExpanded ? null : BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
                        Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                        Theme.of(context).scaffoldBackgroundColor,
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
                          filter: ImageFilter.blur(sigmaX: .5, sigmaY: .5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onTertiary.withValues(alpha: .9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.blueGrey.withValues(alpha: .6),
                                width: 0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isExpanded ? 'View Less' : 'View More',
                                  style: Theme.of(context).textTheme.bodyMedium?.hint(context)
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: Theme.of(context).textTheme.bodyMedium?.hint(context).color!,
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