import 'package:equatable/equatable.dart';

import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../../../core/error/failures.dart';
import '../entities/face_scan_result.dart';
import '../entities/skin_analysis.dart';

/// Use case for processing and enhancing scan results.
/// This encapsulates business logic for analyzing scan data and generating insights.
class ProcessScanResultsUseCase extends UseCase<ProcessedScanResult, ProcessScanResultsParams> {
  ProcessScanResultsUseCase();

  @override
  Future<Result<ProcessedScanResult>> call(ProcessScanResultsParams params) async {
    try {
      // Validate input parameters
      final validationFailure = _validateParams(params);
      if (validationFailure != null) {
        return failure(validationFailure);
      }

      // Process the scan results
      final processedResult = await _processScanResults(params);
      return success(processedResult);
    } catch (e) {
      return failure(
        ScanProcessingFailure(
          message: 'Failed to process scan results: $e',
        ),
      );
    }
  }

  /// Validates the input parameters
  ScanProcessingFailure? _validateParams(ProcessScanResultsParams params) {
    if (!params.scanResult.isSuccessful) {
      return const ScanProcessingFailure(
        message: 'Cannot process unsuccessful scan result',
      );
    }

    if (params.scanResult.skinAnalysis.skinConditionPredictions.isEmpty) {
      return const ScanProcessingFailure(
        message: 'Scan result missing skin analysis data',
      );
    }

    return null;
  }

  /// Processes the scan results and generates insights
  Future<ProcessedScanResult> _processScanResults(ProcessScanResultsParams params) async {
    final scanResult = params.scanResult;
    final skinAnalysis = scanResult.skinAnalysis;

    // Generate detailed insights
    final insights = _generateDetailedInsights(skinAnalysis);
    
    // Categorize skin condition severity
    final severityAssessment = _assessOverallSeverity(skinAnalysis);
    
    // Generate recommendations
    final recommendations = _generateRecommendations(skinAnalysis, severityAssessment);
    
    // Create trend analysis if historical data is available
    final trendAnalysis = params.historicalResults != null 
        ? _analyzeTrends(scanResult, params.historicalResults!)
        : null;
    
    // Calculate improvement metrics
    final improvementMetrics = params.previousResult != null
        ? _calculateImprovementMetrics(scanResult, params.previousResult!)
        : null;

    return ProcessedScanResult(
      originalResult: scanResult,
      detailedInsights: insights,
      severityAssessment: severityAssessment,
      recommendations: recommendations,
      trendAnalysis: trendAnalysis,
      improvementMetrics: improvementMetrics,
      processedAt: DateTime.now(),
    );
  }

  /// Generates detailed insights from skin analysis
  List<SkinInsight> _generateDetailedInsights(SkinAnalysis analysis) {
    final insights = <SkinInsight>[];

    // Analyze overall skin health
    if (analysis.overallSkinScore >= 80) {
      insights.add(
        SkinInsight(
          category: InsightCategory.positive,
          title: 'Excellent Skin Health',
          description: 'Your skin shows excellent overall health with minimal concerns.',
          confidence: 0.9,
        ),
      );
    } else if (analysis.overallSkinScore >= 60) {
      insights.add(
        SkinInsight(
          category: InsightCategory.neutral,
          title: 'Good Skin Condition',
          description: 'Your skin is in good condition with some areas for improvement.',
          confidence: 0.8,
        ),
      );
    } else {
      insights.add(
        SkinInsight(
          category: InsightCategory.concern,
          title: 'Areas Need Attention',
          description: 'Several skin concerns have been identified that could benefit from targeted care.',
          confidence: 0.85,
        ),
      );
    }

    // Analyze dominant conditions
    final topConditions = analysis.getTopConditions(3);
    for (final condition in topConditions) {
      if (condition.confidence > 0.3) {
        insights.add(_generateConditionInsight(condition));
      }
    }

    // Analyze problem areas
    final problemAreas = analysis.problemAreas;
    if (problemAreas.isNotEmpty) {
      insights.add(
        SkinInsight(
          category: InsightCategory.actionable,
          title: 'Focus Areas Identified',
          description: 'Specific facial areas showing concerns: ${problemAreas.map((a) => a.areaName).join(', ')}',
          confidence: 0.8,
        ),
      );
    }

    return insights;
  }

