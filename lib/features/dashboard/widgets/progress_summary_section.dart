import 'package:flutter/material.dart';
import 'package:nepika/features/dashboard/widgets/progress_summary_chart.dart';
import 'package:nepika/features/dashboard/widgets/section_header.dart';

class ProgressSummarySection extends StatefulWidget {
  final Map<String, dynamic> progressSummary;

  const ProgressSummarySection({super.key, required this.progressSummary});

  @override
  State<ProgressSummarySection> createState() => _ProgressSummarySectionState();
}

class _ProgressSummarySectionState extends State<ProgressSummarySection> {
  String _progressSummaryFilter = 'Monthly';

  @override
  Widget build(BuildContext context) {
    // Filter data based on selected filter
    final filteredSummary = Map<String, dynamic>.from(widget.progressSummary);
    if (filteredSummary['data'] is List) {
      final List data = filteredSummary['data'] as List;
      if (_progressSummaryFilter == 'Weekly' && data.length > 7) {
        // Take the last 7 entries for weekly view
        filteredSummary['data'] = data.sublist(data.length - 7);
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: SectionHeader(
                  heading: 'Progress Summary',
                  showButton: false,
                ),
              ),
              Container(
                height: 32,
                width: 140,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment: _progressSummaryFilter == 'Weekly'
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        width: 70,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (_progressSummaryFilter != 'Weekly') {
                                setState(() => _progressSummaryFilter = 'Weekly');
                              }
                            },
                            child: Center(
                              child: Text(
                                'Weekly',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _progressSummaryFilter == 'Weekly'
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: _progressSummaryFilter == 'Weekly'
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (_progressSummaryFilter != 'Monthly') {
                                setState(() => _progressSummaryFilter = 'Monthly');
                              }
                            },
                            child: Center(
                              child: Text(
                                'Monthly',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _progressSummaryFilter == 'Monthly'
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: _progressSummaryFilter == 'Monthly'
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ProgressSummaryChart(
          progressSummary: filteredSummary,
          filter: _progressSummaryFilter,
          height: 280,
          padding: const EdgeInsets.only(left: 20, right: 0, top: 20, bottom: 2),
          showPointsAndLabels: true,
          isOverall: true,
        ),
      ],
    );
  }
}
