import 'package:flutter/material.dart';
import 'package:nepika/core/api_base.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nepika/core/config/constants/app_constants.dart';
import '../models/scan_analysis_models.dart';
import 'scan_result_details_screen.dart';

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
    _fetchScanReport();
  }

  Future<void> _fetchScanReport() async {
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

      // Fetch report from API
      final response = await ApiBase().request(
        path: '/training/reports',
        method: 'GET',
        query: {'report_id': widget.reportId},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true && data['report'] != null) {
          // Transform API response to ScanAnalysisResponse
          _scanResults = _transformToScanAnalysisResponse(data['report']);

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Report not found');
      } else {
        throw Exception('Failed to load report: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching scan report: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  /// Transform API report data to ScanAnalysisResponse format
  ScanAnalysisResponse _transformToScanAnalysisResponse(Map<String, dynamic> report) {
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
              .toList() ??
          [],
      classesFound: (areaDetectionSummary?['classes_found'] as List<dynamic>?)
              ?.map((c) => c as String)
              .toList() ??
          [],
      modelThreshold: (areaDetectionSummary?['model_threshold'] as num?)?.toDouble() ?? 0.1,
    );

    // Create recommendation groups from top conditions
    final recommendations = <RecommendationGroup>[];
    for (var i = 0; i < sortedPredictions.length && i < 5; i++) {
      final prediction = sortedPredictions[i];
      if (prediction.confidence > 0.1) {
        recommendations.add(RecommendationGroup(
          skinIssue: prediction.displayName,
          recommendations: [
            ProductRecommendation(
              product: 'Treatment for ${prediction.displayName}',
              description: 'Detected with ${prediction.confidencePercentage} confidence',
            ),
          ],
        ));
      }
    }

    return ScanAnalysisResponse(
      success: true,
      timestamp: report['scan_datetime'] ?? DateTime.now().toIso8601String(),
      processingTimeSeconds: 0.0,
      conditionAnalysis: conditionAnalysis,
      skinTypeAnalysis: const SkinTypeAnalysis(success: true),
      areaDetectionAnalysis: areaDetectionAnalysis,
      recommendations: recommendations,
      imageUploaded: true,
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
                onPressed: _fetchScanReport,
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

    // Navigate to the actual scan result details screen
    // Note: ScanResultDetailsScreen now fetches its own data via reportId
    // This loader screen is redundant but keeping for backwards compatibility
    return ScanResultDetailsScreen(reportId: widget.reportId);
  }
}