  /// Generates insights for specific skin conditions
  SkinInsight _generateConditionInsight(SkinConditionPrediction condition) {
    // This would typically use a lookup table or AI model for condition-specific insights
    final conditionInsights = {
      'acne': SkinInsight(
        category: InsightCategory.concern,
        title: 'Acne Detected',
        description: 'Active acne lesions identified. Consider gentle, non-comedogenic skincare products.',
        confidence: condition.confidence,
      ),
      'wrinkles': SkinInsight(
        category: InsightCategory.aging,
        title: 'Fine Lines Present',
        description: 'Age-related changes detected. Retinoids and moisturizers may help.',
        confidence: condition.confidence,
      ),
      'dark_spots': SkinInsight(
        category: InsightCategory.pigmentation,
        title: 'Hyperpigmentation',
        description: 'Dark spots identified. Sun protection and vitamin C may be beneficial.',
        confidence: condition.confidence,
      ),
      'redness': SkinInsight(
        category: InsightCategory.sensitivity,
        title: 'Skin Irritation',
        description: 'Redness detected. Consider gentle, fragrance-free products.',
        confidence: condition.confidence,
      ),
    };

    return conditionInsights[condition.condition.toLowerCase()] ??
        SkinInsight(
          category: InsightCategory.neutral,
          title: '${condition.condition} Detected',
          description: 'Skin condition identified with ${condition.confidencePercentage}% confidence.',
          confidence: condition.confidence,
        );
  }

  /// Assesses overall severity of skin concerns
  SkinSeverityAssessment _assessOverallSeverity(SkinAnalysis analysis) {
    final dominantConfidence = analysis.dominantConditionConfidence;
    final problemAreaCount = analysis.problemAreas.length;
    final overallScore = analysis.overallSkinScore;

    SkinSeverityLevel level;
    if (overallScore >= 80 && dominantConfidence < 0.3) {
      level = SkinSeverityLevel.minimal;
    } else if (overallScore >= 60 && dominantConfidence < 0.6) {
      level = SkinSeverityLevel.mild;
    } else if (overallScore >= 40 && dominantConfidence < 0.8) {
      level = SkinSeverityLevel.moderate;
    } else {
      level = SkinSeverityLevel.significant;
    }

    return SkinSeverityAssessment(
      level: level,
      overallScore: overallScore,
      primaryConcerns: analysis.getTopConditions(2),
      affectedAreaCount: problemAreaCount,
      assessedAt: DateTime.now(),
    );
  }

  /// Generates personalized recommendations
  List<SkinRecommendation> _generateRecommendations(
    SkinAnalysis analysis,
    SkinSeverityAssessment severity,
  ) {
    final recommendations = <SkinRecommendation>[];

    // General recommendations based on severity
    switch (severity.level) {
      case SkinSeverityLevel.minimal:
        recommendations.add(
          SkinRecommendation(
            type: RecommendationType.maintenance,
            title: 'Maintain Current Routine',
            description: 'Your skin looks great! Continue with your current skincare routine.',
            priority: RecommendationPriority.low,
          ),
        );
        break;
      case SkinSeverityLevel.mild:
        recommendations.add(
          SkinRecommendation(
            type: RecommendationType.prevention,
            title: 'Preventive Care',
            description: 'Focus on consistent sun protection and gentle cleansing.',
            priority: RecommendationPriority.medium,
          ),
        );
        break;
      case SkinSeverityLevel.moderate:
        recommendations.add(
          SkinRecommendation(
            type: RecommendationType.treatment,
            title: 'Targeted Treatment',
            description: 'Consider targeted treatments for identified concerns.',
            priority: RecommendationPriority.high,
          ),
        );
        break;
      case SkinSeverityLevel.significant:
        recommendations.add(
          SkinRecommendation(
            type: RecommendationType.professional,
            title: 'Professional Consultation',
            description: 'Consider consulting with a dermatologist for comprehensive treatment.',
            priority: RecommendationPriority.urgent,
          ),
        );
        break;
    }

    // Condition-specific recommendations
    final topConditions = analysis.getTopConditions(3);
    for (final condition in topConditions) {
      if (condition.confidence > 0.4) {
        recommendations.addAll(_getConditionRecommendations(condition));
      }
    }

    return recommendations;
  }

