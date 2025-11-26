import 'package:flutter/material.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'dart:math' as math;
import '../models/scan_analysis_models.dart';

/// Screen to display personalized skin care recommendations after face scan
/// Updated UI design with condition tabs and expandable sections
class ScanRecommendationsScreen extends StatefulWidget {
  final ScanAnalysisResponse scanResponse;
  final String? initialCondition; // Optional condition to scroll to on load

  const ScanRecommendationsScreen({
    super.key,
    required this.scanResponse,
    this.initialCondition,
  });

  @override
  State<ScanRecommendationsScreen> createState() =>
      _ScanRecommendationsScreenState();
}

class _ScanRecommendationsScreenState extends State<ScanRecommendationsScreen> {
  String? selectedCondition;
  late ScrollController _scrollController;
  late ScrollController _horizontalScrollController;

  // Stable maps for sections & chips
  final Map<String, GlobalKey> _sectionKeys = {};
  final Map<String, GlobalKey> _chipKeys = {};

  // Expanded state for accordion sections per condition
  final Map<String, Set<String>> _expandedSections = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _horizontalScrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Initialize with detected conditions
    _initializeConditions();

    // Scroll to initial condition after layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (selectedCondition != null && widget.initialCondition != null) {
        // Scroll to the specified initial condition
        _scrollToSection(selectedCondition!);
        // Also ensure the chip is visible
        final chipKey = _chipKeys[selectedCondition];
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
      } else if (_scrollController.hasClients) {
        // Default: scroll to top
        _scrollController.jumpTo(0);
      }
    });
  }

  void _initializeConditions() {
    final conditions = _getDetectedConditions();
    if (conditions.isNotEmpty) {
      // Create keys for each condition first
      for (final condition in conditions) {
        _sectionKeys.putIfAbsent(condition.name, () => GlobalKey());
        _chipKeys.putIfAbsent(condition.name, () => GlobalKey());
        _expandedSections.putIfAbsent(condition.name, () => {});
      }

      // Set initial selected condition
      if (widget.initialCondition != null) {
        // Find the condition that matches the initialCondition (case-insensitive)
        final matchingCondition = conditions.firstWhere(
          (c) => c.name.toLowerCase() == widget.initialCondition!.toLowerCase() ||
                 c.displayName.toLowerCase() == widget.initialCondition!.toLowerCase(),
          orElse: () => conditions.first,
        );
        selectedCondition = matchingCondition.name;
      } else {
        selectedCondition = conditions.first.name;
      }
    }
  }

  List<ConditionPrediction> _getDetectedConditions() {
    return widget.scanResponse.conditionAnalysis.sortedPredictions
        .where(
          (p) => p.confidence > 5.0,
        ) // Only include conditions with > 5% confidence
        .toList();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;

    final conditions = _getDetectedConditions();
    if (conditions.isEmpty) return;

    String? newSelectedCondition;
    double maxVisibleRatio = 0.0;

    final viewportHeight = MediaQuery.of(context).size.height;
    final headerOffset = 150.0;

    for (final condition in conditions) {
      final key = _sectionKeys[condition.name];
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
          newSelectedCondition = condition.name;
        }
      }
    }

    if (newSelectedCondition != null &&
        newSelectedCondition != selectedCondition) {
      setState(() {
        selectedCondition = newSelectedCondition;
      });

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

  void _scrollToSection(String conditionName) {
    final key = _sectionKeys[conditionName];
    if (key?.currentContext != null) {
      try {
        // Use a small delay to ensure layout is complete
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!mounted) return;
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: 0.0, // Scroll to top of section
          );
        });
      } catch (e) {
        debugPrint('Error scrolling to section: $e');
      }
    } else {
      // If section key not found, scroll to top as default
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleSection(String conditionName, String sectionName) {
    setState(() {
      final sections = _expandedSections[conditionName] ?? {};
      if (sections.contains(sectionName)) {
        sections.remove(sectionName);
      } else {
        sections.add(sectionName);
      }
      _expandedSections[conditionName] = sections;
    });
  }

  bool _isSectionExpanded(String conditionName, String sectionName) {
    return _expandedSections[conditionName]?.contains(sectionName) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final conditions = _getDetectedConditions();

    if (conditions.isEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark),
              const Expanded(
                child: Center(child: Text('No skin conditions detected')),
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
            _buildConditionFilters(isDark, conditions),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    ...conditions.map(
                      (condition) =>
                          _buildConditionSection(context, isDark, condition),
                    ),
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
    final theme = Theme.of(context);
    final textPrimary = isDark
        ? AppTheme.textPrimaryDark
        : AppTheme.textPrimaryLight;
    final textSecondary = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;

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
                Icon(Icons.arrow_back_ios, size: 20, color: textPrimary),
                const SizedBox(width: 10),
                Text(
                  'Back',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.faceScanInfo);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: textPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.info_outline, size: 20, color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionFilters(
    bool isDark,
    List<ConditionPrediction> conditions,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
      child: SizedBox(
        height: 40,
        child: ListView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: conditions.map((condition) {
            final isSelected = selectedCondition == condition.name;

            return Padding(
              padding: const EdgeInsets.only(right: 15),
              child: GestureDetector(
                key: _chipKeys[condition.name],
                onTap: () {
                  setState(() {
                    selectedCondition = condition.name;
                  });
                  _scrollToSection(condition.name);
                  if (_chipKeys[condition.name]?.currentContext != null) {
                    try {
                      Scrollable.ensureVisible(
                        _chipKeys[condition.name]!.currentContext!,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: 0.5,
                      );
                    } catch (_) {}
                  }
                },
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.transparent,
                    border: Border.all(color: primaryColor, width: 1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      condition.displayName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isSelected ? Colors.white : primaryColor,
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

  Widget _buildConditionSection(
    BuildContext context,
    bool isDark,
    ConditionPrediction condition,
  ) {
    final recommendations = widget.scanResponse.recommendations;
    final conditionName = condition.name.toLowerCase();

    // Filter recommendations for this condition
    final causes = recommendations.groups.causes
        .where(
          (item) =>
              item.condition.toLowerCase() == conditionName ||
              item.condition.toLowerCase().contains(conditionName),
        )
        .toList();
    final products = recommendations.groups.products
        .where(
          (item) =>
              item.condition.toLowerCase() == conditionName ||
              item.condition.toLowerCase().contains(conditionName),
        )
        .toList();
    final alternates = recommendations.groups.alternateSolutions
        .where(
          (item) =>
              item.condition.toLowerCase() == conditionName ||
              item.condition.toLowerCase().contains(conditionName),
        )
        .toList();
    final lifestyle = recommendations.groups.lifestyleSuggestions
        .where(
          (item) =>
              item.condition.toLowerCase() == conditionName ||
              item.condition.toLowerCase().contains(conditionName),
        )
        .toList();
    final considerations = recommendations.groups.importantConsiderations
        .where(
          (item) =>
              item.condition.toLowerCase() == conditionName ||
              item.condition.toLowerCase().contains(conditionName),
        )
        .toList();
    final dos = recommendations.groups.dos
        .where(
          (item) =>
              item.condition.toLowerCase() == conditionName ||
              item.condition.toLowerCase().contains(conditionName),
        )
        .toList();
    final donts = recommendations.groups.donts
        .where(
          (item) =>
              item.condition.toLowerCase() == conditionName ||
              item.condition.toLowerCase().contains(conditionName),
        )
        .toList();

    // Get primary solution
    final primarySolution = products.isNotEmpty ? products.first : null;

    final surfaceColor = isDark
        ? AppTheme.surfaceColorDark
        : AppTheme.surfaceColorLight;
    final borderColor = isDark
        ? const Color(0xFF3E3E3E)
        : const Color(0xFFE5E5E5);

    return Container(
      key: _sectionKeys[condition.name],
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detected Concern Card
          _buildDetectedConcernCard(context, isDark, condition),
          const SizedBox(height: 16),

          // Primary Solution Card
          if (primarySolution != null) ...[
            _buildPrimarySolutionCard(context, isDark, primarySolution),
            const SizedBox(height: 16),
          ],

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                if (causes.isNotEmpty)
                  _buildAccordionSection(
                    context,
                    isDark,
                    condition.name,
                    'causes',
                    'Causes',
                    Icons.psychology,
                    causes.length,
                    () => _buildCausesList(context, isDark, causes),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 1,
                    child: Divider(
                      color: borderColor,
                    ),
                  ),

                if (products.length > 1)
                  _buildAccordionSection(
                    context,
                    isDark,
                    condition.name,
                    'products',
                    'Product Examples',
                    Icons.shopping_bag_outlined,
                    products.length - 1, // Exclude primary solution
                    () => _buildProductsList(
                      context,
                      isDark,
                      products.skip(1).toList(),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 1,
                    child: Divider(
                      color: borderColor,
                    ),
                  ),

                if (alternates.isNotEmpty)
                  _buildAccordionSection(
                    context,
                    isDark,
                    condition.name,
                    'alternates',
                    'Alternative Solutions',
                    Icons.auto_awesome_outlined,
                    alternates.length,
                    () => _buildAlternatesList(context, isDark, alternates),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 1,
                    child: Divider(
                      color: borderColor,
                    ),
                  ),

                if (lifestyle.isNotEmpty)
                  _buildAccordionSection(
                    context,
                    isDark,
                    condition.name,
                    'lifestyle',
                    'Lifestyle Suggestions',
                    Icons.self_improvement,
                    lifestyle.length,
                    () => _buildLifestyleList(context, isDark, lifestyle),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 1,
                    child: Divider(
                      color: borderColor,
                    ),
                  ),

                if (considerations.isNotEmpty)
                  _buildAccordionSection(
                    context,
                    isDark,
                    condition.name,
                    'considerations',
                    'Important Considerations',
                    Icons.warning_amber_outlined,
                    considerations.length,
                    () => _buildConsiderationsList(
                      context,
                      isDark,
                      considerations,
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 1,
                    child: Divider(
                      color: borderColor,
                    ),
                  ),
              ],
            ),
          ),
          // Expandable Accordion Sections
          // Do's & Don'ts Section (always visible, not accordion)
          if (dos.isNotEmpty || donts.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDosAndDontsSection(context, isDark, dos, donts),
          ],

          // Medical Disclaimer
          const SizedBox(height: 24),
          _buildMedicalDisclaimer(context, isDark),
        ],
      ),
    );
  }

  Widget _buildDetectedConcernCard(
    BuildContext context,
    bool isDark,
    ConditionPrediction condition,
  ) {
    final theme = Theme.of(context);
    final textPrimary = isDark
        ? AppTheme.textPrimaryDark
        : AppTheme.textPrimaryLight;
    final textSecondary = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;
    final surfaceColor = isDark
        ? AppTheme.surfaceColorDark
        : AppTheme.surfaceColorLight;
    final borderColor = isDark
        ? const Color(0xFF2E2E2E)
        : const Color(0xFFE5E5E5);

    final severity = widget.scanResponse.recommendations.personalizedFor
        .getSeverity(condition.name);
    final severityColor = _getSeverityColor(severity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Detected Concern',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.primary,
                ),
              ),
              GestureDetector(
                onTap: () => _showAITooltip(context, condition),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.info_outline,
                    size: 14,
                    color: isDark ? Colors.white70 : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            condition.displayName,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Confidence Level',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${condition.confidence.toStringAsFixed(0)}%',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: severityColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: condition.confidence / 100,
              minHeight: 8,
              backgroundColor: borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(severityColor),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Severity: ${_capitalizeFirst(severity)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: severityColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimarySolutionCard(
    BuildContext context,
    bool isDark,
    RecommendationItem solution,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.onTertiary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Ⓞ Primary Solution',
                style: TextStyle(
                  fontFamily: 'HelveticaNowDisplay',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Text(
          //   solution.title,
          //   style: TextStyle(
          //     fontFamily: 'HelveticaNowDisplay',
          //     fontSize: 18,
          //     fontWeight: FontWeight.w600,
          //     color: Theme.of(context).colorScheme.tertiary,
          //   ),
          // ),
          if (solution.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              solution.subtitle!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            solution.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (solution.usage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      solution.usage!,
                      style: TextStyle(
                        fontFamily: 'HelveticaNowDisplay',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccordionSection(
    BuildContext context,
    bool isDark,
    String conditionName,
    String sectionId,
    String title,
    IconData icon,
    int itemCount,
    Widget Function() contentBuilder,
  ) {
    final theme = Theme.of(context);
    final textPrimary = isDark
        ? AppTheme.textPrimaryDark
        : AppTheme.textPrimaryLight;
    final textSecondary = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;
    final surfaceColor = isDark
        ? AppTheme.surfaceColorDark
        : AppTheme.surfaceColorLight;
    final borderColor = isDark
        ? const Color(0xFF2E2E2E)
        : const Color(0xFFE5E5E5);
    final chipBgColor = isDark
        ? const Color(0xFF2E2E2E)
        : const Color(0xFFF5F5F5);

    final isExpanded = _isSectionExpanded(conditionName, sectionId);

    return Container(
      // margin: const EdgeInsets.only(bottom: 8),
      // decoration: BoxDecoration(
      //   color: surfaceColor,
      //   borderRadius: BorderRadius.circular(12),
      //   border: Border.all(color: borderColor),
      // ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleSection(conditionName, sectionId),
            borderRadius: BorderRadius.circular(0),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: chipBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$itemCount',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 24,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              child: contentBuilder(),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildCausesList(
    BuildContext context,
    bool isDark,
    List<RecommendationItem> causes,
  ) {
    final theme = Theme.of(context);
    final textPrimary = isDark
        ? AppTheme.textPrimaryDark
        : AppTheme.textPrimaryLight;
    final textSecondary = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;
    final primaryColor = theme.colorScheme.primary;
    final itemBgColor = isDark
        ? const Color(0xFF2E2E2E)
        : const Color(0xFFF8F8F8);

    return Column(
      children: causes.map((cause) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: itemBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getIconForCause(cause.icon),
                  size: 16,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cause.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cause.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProductsList(
    BuildContext context,
    bool isDark,
    List<RecommendationItem> products,
  ) {
    final theme = Theme.of(context);
    final textPrimary = isDark
        ? AppTheme.textPrimaryDark
        : AppTheme.textPrimaryLight;
    final textSecondary = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;
    final textTertiary = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textTertiaryLight;
    final primaryColor = theme.colorScheme.primary;
    final itemBgColor = isDark
        ? const Color(0xFF2E2E2E)
        : const Color(0xFFF8F8F8);

    return Column(
      children: products.map((product) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: itemBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.science_outlined,
                      size: 16,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      product.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  if (product.priceRange != null)
                    Text(
                      _formatPriceRange(product.priceRange!),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                product.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              if (product.usage != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: textTertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        product.usage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAlternatesList(
    BuildContext context,
    bool isDark,
    List<RecommendationItem> alternates,
  ) {
    final theme = Theme.of(context);
    final textPrimary = isDark
        ? AppTheme.textPrimaryDark
        : AppTheme.textPrimaryLight;
    final textSecondary = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;
    final itemBgColor = isDark
        ? const Color(0xFF2E2E2E)
        : const Color(0xFFF8F8F8);

    return Column(
      children: alternates.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: itemBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  size: 16,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLifestyleList(
    BuildContext context,
    bool isDark,
    List<RecommendationItem> lifestyle,
  ) {
    final theme = Theme.of(context);
    final textPrimary = isDark
        ? AppTheme.textPrimaryDark
        : AppTheme.textPrimaryLight;
    final textSecondary = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;
    final itemBgColor = isDark
        ? const Color(0xFF2E2E2E)
        : const Color(0xFFF8F8F8);

    return Column(
      children: lifestyle.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: itemBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.self_improvement,
                      size: 16,
                      color: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (item.difficulty != null || item.timeToResults != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (item.difficulty != null) ...[
                      _buildInfoChip(
                        context,
                        isDark,
                        Icons.fitness_center,
                        item.difficulty!,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (item.timeToResults != null)
                      _buildInfoChip(
                        context,
                        isDark,
                        Icons.timer_outlined,
                        item.timeToResults!,
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConsiderationsList(
    BuildContext context,
    bool isDark,
    List<RecommendationItem> considerations,
  ) {
    final theme = Theme.of(context);
    final textPrimary = isDark
        ? AppTheme.textPrimaryDark
        : AppTheme.textPrimaryLight;
    final textSecondary = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;
    final itemBgColor = isDark
        ? const Color(0xFF2E2E2E)
        : const Color(0xFFF8F8F8);

    return Column(
      children: considerations.map((item) {
        final isUrgent = item.urgency == 'high';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUrgent
                ? AppTheme.warningColor.withOpacity(isDark ? 0.2 : 0.1)
                : itemBgColor,
            borderRadius: BorderRadius.circular(8),
            border: isUrgent
                ? Border.all(color: AppTheme.warningColor.withOpacity(0.5))
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.warning_amber_outlined,
                  size: 16,
                  color: isUrgent ? Colors.orange : Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (item.actionRequired != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.actionRequired!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDosAndDontsSection(
    BuildContext context,
    bool isDark,
    List<RecommendationItem> dos,
    List<RecommendationItem> donts,
  ) {
    final theme = Theme.of(context);
    final textPrimary = isDark
        ? AppTheme.textPrimaryDark
        : AppTheme.textPrimaryLight;
    final surfaceColor = isDark
        ? AppTheme.surfaceColorDark
        : AppTheme.surfaceColorLight;
    final borderColor = isDark
        ? const Color(0xFF2E2E2E)
        : const Color(0xFFE5E5E5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Do's & Don'ts",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Do's Section
          if (dos.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Do's",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...dos.map((item) => _buildDoItem(context, isDark, item)),
          ],

          if (dos.isNotEmpty && donts.isNotEmpty) const SizedBox(height: 20),

          // Don'ts Section
          if (donts.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Don'ts",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...donts.map((item) => _buildDontItem(context, isDark, item)),
          ],
        ],
      ),
    );
  }

  Widget _buildDoItem(
    BuildContext context,
    bool isDark,
    RecommendationItem item,
  ) {
    final theme = Theme.of(context);
    final textPrimary = isDark
        ? AppTheme.textPrimaryDark
        : AppTheme.textPrimaryLight;
    final textSecondary = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textSecondary,
              height: 1.4,
            ),
          ),
          if (item.frequency != null) ...[
            const SizedBox(height: 6),
            Text(
              item.frequency!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDontItem(
    BuildContext context,
    bool isDark,
    RecommendationItem item,
  ) {
    final theme = Theme.of(context);
    final textPrimary = isDark
        ? AppTheme.textPrimaryDark
        : AppTheme.textPrimaryLight;
    final textSecondary = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textSecondary,
              height: 1.4,
            ),
          ),
          if (item.consequence != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.warning_amber, size: 14, color: AppTheme.errorColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.consequence!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicalDisclaimer(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final textSecondary = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;
    final textTertiary = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textTertiaryLight;
    final bgColor = isDark
        ? const Color(0xFF2E2E2E).withOpacity(0.5)
        : const Color(0xFFFAFAFA);
    final borderColor = isDark
        ? const Color(0xFF3E3E3E)
        : const Color(0xFFE5E5E5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: textTertiary),
              const SizedBox(width: 8),
              Text(
                'Medical Disclaimer',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This analysis is for informational purposes only and should not be considered medical advice. Results are based on AI analysis and may not be 100% accurate. For serious skin concerns, please consult a dermatologist or healthcare professional.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textTertiary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    bool isDark,
    IconData icon,
    String text,
  ) {
    final theme = Theme.of(context);
    final textSecondary = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;
    final chipBgColor = isDark
        ? const Color(0xFF3E3E3E)
        : const Color(0xFFEEEEEE);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }

  void _showAITooltip(BuildContext context, ConditionPrediction condition) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppTheme.textPrimaryDark
        : AppTheme.textPrimaryLight;
    final textSecondary = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;
    final textTertiary = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textTertiaryLight;
    final surfaceColor = isDark
        ? AppTheme.surfaceColorDark
        : AppTheme.surfaceColorLight;
    final primaryColor = theme.colorScheme.primary;
    final chipBgColor = isDark
        ? const Color(0xFF2E2E2E)
        : const Color(0xFFF5F5F5);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'AI Analysis',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              condition.displayName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getConditionDescription(condition.name),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: chipBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 20,
                    color: textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Our AI analyzed facial features, skin texture, and color patterns to detect this condition with ${condition.confidence.toStringAsFixed(0)}% confidence.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textTertiary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return AppTheme.errorColor;
      case 'moderate':
        return AppTheme.warningColor;
      case 'mild':
      default:
        return AppTheme.successColor;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  IconData _getIconForCause(String? iconName) {
    switch (iconName) {
      case 'oil-drop':
        return Icons.water_drop;
      case 'pore':
        return Icons.blur_circular;
      case 'sun':
        return Icons.wb_sunny;
      case 'bacteria':
        return Icons.bug_report;
      case 'hormone':
        return Icons.medical_services_outlined;
      case 'stress':
        return Icons.psychology;
      case 'diet':
        return Icons.restaurant;
      default:
        return Icons.help_outline;
    }
  }

  String _formatPriceRange(String priceRange) {
    switch (priceRange.toLowerCase()) {
      case 'budget':
        return '\$';
      case 'mid-range':
        return '\$\$';
      case 'premium':
        return '\$\$\$';
      default:
        return priceRange;
    }
  }

  String _getConditionDescription(String conditionName) {
    final normalized = conditionName.replaceAll('-', ' ').toLowerCase().trim();

    switch (normalized) {
      case 'wrinkles':
        return 'Fine lines and wrinkles are caused by aging, sun exposure, and repeated facial expressions. They appear as creases or folds in the skin, typically around the eyes, mouth, and forehead.';
      case 'skin redness':
        return 'Skin redness can be caused by irritation, inflammation, rosacea, or underlying skin conditions. It manifests as flushed or inflamed patches on the skin.';
      case 'acne':
        return 'Acne occurs when hair follicles become clogged with oil and dead skin cells. It can present as blackheads, whiteheads, pimples, or deeper cysts.';
      case 'dark spots':
      case 'hyperpigmentation':
        return 'Dark spots and hyperpigmentation are caused by sun damage, acne scarring, or hormonal changes. They appear as patches of skin that are darker than the surrounding area.';
      case 'dryness':
      case 'dry skin':
        return 'Dry skin occurs when the skin lacks moisture. It can feel tight, rough, or flaky, and may be itchy or uncomfortable.';
      case 'oily skin':
        return 'Oily skin is characterized by excess sebum production, leading to a shiny appearance and enlarged pores. It can contribute to acne and breakouts.';
      case 'blackheads':
        return 'Blackheads are a type of comedone that form when pores become clogged with oil and dead skin cells. The surface oxidizes and turns dark.';
      case 'whiteheads':
        return 'Whiteheads are closed comedones where the clogged pore is sealed beneath the skin surface, creating small white or flesh-colored bumps.';
      case 'enlarged pores':
      case 'englarged pores':
        return 'Enlarged pores are more visible openings on the skin surface, often caused by genetics, aging, or excess oil production.';
      case 'eyebags':
      case 'eye bags':
        return 'Eye bags are mild puffiness or swelling under the eyes, often caused by aging, lack of sleep, allergies, or fluid retention.';
      default:
        return 'This skin condition was detected by our AI analysis. For more information and personalized treatment recommendations, please consult a dermatologist.';
    }
  }
}
