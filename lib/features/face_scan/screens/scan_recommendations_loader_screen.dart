import 'package:flutter/material.dart';
import 'package:nepika/core/api_base.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/config/constants/theme.dart';
import '../models/scan_analysis_models.dart';
import '../models/detection_models.dart';
import 'scan_recommendations_screen.dart';

/// Loader screen that fetches scan report by ID and displays the new recommendations UI
class ScanRecommendationsLoaderScreen extends StatefulWidget {
  final String reportId;
  final String? condition; // Optional initial condition to scroll to

  const ScanRecommendationsLoaderScreen({
    super.key,
    required this.reportId,
    this.condition,
  });

  @override
  State<ScanRecommendationsLoaderScreen> createState() => _ScanRecommendationsLoaderScreenState();
}

class _ScanRecommendationsLoaderScreenState extends State<ScanRecommendationsLoaderScreen> {
  bool _isLoading = true;
  String? _error;
  ScanAnalysisResponse? _scanResults;

  @override
  void initState() {
    super.initState();
    _fetchScanData();
  }

  Future<void> _fetchScanData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      debugPrint('📊 Fetching scan data for reportId: ${widget.reportId}');

      // Step 1: Fetch report basic data
      final reportResponse = await ApiBase().request(
        path: '/training/reports',
        method: 'GET',
        query: {'report_id': widget.reportId},
      );

      debugPrint('📡 Report API response status: ${reportResponse.statusCode}');

      if (reportResponse.statusCode != 200) {
        if (reportResponse.statusCode == 404) {
          throw Exception('Report not found');
        }
        throw Exception('Failed to load report: ${reportResponse.statusCode}');
      }

      final reportData = reportResponse.data;
      if (reportData['success'] != true || reportData['report'] == null) {
        throw Exception('Invalid report response format');
      }

      final report = reportData['report'] as Map<String, dynamic>;

      // Step 2: Fetch V2 recommendations
      debugPrint('📊 Fetching V2 recommendations for reportId: ${widget.reportId}');

      final recommendationsResponse = await ApiBase().request(
        path: '/face-scan-v2/reports/${widget.reportId}/recommendations',
        method: 'GET',
      );

      debugPrint('📡 Recommendations API response status: ${recommendationsResponse.statusCode}');

      RecommendationsData recommendations;

      if (recommendationsResponse.statusCode == 200 && recommendationsResponse.data != null) {
        final recData = recommendationsResponse.data as Map<String, dynamic>;

        if (recData['success'] == true && recData['data'] != null) {
          debugPrint('✅ V2 recommendations fetched successfully');
          recommendations = RecommendationsData.fromJson(recData['data'] as Map<String, dynamic>);
        } else {
          debugPrint('⚠️ V2 recommendations response invalid, using empty data');
          recommendations = _createEmptyRecommendations();
        }
      } else {
        debugPrint('⚠️ Failed to fetch V2 recommendations, using empty data');
        recommendations = _createEmptyRecommendations();
      }

      // Transform report data to ScanAnalysisResponse
      _scanResults = _transformToScanAnalysisResponse(report, recommendations);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching scan data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  RecommendationsData _createEmptyRecommendations() {
    return const RecommendationsData(
      personalizedFor: PersonalizedFor(
        skinType: 'Unknown',
        severityMap: {},
      ),
      groups: RecommendationGroups(
        causes: [],
        products: [],
        alternateSolutions: [],
        lifestyleSuggestions: [],
        importantConsiderations: [],
        dos: [],
        donts: [],
      ),
      flatItems: [],
    );
  }

  /// Transform API report data to ScanAnalysisResponse format
  ScanAnalysisResponse _transformToScanAnalysisResponse(
    Map<String, dynamic> report,
    RecommendationsData recommendations,
  ) {
    // Extract condition results
    final conditionResult = report['condition_result'] as Map<String, dynamic>?;
    final areaDetectionSummary = report['area_detection_summary'] as Map<String, dynamic>?;

    // Create condition predictions from condition_result
    final sortedPredictions = <ConditionPrediction>[];
    if (conditionResult != null) {
      conditionResult.forEach((condition, confidence) {
        sortedPredictions.add(ConditionPrediction(
          name: condition,
          confidence: (confidence as num).toDouble(),
        ));
      });
      // Sort by confidence descending
      sortedPredictions.sort((a, b) => b.confidence.compareTo(a.confidence));
    }

    // Create ConditionAnalysis
    final conditionAnalysis = ConditionAnalysis(
      prediction: report['skin_condition_prediction'] ?? 'Unknown',
      sortedPredictions: sortedPredictions,
    );

    // Create AreaDetectionAnalysis
    final areaDetectionAnalysis = AreaDetectionAnalysis(
      totalDetections: areaDetectionSummary?['total_detections'] ?? 0,
      detections: (areaDetectionSummary?['detections'] as List<dynamic>?)
              ?.map((d) => Detection.fromJson(d as Map<String, dynamic>))
              .toList().cast<Detection>() ??
          <Detection>[],
      classesFound: (areaDetectionSummary?['classes_found'] as List<dynamic>?)
              ?.map((c) => c as String)
              .toList() ??
          [],
      modelThreshold: (areaDetectionSummary?['model_threshold'] as num?)?.toDouble() ?? 0.1,
    );

    return ScanAnalysisResponse(
      success: true,
      timestamp: report['scan_datetime'] ?? DateTime.now().toIso8601String(),
      processingTimeSeconds: 0.0,
      conditionAnalysis: conditionAnalysis,
      skinTypeAnalysis: SkinTypeAnalysis(
        prediction: recommendations.personalizedFor.skinType,
        confidence: 0.0,
        allPredictions: const {},
        adequateLighting: true,
        success: true,
      ),
      areaDetectionAnalysis: areaDetectionAnalysis,
      recommendations: recommendations,
      imageUploaded: true,
      reportId: widget.reportId,
    );
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
                      Text('Loading scan results...'),
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
                          onPressed: _fetchScanData,
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

    if (_scanResults == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, isDark),
              const Expanded(
                child: Center(
                  child: Text('No scan results available'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show the recommendations screen with loaded data
    return ScanRecommendationsScreen(
      scanResponse: _scanResults!,
      initialCondition: widget.condition,
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
        final textPrimary = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;

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
          ),        ],
      ),
    );
  }
}