  /// Gets recommendations for specific conditions
  List<SkinRecommendation> _getConditionRecommendations(SkinConditionPrediction condition) {
    // This would typically use a comprehensive recommendation engine
    switch (condition.condition.toLowerCase()) {
      case 'acne':
        return [
          SkinRecommendation(
            type: RecommendationType.product,
            title: 'Gentle Cleanser',
            description: 'Use a gentle, non-comedogenic cleanser twice daily.',
            priority: RecommendationPriority.high,
          ),
          SkinRecommendation(
            type: RecommendationType.ingredient,
            title: 'Salicylic Acid',
            description: 'Consider products with salicylic acid for acne treatment.',
            priority: RecommendationPriority.medium,
          ),
        ];
      case 'wrinkles':
        return [
          SkinRecommendation(
            type: RecommendationType.ingredient,
            title: 'Retinoids',
            description: 'Incorporate retinoid products to address fine lines.',
            priority: RecommendationPriority.high,
          ),
        ];
      default:
        return [];
    }
  }

  /// Analyzes trends across multiple scans
  SkinTrendAnalysis? _analyzeTrends(
    FaceScanResult currentResult,
    List<FaceScanResult> historicalResults,
  ) {
    if (historicalResults.length < 2) return null;

    final recentResults = [...historicalResults, currentResult]
      ..sort((a, b) => a.scanTimestamp.compareTo(b.scanTimestamp));

    // Calculate score trends
    final scores = recentResults.map((r) => r.skinAnalysis.overallSkinScore).toList();
    final scoreTrend = _calculateTrend(scores);

    // Calculate condition trends
    final conditionTrends = <String, TrendDirection>{};
    final allConditions = <String>{};
    
    for (final result in recentResults) {
      allConditions.addAll(result.skinAnalysis.skinConditionPredictions.keys);
    }

    for (final condition in allConditions) {
      final conditionScores = recentResults
          .map((r) => r.skinAnalysis.skinConditionPredictions[condition] ?? 0.0)
          .toList();
      conditionTrends[condition] = _calculateTrend(conditionScores);
    }

    return SkinTrendAnalysis(
      overallScoreTrend: scoreTrend,
      conditionTrends: conditionTrends,
      analyzedPeriod: Duration(
        days: currentResult.scanTimestamp.difference(recentResults.first.scanTimestamp).inDays,
      ),
      dataPoints: recentResults.length,
    );
  }

  /// Calculates trend direction from a series of values
  TrendDirection _calculateTrend(List<double> values) {
    if (values.length < 2) return TrendDirection.stable;

    final firstHalf = values.take(values.length ~/ 2).toList();
    final secondHalf = values.skip(values.length ~/ 2).toList();

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    const threshold = 0.05; // 5% change threshold
    final change = (secondAvg - firstAvg) / firstAvg;

    if (change > threshold) return TrendDirection.improving;
    if (change < -threshold) return TrendDirection.worsening;
    return TrendDirection.stable;
  }

  /// Calculates improvement metrics comparing two results
  ImprovementMetrics _calculateImprovementMetrics(
    FaceScanResult current,
    FaceScanResult previous,
  ) {
    final scoreChange = current.skinAnalysis.overallSkinScore - previous.skinAnalysis.overallSkinScore;
    final timespan = current.scanTimestamp.difference(previous.scanTimestamp);

    // Calculate condition changes
    final conditionChanges = <String, double>{};
    final allConditions = {
      ...current.skinAnalysis.skinConditionPredictions.keys,
      ...previous.skinAnalysis.skinConditionPredictions.keys,
    };

    for (final condition in allConditions) {
      final currentScore = current.skinAnalysis.skinConditionPredictions[condition] ?? 0.0;
      final previousScore = previous.skinAnalysis.skinConditionPredictions[condition] ?? 0.0;
      conditionChanges[condition] = currentScore - previousScore;
    }

    return ImprovementMetrics(
      overallScoreChange: scoreChange,
      conditionChanges: conditionChanges,
      timespan: timespan,
      improvementDirection: scoreChange > 0 ? TrendDirection.improving : 
                           scoreChange < 0 ? TrendDirection.worsening : 
                           TrendDirection.stable,
    );
  }
}

/// Parameters for processing scan results
class ProcessScanResultsParams extends Equatable {
  /// The scan result to process
  final FaceScanResult scanResult;
  
  /// Previous scan result for comparison (optional)
  final FaceScanResult? previousResult;
  
  /// Historical results for trend analysis (optional)
  final List<FaceScanResult>? historicalResults;
  
  /// User preferences for recommendations (optional)
  final UserSkinCarePreferences? preferences;

  const ProcessScanResultsParams({
    required this.scanResult,
    this.previousResult,
    this.historicalResults,
    this.preferences,
  });

