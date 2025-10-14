import 'package:flutter/material.dart';
import 'package:nepika/features/dashboard/widgets/dashboard_navbar.dart';
import 'dart:math' as math;
import '../models/scan_analysis_models.dart';
import 'package:nepika/core/api_base.dart';

/// Data class for severity information
class SeverityData {
  final String label;
  final double percentage;
  final Color color;

  const SeverityData(this.label, this.percentage, this.color);
}

/// Detailed scan results screen matching the Figma design exactly
class ScanResultDetailsScreen extends StatefulWidget {
  final String reportId;

  const ScanResultDetailsScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<ScanResultDetailsScreen> createState() => _ScanResultDetailsScreenState();
}

class _ScanResultDetailsScreenState extends State<ScanResultDetailsScreen> {
  String? selectedCondition;
  late ScrollController _scrollController;
  late ScrollController _horizontalScrollController;
  final Map<String, GlobalKey> _sectionKeys = {};
  final Map<String, GlobalKey> _chipKeys = {};

  // Data fetching state
  bool _isLoading = true;
  String? _error;
  List<RecommendationGroup> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _horizontalScrollController = ScrollController();

    // Listen to scroll changes to update header
    _scrollController.addListener(_onScroll);

    // Fetch report data
    _fetchReportData();
  }

  /// Fetch report data from API
  Future<void> _fetchReportData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      debugPrint('🔍 Fetching report details for reportId: ${widget.reportId}');

      // Make API request
      final response = await ApiBase().request(
        path: '/training/report/${widget.reportId}',
        method: 'GET',
      );

      debugPrint('📡 Report API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Raw API response: ${response.data}');
        
        // Handle both array and object responses
        List<dynamic> data;
        if (response.data is List<dynamic>) {
          data = response.data as List<dynamic>;
        } else if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;
          // Check if the object has a recommendations array
          if (responseMap.containsKey('recommendations')) {
            data = responseMap['recommendations'] as List<dynamic>;
          } else if (responseMap.containsKey('data')) {
            data = responseMap['data'] as List<dynamic>;
          } else {
            // If it's an empty object or doesn't contain expected data, use empty array
            data = [];
          }
        } else {
          data = [];
        }
        
        debugPrint('✅ Received ${data.length} skin issue recommendations');

        // Parse recommendations from API response
        _recommendations = data
            .map((item) => RecommendationGroup.fromJson(item as Map<String, dynamic>))
            .toList();

        // Set the primary condition as selected by default
        if (_recommendations.isNotEmpty) {
          selectedCondition = _recommendations.first.skinIssue;
          debugPrint('📌 Primary condition: $selectedCondition');
          
          // Create keys for each section and chip
          for (final group in _recommendations) {
            _sectionKeys[group.skinIssue] = GlobalKey();
            _chipKeys[group.skinIssue] = GlobalKey();
          }
        } else {
          debugPrint('⚠️ No recommendations found in response');
        }

        setState(() {
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        throw Exception('Report not found or does not belong to you');
      } else {
        throw Exception('Failed to load report: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching report data: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
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
    if (!mounted) return;

    // Find which section is currently most visible
    String? newSelectedCondition;
    double maxVisibleArea = 0;

    for (final group in _recommendations) {
      final key = _sectionKeys[group.skinIssue];
      if (key?.currentContext != null) {
        final RenderBox? renderBox = key!.currentContext!.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;

          // Calculate visible area of this section
          final viewportHeight = MediaQuery.of(context).size.height;
          final sectionTop = position.dy;
          final sectionBottom = position.dy + size.height;

          // Calculate intersection with viewport (considering header height)
          final headerHeight = 150.0; // Approximate header height
          final visibleTop = math.max(sectionTop, headerHeight);
          final visibleBottom = math.min(sectionBottom, viewportHeight);

          if (visibleBottom > visibleTop) {
            final visibleArea = visibleBottom - visibleTop;
            if (visibleArea > maxVisibleArea) {
              maxVisibleArea = visibleArea;
              newSelectedCondition = group.skinIssue;
            }
          }
        }
      }
    }

    // Update selected condition if it changed
    if (newSelectedCondition != null && newSelectedCondition != selectedCondition) {
      setState(() {
        selectedCondition = newSelectedCondition;
      });

      // Auto-scroll horizontally to make the selected chip visible
      _autoScrollToChip(newSelectedCondition);
    }
  }


  /// Auto-scroll horizontally to make the selected chip visible
  void _autoScrollToChip(String skinIssue) {
    // Use a slight delay to ensure the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chipKey = _chipKeys[skinIssue];
      if (chipKey?.currentContext != null && _horizontalScrollController.hasClients) {
        try {
          final RenderBox? chipRenderBox = chipKey!.currentContext!.findRenderObject() as RenderBox?;
          if (chipRenderBox != null) {
            // Get the horizontal ListView's RenderBox
            final RenderBox? scrollViewRenderBox = _horizontalScrollController.position.context.storageContext.findRenderObject() as RenderBox?;
            
            if (scrollViewRenderBox != null) {
              // Calculate chip position relative to the scroll view
              final chipPosition = chipRenderBox.localToGlobal(Offset.zero);
              final scrollViewPosition = scrollViewRenderBox.localToGlobal(Offset.zero);
              
              final chipSize = chipRenderBox.size;
              final screenWidth = MediaQuery.of(context).size.width;
              
              // Calculate relative position within the scroll view
              final chipRelativeLeft = chipPosition.dx - scrollViewPosition.dx;
              final chipRelativeRight = chipRelativeLeft + chipSize.width;
              
              // Calculate visible area of the scroll view (considering padding)
              final visibleLeft = 0.0;
              final visibleRight = screenWidth - 40.0; // 40 is total horizontal padding
              
              // Check if chip is outside the visible area
              double? targetScrollOffset;
              
              if (chipRelativeLeft < visibleLeft) {
                // Chip is hidden on the left side
                targetScrollOffset = _horizontalScrollController.offset + chipRelativeLeft - 20;
              } else if (chipRelativeRight > visibleRight) {
                // Chip is hidden on the right side
                targetScrollOffset = _horizontalScrollController.offset + chipRelativeRight - visibleRight + 20;
              }
              
              // Animate to target position if needed
              if (targetScrollOffset != null) {
                _horizontalScrollController.animateTo(
                  math.max(0, targetScrollOffset), // Ensure not negative
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            }
          }
        } catch (e) {
          // Ignore errors during auto-scroll (widget might not be ready)
          debugPrint('Auto-scroll error: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Show loading state
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF0F9FF),
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

    // Show error state
    if (_error != null) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF0F9FF),
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
                          _error!,
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

    // Show content
    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF0F9FF), // Light blue background
      body: SafeArea(
        child: Column(
          children: [
            // Status bar + Back navigation
            _buildHeader(context, isDark),

            // Sticky condition filter chips
            _buildConditionFilters(isDark),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: 30),

                    // All recommendations content
                    _buildAllRecommendationsContent(isDark),

                    const SizedBox(height: 100), // Space for dashboard navigation
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: DashboardNavBar(
      //   selectedIndex: 0, // Home tab
      //   onNavBarTap: (index, route) {
      //     // Pop back to face scan result, then navigate to dashboard route
      //     Navigator.of(context).pop();
      //     // Use root navigator to navigate to dashboard
      //     Navigator.of(context, rootNavigator: true).pushReplacementNamed(route);
      //   },
      // ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      height: 47,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_ios,
                  size: 20,
                  color: isDark ? Colors.white : const Color(0xFF07223B),
                ),
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

            // Map skin issues to display names exactly as shown in Figma
            final displayName = _getDisplayNameForSkinIssue(group.skinIssue);

            return Padding(
              padding: const EdgeInsets.only(right: 15),
              child: GestureDetector(
                key: _chipKeys[group.skinIssue],
                onTap: () {
                  _scrollToSection(group.skinIssue);
                },
                child: Container(
                  constraints: const BoxConstraints(
                    maxHeight: 40,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF3898ED)
                        : Colors.transparent,
                    border: Border.all(
                      color: const Color(0xFF3898ED),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontFamily: 'HelveticaNowDisplay',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF3898ED),
                      ),
                      textAlign: TextAlign.center,
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

  /// Map skin issues from API to display names matching Figma design
  String _getDisplayNameForSkinIssue(String skinIssue) {
    switch (skinIssue.toLowerCase()) {
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
        return 'Enlarged Pores';
      case 'blackheads':
        return 'Blackheads';
      case 'whiteheads':
        return 'Whiteheads';
      default:
        // Fallback to capitalizing the skin issue name
        return skinIssue.split(' ')
            .map((word) => word.isNotEmpty 
                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                : word)
            .join(' ');
    }
  }

  /// Scroll to a specific section
  void _scrollToSection(String skinIssue) {
    final key = _sectionKeys[skinIssue];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Build all recommendations content in a single scrollable view
  Widget _buildAllRecommendationsContent(bool isDark) {
    // Show empty state if no recommendations
    if (_recommendations.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 64,
                  color: isDark ? Colors.white54 : Colors.grey[400],
                ),
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
                // Section title and description
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
                
                
                // Progress Summary Chart
                // _buildProgressSummaryChart(group, isDark),
                
                const SizedBox(height: 30),
                
                // Suggested Solutions section
                Text(
                  'Suggested Solutions',
                  style: TextStyle(
                    fontFamily: 'HelveticaNowDisplay',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white : const Color(0xFF07223B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
                
                const SizedBox(height: 10),
                
                // Product recommendation cards
                _buildProductRecommendations(group.recommendations, isDark),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }


  Widget _buildProductRecommendations(List<ProductRecommendation> recommendations, bool isDark) {
    // Group recommendations in pairs for the 2-column layout
    final List<Widget> rows = [];
    
    for (int i = 0; i < recommendations.length; i += 2) {
      final List<Widget> rowChildren = [];
      
      // First card
      rowChildren.add(
        Expanded(
          child: _buildProductCard(recommendations[i], isDark),
        ),
      );
      
      // Second card (if exists)
      if (i + 1 < recommendations.length) {
        rowChildren.add(const SizedBox(width: 15));
        rowChildren.add(
          Expanded(
            child: _buildProductCard(recommendations[i + 1], isDark),
          ),
        );
      }
      
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowChildren,
        ),
      );
      
      if (i + 2 < recommendations.length) {
        rows.add(const SizedBox(height: 15));
      }
    }
    
    return Column(children: rows);
  }

  Widget _buildProductCard(ProductRecommendation recommendation, bool isDark) {
    final isClinicallProven = recommendation.isClinicallyProven;
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.1) 
            : Colors.white.withValues(alpha: 0.6),
        border: Border.all(
          color: const Color(0xFF3898ED),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with info icon and product name
          Row(
            children: [
              Container(
                width: 13,
                height: 13,
                decoration: const BoxDecoration(
                  color: Color(0xFF3898ED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info,
                  size: 8,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  recommendation.product,
                  style: TextStyle(
                    fontFamily: 'HelveticaNowDisplay',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white : const Color(0xFF07223B),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 5),
          
          // Effectiveness percentage
          Text(
            '${recommendation.effectivenessPercentage}%',
            style: TextStyle(
              fontFamily: 'HelveticaNowDisplay',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF07223B),
            ),
          ),
          
          const SizedBox(height: 5),
          
          // Effectiveness badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isClinicallProven) ...[
                  Container(
                    width: 15,
                    height: 15,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDFAE3E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    recommendation.effectivenessLevel,
                    style: TextStyle(
                      fontFamily: 'HelveticaNowDisplay',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isClinicallProven 
                          ? const Color(0xFF009C44) 
                          : const Color(0xFFDFAE3E),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 5),
          
          // Description
          Text(
            recommendation.description,
            style: TextStyle(
              fontFamily: 'HelveticaNowDisplay',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white : const Color(0xFF07223B),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
        ],
      ),
    );
  }


  /// Build progress summary chart for each recommendation
  Widget _buildProgressSummaryChart(RecommendationGroup group, bool isDark) {
    // Get severity and confidence data from the API
    final severity = _getSeverityForCondition(group.skinIssue);
    final improvementPotential = _getImprovementPotential(group.recommendations);
    final timelineWeeks = _getTimelineForCondition(group.skinIssue);
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart title
          Text(
            'Progress Summary',
            style: TextStyle(
              fontFamily: 'HelveticaNowDisplay',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF07223B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
          ),
          
          const SizedBox(height: 15),
          
          // Progress metrics
          Row(
            children: [
              // Severity indicator
              Expanded(
                child: _buildProgressMetric(
                  'Current Severity',
                  severity.label,
                  severity.percentage,
                  severity.color,
                  isDark,
                ),
              ),
              
              const SizedBox(width: 15),
              
              // Improvement potential
              Expanded(
                child: _buildProgressMetric(
                  'Improvement Potential',
                  '$improvementPotential%',
                  improvementPotential / 100,
                  const Color(0xFF4CAF50),
                  isDark,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          // Timeline
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: isDark ? Colors.white70 : const Color(0xFF7F7F7F),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Expected improvement timeline: $timelineWeeks weeks',
                  style: TextStyle(
                    fontFamily: 'HelveticaNowDisplay',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white70 : const Color(0xFF7F7F7F),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual progress metric widget
  Widget _buildProgressMetric(String label, String value, double percentage, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'HelveticaNowDisplay',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: isDark ? Colors.white70 : const Color(0xFF7F7F7F),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
        ),
        
        const SizedBox(height: 8),
        
        // Progress bar
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 6),
        
        Text(
          value,
          style: TextStyle(
            fontFamily: 'HelveticaNowDisplay',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
        ),
      ],
    );
  }

  /// Get severity data for a specific condition
  SeverityData _getSeverityForCondition(String condition) {
    // This would typically come from the API, but we'll use mock data for now
    switch (condition.toLowerCase()) {
      case 'wrinkles':
        return SeverityData('Moderate', 0.65, const Color(0xFFFF9800));
      case 'skin redness':
        return SeverityData('Mild', 0.35, const Color(0xFF4CAF50));
      case 'acne':
        return SeverityData('Severe', 0.85, const Color(0xFFF44336));
      case 'dark spots':
        return SeverityData('Moderate', 0.55, const Color(0xFFFF9800));
      case 'dry skin':
      case 'dryness':
        return SeverityData('Mild', 0.40, const Color(0xFF4CAF50));
      default:
        return SeverityData('Moderate', 0.50, const Color(0xFFFF9800));
    }
  }

  /// Get improvement potential based on recommendations
  int _getImprovementPotential(List<ProductRecommendation> recommendations) {
    // Calculate based on the effectiveness of recommendations
    if (recommendations.isEmpty) return 50;
    
    final avgEffectiveness = recommendations
        .map((r) => r.effectivenessPercentage)
        .reduce((a, b) => a + b) / recommendations.length;
    
    return (avgEffectiveness * 0.8).round(); // 80% of product effectiveness as improvement potential
  }

  /// Get expected timeline for condition improvement
  int _getTimelineForCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'wrinkles':
        return 12; // Anti-aging takes longer
      case 'skin redness':
        return 4; // Redness can improve quickly
      case 'acne':
        return 8; // Moderate timeline for acne
      case 'dark spots':
        return 16; // Hyperpigmentation takes time
      case 'dry skin':
      case 'dryness':
        return 2; // Hydration improves quickly
      default:
        return 8; // Default moderate timeline
    }
  }

  String _getDescriptionForCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'wrinkles':
        return 'Fine lines and wrinkles are caused by aging, sun exposure, and repeated facial expressions. Anti-aging ingredients help stimulate collagen production and smooth the skin surface.';
      case 'skin redness':
        return 'Skin redness can be caused by irritation, inflammation, or underlying skin conditions. Soothing ingredients help calm the skin and reduce visible redness.';
      case 'acne':
        return 'Acne occurs when pores become clogged with oil and dead skin cells. Targeted treatments help unclog pores and prevent future breakouts.';
      case 'dark spots':
        return 'Dark spots and hyperpigmentation are caused by sun damage, acne scarring, or hormonal changes. Brightening ingredients help even out skin tone.';
      case 'dryness':
      case 'dry skin':
        return 'Dehydration causes skin to feel dry, tight, or rough. Moisturizing ingredients increase hydration and support the skin barrier.';
      default:
        return 'This skin condition requires targeted care with appropriate skincare ingredients to improve its appearance and health.';
    }
  }
}