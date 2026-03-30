import 'package:flutter/material.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/settings_header.dart';

class CommunityInsightsScreen extends StatefulWidget {
  const CommunityInsightsScreen({super.key});

  @override
  State<CommunityInsightsScreen> createState() => _CommunityInsightsScreenState();
}

class _CommunityInsightsScreenState extends State<CommunityInsightsScreen> {
  bool _isLoading = true;
  String? _error;

  List<dynamic> _skinConditionDistribution = [];
  List<dynamic> _topIssues = [];
  List<dynamic> _ageBands = [];

  @override
  void initState() {
    super.initState();
    _fetchInsights();
  }

  Future<void> _fetchInsights() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await ApiBase().request(
        path: "/dashboard/community-insights",
        method: "GET",
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (mounted) {
          setState(() {
            _skinConditionDistribution = data['skinConditionDistribution'] ?? [];
            _topIssues = data['topIssues'] ?? [];
            _ageBands = data['ageBands'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load insights. Please try again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to fetch data. Please try again later.';
          _isLoading = false;
        });
      }
    }
  }



  Color _parseColor(String hexString) {
    var hex = hexString.toUpperCase().replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: _fetchInsights,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SettingsHeader(title: 'Community Insights', showBackButton: true),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: _buildErrorState(theme),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildAgeBandsSection(theme),
                      const SizedBox(height: 24),
                      _buildSectionTitle(theme, 'Skin Condition Breakdown'),
                      const SizedBox(height: 12),
                      _buildSkinDistributionChart(theme),
                      const SizedBox(height: 24),
                      _buildSectionTitle(theme, 'Top Common Issues'),
                      const SizedBox(height: 12),
                      _buildTopIssuesList(theme),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _fetchInsights,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
      ),
    );
  }

  Widget _buildAgeBandsSection(ThemeData theme) {
    if (_ageBands.isEmpty) return const SizedBox.shrink();

    // Unique issues across all bands
    final Set<String> uniqueIssues = {};
    for (var bandData in _ageBands) {
      if (bandData['issues'] != null) {
        for (var issue in bandData['issues']) {
          uniqueIssues.add(issue['name'] as String);
        }
      }
    }

    final List<String> issuesList = uniqueIssues.toList();

    // Assign specific colors matching the user's image where possible
    final List<Color> palette = [
      AppTheme.primaryColor.withValues(alpha: 0.8),
      const Color(0xFFF29B52),
      const Color(0xFF7D65A9),
      const Color(0xFFE56E8A),
      const Color(0xFFEED6AD),
      const Color(0xFF5ABCB6),
      const Color(0xFFD64448),
      const Color(0xFF86C166),
      const Color(0xFF4169E1),
      const Color(0xFFE1D06E),
    ];

    final Map<String, Color> issueColors = {};
    for (int i = 0; i < issuesList.length; i++) {
      final lowerName = issuesList[i].toLowerCase();
      if (lowerName.contains('acne')) {
        issueColors[issuesList[i]] = const Color(0xFF4DBFC1); // Muted Teal
      } else if (lowerName.contains('oil')) {
        issueColors[issuesList[i]] = const Color(0xFFFFA962); // Soft Orange/Peach
      } else if (lowerName.contains('pigment') || lowerName.contains('spot')) {
        issueColors[issuesList[i]] = const Color(0xFF8161B8); // Soft Purple
      } else if (lowerName.contains('wrinkle')) {
        issueColors[issuesList[i]] = const Color(0xFFE96D8E); // Soft Pink
      } else if (lowerName.contains('dry')) {
        issueColors[issuesList[i]] = const Color(0xFFE6CFAB); // Muted Tan
      } else {
        issueColors[issuesList[i]] = palette[i % palette.length];
      }
    }

    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildSectionTitle(theme, 'Understanding common skin issues by age group'),
        const SizedBox(height: 4),
        // Text(
        //   '(Last 30 days • Anonymized data)',
        //   style: theme.textTheme.bodySmall?.copyWith(
        //     color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
        //     fontSize: 12,
        //   ),
        // ),
        const SizedBox(height: 16),
        _buildCard(
          theme,
          padding: const EdgeInsets.fromLTRB(12, 32, 24, 20),
          child: Column(
            children: [
              SizedBox(
                height: 280,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    minY: 0,
                    groupsSpace: 20,
                    barTouchData: BarTouchData(enabled: false), // Static chart typical for this view
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < _ageBands.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Text(
                                  _ageBands[value.toInt()]['band'],
                                  style: TextStyle(
                                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          interval: 20,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: TextStyle(
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.right,
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: theme.dividerColor.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3), width: 1),
                      ),
                    ),
                    barGroups: List.generate(_ageBands.length, (index) {
                      final bandData = _ageBands[index];
                      final issues = bandData['issues'] as List<dynamic>;
                      
                      double currentY = 0;
                      List<BarChartRodStackItem> stackItems = [];
                      
                      // Using the order of issuesList to keep stack order consistent if desired,
                      // or just render as they come. Rendering as they come handles different totals well.
                      for (var issueData in issues) {
                        final name = issueData['name'] as String;
                        final pct = (issueData['percentage'] as num).toDouble();
                        stackItems.add(
                          BarChartRodStackItem(currentY, currentY + pct, issueColors[name]!)
                        );
                        currentY += pct;
                      }
                      
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: currentY > 100 ? 100 : currentY, // Caps at 100% just in case
                            width: 40,
                            borderRadius: BorderRadius.zero,
                            rodStackItems: stackItems,
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Legend
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: issueColors.entries.map((entry) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        color: entry.value,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildSkinDistributionChart(ThemeData theme) {
    if (_skinConditionDistribution.isEmpty) return const SizedBox.shrink();

    final total = _skinConditionDistribution.fold<int>(0, (sum, d) => sum + (d['value'] as int));

    return _buildCard(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      startDegreeOffset: -90,
                      sections: _skinConditionDistribution.map((d) {
                        final val = (d['value'] as int).toDouble();
                        return PieChartSectionData(
                          color: _parseColor(d['color']),
                          value: val,
                          title: '',
                          radius: 46,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _skinConditionDistribution.map((d) {
                      final val = d['value'] as int;
                      final pct = total > 0 ? (val / total * 100).round() : 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _parseColor(d['color']),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                d['name'],
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '$pct%',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIssuesList(ThemeData theme) {
    if (_topIssues.isEmpty) return const SizedBox.shrink();

    return _buildCard(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _topIssues.asMap().entries.map((entry) {
          final i = entry.key;
          final issue = entry.value;
          final pct = issue['percentage'] as int;
          final isLast = i == _topIssues.length - 1;

          // Highlight top 3 with decreasing alpha (e.g. 0.15, 0.11, 0.07), others are grey.
          final isTop3 = i < 3;
          final badgeAlpha = isTop3 ? (0.15 - (i * 0.04)).clamp(0.05, 0.15) : 0.0;
          final progressAlpha = isTop3 ? (0.4 - (i * 0.1)).clamp(0.15, 0.4) : 0.0;
          
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rank Badge
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isTop3 
                        ? AppTheme.primaryColor.withValues(alpha: badgeAlpha)
                        : theme.colorScheme.surface,
                    border: !isTop3 ? Border.all(color: theme.dividerColor.withValues(alpha: 0.15)) : null,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isTop3 
                          ? AppTheme.primaryColor 
                          : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content Block (Name, Pct, Progress Line)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            issue['name'],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.9),
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isTop3 ? FontWeight.bold : FontWeight.w600,
                              color: isTop3 ? AppTheme.primaryColor : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100.0,
                          minHeight: 6,
                          backgroundColor: isTop3 
                              ? AppTheme.primaryColor.withValues(alpha: 0.08)
                              : theme.dividerColor.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isTop3 
                                ? AppTheme.primaryColor.withValues(alpha: progressAlpha + 0.5) 
                                : theme.dividerColor.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCard(ThemeData theme, {required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