  @override
  List<Object?> get props => [scanResult, previousResult, historicalResults, preferences];
}

/// Enhanced scan result with additional insights and processing
class ProcessedScanResult extends Equatable {
  final FaceScanResult originalResult;
  final List<SkinInsight> detailedInsights;
  final SkinSeverityAssessment severityAssessment;
  final List<SkinRecommendation> recommendations;
  final SkinTrendAnalysis? trendAnalysis;
  final ImprovementMetrics? improvementMetrics;
  final DateTime processedAt;

  const ProcessedScanResult({
    required this.originalResult,
    required this.detailedInsights,
    required this.severityAssessment,
    required this.recommendations,
    this.trendAnalysis,
    this.improvementMetrics,
    required this.processedAt,
  });

  @override
  List<Object?> get props => [
        originalResult,
        detailedInsights,
        severityAssessment,
        recommendations,
        trendAnalysis,
        improvementMetrics,
        processedAt,
      ];
}

/// Represents a specific skin insight
class SkinInsight extends Equatable {
  final InsightCategory category;
  final String title;
  final String description;
  final double confidence;

  const SkinInsight({
    required this.category,
    required this.title,
    required this.description,
    required this.confidence,
  });

  @override
  List<Object?> get props => [category, title, description, confidence];
}

/// Categories of skin insights
enum InsightCategory { positive, neutral, concern, actionable, aging, pigmentation, sensitivity }

/// Overall severity assessment
class SkinSeverityAssessment extends Equatable {
  final SkinSeverityLevel level;
  final double overallScore;
  final List<SkinConditionPrediction> primaryConcerns;
  final int affectedAreaCount;
  final DateTime assessedAt;

  const SkinSeverityAssessment({
    required this.level,
    required this.overallScore,
    required this.primaryConcerns,
    required this.affectedAreaCount,
    required this.assessedAt,
  });

  @override
  List<Object?> get props => [level, overallScore, primaryConcerns, affectedAreaCount, assessedAt];
}

/// Severity levels
enum SkinSeverityLevel { minimal, mild, moderate, significant }

/// Skin care recommendation
class SkinRecommendation extends Equatable {
  final RecommendationType type;
  final String title;
  final String description;
  final RecommendationPriority priority;

  const SkinRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
  });

  @override
  List<Object?> get props => [type, title, description, priority];
}

/// Types of recommendations
enum RecommendationType { maintenance, prevention, treatment, product, ingredient, professional }

/// Recommendation priorities
enum RecommendationPriority { low, medium, high, urgent }

/// Trend analysis across multiple scans
class SkinTrendAnalysis extends Equatable {
  final TrendDirection overallScoreTrend;
  final Map<String, TrendDirection> conditionTrends;
  final Duration analyzedPeriod;
  final int dataPoints;

  const SkinTrendAnalysis({
    required this.overallScoreTrend,
    required this.conditionTrends,
    required this.analyzedPeriod,
    required this.dataPoints,
  });

  @override
  List<Object?> get props => [overallScoreTrend, conditionTrends, analyzedPeriod, dataPoints];
}

/// Trend directions
enum TrendDirection { improving, stable, worsening }

/// Improvement metrics between scans
class ImprovementMetrics extends Equatable {
  final double overallScoreChange;
  final Map<String, double> conditionChanges;
  final Duration timespan;
  final TrendDirection improvementDirection;

  const ImprovementMetrics({
    required this.overallScoreChange,
    required this.conditionChanges,
    required this.timespan,
    required this.improvementDirection,
  });

  @override
  List<Object?> get props => [overallScoreChange, conditionChanges, timespan, improvementDirection];
}

/// User preferences for skin care recommendations
class UserSkinCarePreferences extends Equatable {
  final List<String> preferredIngredients;
  final List<String> avoidedIngredients;
  final List<String> skinConcerns;
  final String? skinType;
  final bool sensitiveSkin;

  const UserSkinCarePreferences({
    required this.preferredIngredients,
    required this.avoidedIngredients,
    required this.skinConcerns,
    this.skinType,
    required this.sensitiveSkin,
  });

  @override
  List<Object?> get props => [preferredIngredients, avoidedIngredients, skinConcerns, skinType, sensitiveSkin];
}

/// Scan processing specific failure
class ScanProcessingFailure extends Failure {
  const ScanProcessingFailure({
    required super.message,
    super.code,
  });
}