import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:nepika/features/dashboard/widgets/progress_summary_chart.dart';
import '../models/scan_analysis_models.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/config/constants/routes.dart';

class SeverityData {
  final String label;
  final double percentage;
  final Color color;

  const SeverityData(this.label, this.percentage, this.color);
}

class ScanResultDetailsScreen extends StatefulWidget {
  final String reportId;
  final String? condition; // requested initial condition (may be null)

  const ScanResultDetailsScreen({
    super.key,
    required this.reportId,
    this.condition,
  });

  @override
  State<ScanResultDetailsScreen> createState() =>
      _ScanResultDetailsScreenState();
}

class _ScanResultDetailsScreenState extends State<ScanResultDetailsScreen> {
  String? selectedCondition;
  late ScrollController _scrollController;
  late ScrollController _horizontalScrollController;

  // Stable maps for sections & chips (created once after data load)
  final Map<String, GlobalKey> _sectionKeys = {};
  final Map<String, GlobalKey> _chipKeys = {};

  bool _showMarkings = false;
  bool _isLoading = true;
  String? _error;
  List<RecommendationGroup> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _horizontalScrollController = ScrollController();
    selectedCondition = widget.condition;
    _scrollController.addListener(_onScroll);

    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      debugPrint('🔍 Fetching report details for reportId: ${widget.reportId}');

      final response = await ApiBase().request(
        path: '/training/report/${widget.reportId}',
        method: 'GET',
      );

      debugPrint('📡 Report API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Raw API response: ${response.data}');

