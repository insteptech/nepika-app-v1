import 'package:flutter/material.dart';
import 'package:nepika/core/api_base.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import '../models/scan_analysis_models.dart';
import '../models/detection_models.dart';
import 'scan_recommendations_screen.dart';

/// Loader screen that fetches scan report by ID and displays results
class ScanReportLoaderScreen extends StatefulWidget {
  final String reportId;

  const ScanReportLoaderScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<ScanReportLoaderScreen> createState() => _ScanReportLoaderScreenState();
}

class _ScanReportLoaderScreenState extends State<ScanReportLoaderScreen> {
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

      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.accessTokenKey);

      if (token == null) {
        throw Exception('Not authenticated');
      }

      debugPrint('📊 Fetching scan data for reportId: ${widget.reportId}');

      // Step 1: Fetch report from API
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
        throw Exception('Invalid response format');
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

      // Transform to ScanAnalysisResponse
      _scanResults = _transformToScanAnalysisResponse(report, recommendations);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching scan report: $e');
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
        // Handle both String and num types from backend
        double confidenceValue = 0.0;
        if (confidence is num) {
          confidenceValue = confidence.toDouble();
        } else if (confidence is String) {
          confidenceValue = double.tryParse(confidence) ?? 0.0;
        }
        sortedPredictions.add(ConditionPrediction(
          name: condition,
          confidence: confidenceValue,
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Loading Report'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Fetching scan results...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load report',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchScanData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_scanResults == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: const Center(
          child: Text('No scan results available'),
        ),
      );
    }

    // Navigate to the new recommendations screen with loaded data
    return ScanRecommendationsScreen(scanResponse: _scanResults!);
  }
}