        List<dynamic> rawData;
        if (response.data is List<dynamic>) {
          rawData = response.data as List<dynamic>;
        } else if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;
          if (responseMap.containsKey('recommendations')) {
            rawData = responseMap['recommendations'] as List<dynamic>;
          } else if (responseMap.containsKey('data')) {
            rawData = responseMap['data'] as List<dynamic>;
          } else {
            rawData = [];
          }
        } else {
          rawData = [];
        }

        // convert / normalize to List<Map<String, dynamic>>
        final List<Map<String, dynamic>> typedData = rawData.map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          } else if (item is Map) {
            final Map<String, dynamic> converted = {};
            item.forEach((key, value) {
              final String stringKey = key.toString();
              if (value is List) {
                converted[stringKey] = value.map((listItem) {
                  if (listItem is Map && listItem is! Map<String, dynamic>) {
                    final Map<String, dynamic> convertedItem = {};
                    listItem.forEach((k, v) {
                      convertedItem[k.toString()] = v;
                    });
                    return convertedItem;
                  } else if (listItem is Map<String, dynamic>) {
                    return listItem;
                  }
                  return listItem;
                }).toList();
              } else {
                converted[stringKey] = value;
              }
            });
            return converted;
          }
          throw Exception('Invalid data format: expected Map but got ${item.runtimeType}');
        }).toList();

        _recommendations = typedData
            .map((item) => RecommendationGroup.fromJson(item))
            .toList();

        debugPrint('✅ Successfully parsed ${_recommendations.length} recommendation groups');

        if (_recommendations.isNotEmpty) {
          // Create stable keys once here
          for (final group in _recommendations) {
            // If key already exists (unlikely on first load) keep it, otherwise create new
            _sectionKeys.putIfAbsent(group.skinIssue, () => GlobalKey());
            _chipKeys.putIfAbsent(group.skinIssue, () => GlobalKey());
          }

          // Decide which condition to select initially
          final resolved = _resolveInitialCondition(widget.condition, _recommendations);
          selectedCondition = resolved;
          debugPrint('📌 Selected initial condition: $selectedCondition');

          // Wait for widgets to build, then auto-scroll to the chosen section & chip
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToInitialCondition(resolved);
          });
        } else {
          debugPrint('⚠️ No recommendations found in response');
        }

        setState(() {
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        throw Exception('Report not found or does not belong to you (404).');
      } else {
        throw Exception('Failed to load report: ${response.statusCode}');
      }
    } catch (e, st) {
      debugPrint('❌ Error fetching report data: $e');
      debugPrint('$st');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  /// Normalize and find the best match for initial condition. If not found, returns first group's skinIssue.
  String _resolveInitialCondition(String? requested, List<RecommendationGroup> groups) {
    if (groups.isEmpty) return requested ?? '';

    if (requested == null || requested.trim().isEmpty) {
      return groups.first.skinIssue;
    }

    final normalizedRequested = _normalizeKey(requested);

    // Try exact match first, then contains match, else fallback to first
    for (final g in groups) {
      if (_normalizeKey(g.skinIssue) == normalizedRequested) {
        return g.skinIssue;
      }
    }
    for (final g in groups) {
      if (_normalizeKey(g.skinIssue).contains(normalizedRequested) ||
          normalizedRequested.contains(_normalizeKey(g.skinIssue))) {
        return g.skinIssue;
      }
    }

    return groups.first.skinIssue;
  }

  String _normalizeKey(String input) {
    return input.replaceAll('-', ' ').toLowerCase().trim();
  }

  /// Auto-scroll to the chosen section and also ensure the chip is visible.
  void _scrollToInitialCondition(String skinIssue) {
    if (!mounted) return;

    // Scroll section into view
    final sectionKey = _sectionKeys[skinIssue];
    if (sectionKey?.currentContext != null) {
      try {
        Scrollable.ensureVisible(
          sectionKey!.currentContext!,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeInOut,
          alignment: 0, // try to place section a little below the sticky header
        );
      } catch (e) {
        debugPrint('Error ensuring visible for section: $e');
      }
    }

    // Also ensure the chip is visible in the horizontal list
    final chipKey = _chipKeys[skinIssue];
    if (chipKey?.currentContext != null) {
      try {
        Scrollable.ensureVisible(
          chipKey!.currentContext!,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      } catch (e) {
        debugPrint('Error ensuring visible for chip: $e');
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || _recommendations.isEmpty) return;

    String? newSelectedCondition;
    double maxVisibleRatio = 0.0;

    final viewportHeight = MediaQuery.of(context).size.height;
    final headerOffset = 200.0; // approximate header + chips

    for (final group in _recommendations) {
      final key = _sectionKeys[group.skinIssue];
      final ctx = key?.currentContext;
      if (ctx == null) continue;

      final renderBox = ctx.findRenderObject() as RenderBox?;
      if (renderBox == null) continue;

      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      final sectionTop = position.dy;
      final sectionBottom = position.dy + size.height;

      final visibleTop = math.max(sectionTop, headerOffset);
      final visibleBottom = math.min(sectionBottom, viewportHeight);

      if (visibleBottom > visibleTop) {
        final visibleHeight = visibleBottom - visibleTop;
        final visibleRatio = visibleHeight / size.height;

        if (visibleRatio > maxVisibleRatio ||
            (visibleRatio == maxVisibleRatio && newSelectedCondition == null)) {
          maxVisibleRatio = visibleRatio;
          newSelectedCondition = group.skinIssue;
        }
      }
    }

    if (newSelectedCondition != null && newSelectedCondition != selectedCondition) {
      setState(() {
        selectedCondition = newSelectedCondition;
      });

      // Ensure chip visible when user scrolls content
      final chipKey = _chipKeys[newSelectedCondition];
      if (chipKey?.currentContext != null) {
        try {
          Scrollable.ensureVisible(
            chipKey!.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.5,
          );
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark),
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading report...'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load report',
                          style: TextStyle(
                            fontFamily: 'HelveticaNowDisplay',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF07223B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error ?? 'Unknown error',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'HelveticaNowDisplay',
                            fontSize: 14,
                            color: isDark ? Colors.white70 : const Color(0xFF7F7F7F),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _fetchReportData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3898ED),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            _buildConditionFilters(isDark),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    _buildAllRecommendationsContent(isDark),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      height: 47,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_ios, size: 20, color: isDark ? Colors.white : const Color(0xFF07223B)),
                const SizedBox(width: 10),
                Text(
                  'Back',
                  style: TextStyle(
                    fontFamily: 'HelveticaNowDisplay',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white70 : const Color(0xFF7F7F7F),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context, rootNavigator: true).pushNamed(AppRoutes.faceScanInfo);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : const Color(0xFF07223B)).withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.info_outline, size: 20, color: isDark ? Colors.white : const Color(0xFF07223B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
      child: SizedBox(
        height: 40,
        child: ListView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: _recommendations.map((group) {
            final isSelected = selectedCondition == group.skinIssue;
            final displayName = _getDisplayNameForSkinIssue(group.skinIssue);

            return Padding(
              padding: const EdgeInsets.only(right: 15),
              child: GestureDetector(
                key: _chipKeys[group.skinIssue],
                onTap: () {
                  setState(() {
                    selectedCondition = group.skinIssue;
                  });
                  // scroll the main content to that section
                  _scrollToSection(group.skinIssue);
                  // ensure this chip is visible horizontally
                  if (_chipKeys[group.skinIssue]?.currentContext != null) {
                    try {
                      Scrollable.ensureVisible(
                        _chipKeys[group.skinIssue]!.currentContext!,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: 0.5,
                      );
                    } catch (_) {}
                  }
                },
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF3898ED) : Colors.transparent,
                    border: Border.all(color: const Color(0xFF3898ED), width: 1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontFamily: 'HelveticaNowDisplay',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: isSelected ? Colors.white : const Color(0xFF3898ED),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getDisplayNameForSkinIssue(String skinIssue) {
    final normalized = skinIssue.replaceAll('-', ' ').toLowerCase().trim();

    switch (normalized) {
      case 'wrinkles':
        return 'Anti-aging + Fine Lines';
      case 'skin redness':
        return 'Redness & Irritation';
      case 'acne':
        return 'Acne & Breakouts';
      case 'dark spots':
      case 'hyperpigmentation':
        return 'Hyperpigmentation & Dark Spots';
      case 'dry skin':
      case 'dryness':
        return 'Dryness & Dehydration';
      case 'sensitivity':
      case 'reactive skin':
        return 'Sensitivity (Reactive skin)';
      case 'oily skin':
        return 'Oily Skin';
      case 'enlarged pores':
      case 'englarged pores':
        return 'Enlarged Pores';
      case 'blackheads':
        return 'Blackheads';
      case 'whiteheads':
        return 'Whiteheads';
      case 'eyebags':
      case 'eye bags':
        return 'Eye Bags';
      default:
        return skinIssue
            .replaceAll('-', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : word)
            .join(' ');
    }
  }

  void _scrollToSection(String skinIssue) {
    final key = _sectionKeys[skinIssue];
    if (key?.currentContext != null) {
      try {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          alignment: 0,
        );
      } catch (e) {
        debugPrint('Error scrolling to section: $e');
      }
    }
  }

  Widget _buildAllRecommendationsContent(bool isDark) {
    if (_recommendations.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, size: 64, color: isDark ? Colors.white54 : Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No Analysis Available',
                  style: TextStyle(
                    fontFamily: 'HelveticaNowDisplay',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF07223B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This scan doesn\'t have detailed analysis data yet. Try scanning again or check back later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'HelveticaNowDisplay',
                    fontSize: 14,
                    color: isDark ? Colors.white70 : const Color(0xFF7F7F7F),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _recommendations.map((group) {
          return Container(
            key: _sectionKeys[group.skinIssue],
            margin: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDisplayNameForSkinIssue(group.skinIssue),
                  style: TextStyle(
                    fontFamily: 'HelveticaNowDisplay',
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white : const Color(0xFF07223B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
                const SizedBox(height: 5),
                Text(
                  _getDescriptionForCondition(group.skinIssue),
                  style: TextStyle(
                    fontFamily: 'HelveticaNowDisplay',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white70 : const Color(0xFF7F7F7F),
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
                const SizedBox(height: 30),
                Text(
                  'Suggested Solutions',
                  style: TextStyle(
                    fontFamily: 'HelveticaNowDisplay',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white : const Color(0xFF07223B),
                  ),
                ),
                const SizedBox(height: 10),
                _buildProductRecommendations(group.recommendations, isDark),
                const SizedBox(height: 20),
                if (group.progressSummary != null)
                  Row(
                    key: ValueKey('${group.skinIssue}_progress_summary_header'),
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Progress Summary", style: Theme.of(context).textTheme.headlineMedium),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          alignment: Alignment.center,
                        ),
                        onPressed: () {
                          setState(() {
                            _showMarkings = !_showMarkings;
                          });
                        },
                        child: Row(
                          children: [
                            Text("Proints", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                            const SizedBox(width: 4),
                            Icon(_showMarkings ? Icons.visibility : Icons.visibility_off, size: 15, color: Theme.of(context).colorScheme.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                if (group.progressSummary != null)
                  GestureDetector(
                    onTap: () {
                      _handleProgrssSummaryChartTap(group.conditionSlug ?? group.skinIssue);
                    },
                    child: ProgressSummaryChart(
                      key: ValueKey('${group.skinIssue}_progress_summary_${_showMarkings ? "with_points" : "no_points"}'),
                      progressSummary: group.progressSummary!,
                      showPointsAndLabels: _showMarkings,
                    ),
                  ),
                const SizedBox(height: 50),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductRecommendations(List<ProductRecommendation> recommendations, bool isDark) {
    final List<Widget> rows = [];

    for (int i = 0; i < recommendations.length; i += 2) {
      final List<Widget> rowChildren = [];

      rowChildren.add(Expanded(child: _buildProductCard(recommendations[i], isDark)));

      if (i + 1 < recommendations.length) {
        rowChildren.add(const SizedBox(width: 15));
        rowChildren.add(Expanded(child: _buildProductCard(recommendations[i + 1], isDark)));
      }

      rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowChildren));

      if (i + 2 < recommendations.length) rows.add(const SizedBox(height: 15));
    }

    return Column(children: rows);
  }

  Widget _buildProductCard(ProductRecommendation recommendation, bool isDark) {
    final isClinicallProven = recommendation.isClinicallyProven;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 13, height: 13, decoration: const BoxDecoration(color: Color.fromARGB(255, 1, 53, 98), shape: BoxShape.circle), child: const Icon(Icons.info, size: 10, color: Colors.white)),
          const SizedBox(width: 5),
          Expanded(child: Text(recommendation.product, style: const TextStyle(fontFamily: 'HelveticaNowDisplay', fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white))),
        ]),
        const SizedBox(height: 5),
        Text('${recommendation.effectivenessPercentage}%', style: const TextStyle(fontFamily: 'HelveticaNowDisplay', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(3)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (!isClinicallProven) ...[
              Container(width: 15, height: 15, decoration: const BoxDecoration(color: Color.fromARGB(255, 255, 210, 106), shape: BoxShape.circle), child: const Icon(Icons.info, size: 8, color: Colors.white)),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                recommendation.effectivenessLevel,
                style: TextStyle(
                  fontFamily: 'HelveticaNowDisplay',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isClinicallProven ? const Color.fromARGB(255, 99, 255, 167) : const Color.fromARGB(255, 255, 222, 144),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 5),
        Text(
          recommendation.description,
          style: const TextStyle(fontFamily: 'HelveticaNowDisplay', fontSize: 13, fontWeight: FontWeight.w400, color: Colors.white),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
        ),
      ]),
    );
  }

  void _handleProgrssSummaryChartTap(String conditionName) {
    Navigator.of(context, rootNavigator: true).pushNamed(AppRoutes.conditionDetailsPage, arguments: {'conditionInfo': conditionName});
  }

  String _getDescriptionForCondition(String condition) {
    final normalized = condition.replaceAll('-', ' ').toLowerCase().trim();

    switch (normalized) {
      case 'wrinkles':
        return 'Fine lines and wrinkles are caused by aging, sun exposure, and repeated facial expressions. Anti-aging ingredients help stimulate collagen production and smooth the skin surface.';
      case 'skin redness':
        return 'Skin redness can be caused by irritation, inflammation, or underlying skin conditions. Soothing ingredients help calm the skin and reduce visible redness.';
      case 'acne':
        return 'Acne occurs when pores become clogged with oil and dead skin cells. Targeted treatments help unclog pores and prevent future breakouts.';
      case 'dark spots':
      case 'hyperpigmentation':
        return 'Dark spots and hyperpigmentation are caused by sun damage, acne scarring, or hormonal changes. Brightening ingredients help even out skin tone.';
      case 'dryness':
      case 'dry skin':
        return 'Dehydration causes skin to feel dry, tight, or rough. Moisturizing ingredients increase hydration and support the skin barrier.';
      case 'oily skin':
        return 'Excess oil production can lead to shine and clogged pores. Balancing treatments help regulate sebum and maintain a healthy complexion.';
      case 'blackheads':
        return 'Blackheads form when pores become clogged with oil and dead skin cells that oxidize. Exfoliating treatments help clear pores.';
      case 'whiteheads':
        return 'Whiteheads are closed pores filled with oil and dead skin cells. Gentle exfoliation and pore-clearing treatments can help.';
      case 'enlarged pores':
      case 'englarged pores':
        return 'Enlarged pores can be caused by genetics, aging, or excess oil production. Pore-minimizing treatments help refine skin texture.';
      case 'eyebags':
      case 'eye bags':
        return 'Eye bags can be caused by aging, lack of sleep, or fluid retention. Targeted eye treatments help reduce puffiness and dark circles.';
      default:
        return 'This skin condition requires targeted care with appropriate skincare ingredients to improve its appearance and health.';
    }
  }
}
