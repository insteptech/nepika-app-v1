import 'package:flutter/foundation.dart';
import 'detection_models.dart';

/// Main model for the complete face scan API response
class ScanAnalysisResponse {
  final bool success;
  final String timestamp;
  final double processingTimeSeconds;
  final ConditionAnalysis conditionAnalysis;
  final SkinTypeAnalysis skinTypeAnalysis;
  final AreaDetectionAnalysis areaDetectionAnalysis;
  final List<RecommendationGroup> recommendations;
  final bool imageUploaded;
  final String? reportId; // Report ID for fetching detailed recommendations

  const ScanAnalysisResponse({
    required this.success,
    required this.timestamp,
    required this.processingTimeSeconds,
    required this.conditionAnalysis,
    required this.skinTypeAnalysis,
    required this.areaDetectionAnalysis,
    required this.recommendations,
    required this.imageUploaded,
    this.reportId,
  });

  factory ScanAnalysisResponse.fromJson(Map<String, dynamic> json) {
    try {
      final recommendationsData = json['recommendations'] as List<dynamic>? ?? [];
      final recommendations = recommendationsData
          .map((item) => RecommendationGroup.fromJson(item as Map<String, dynamic>))
          .toList();

      // Extract report_id directly from root level of response
      final reportId = json['report_id'] as String?;
      debugPrint('📝 Parsed report_id from API response: $reportId');

      return ScanAnalysisResponse(
        success: json['success'] as bool? ?? false,
        timestamp: json['timestamp'] as String? ?? '',
        processingTimeSeconds: (json['processing_time_seconds'] as num?)?.toDouble() ?? 0.0,
        conditionAnalysis: ConditionAnalysis.fromJson(
          json['condition_analysis'] as Map<String, dynamic>? ?? {},
        ),
        skinTypeAnalysis: SkinTypeAnalysis.fromJson(
          json['skin_type_analysis'] as Map<String, dynamic>? ?? {},
        ),
        areaDetectionAnalysis: AreaDetectionAnalysis.fromJson(
          json['area_detection_analysis'] as Map<String, dynamic>? ?? {},
        ),
        recommendations: recommendations,
        imageUploaded: json['image_uploaded'] as bool? ?? false,
        reportId: reportId,
      );
    } catch (e) {
      debugPrint('❌ Error parsing ScanAnalysisResponse: $e');
      rethrow;
    }
  }

  /// Get the primary detected condition
  String get primaryCondition => conditionAnalysis.prediction;

  /// Get confidence percentage for primary condition
  double get primaryConditionConfidence {
    if (conditionAnalysis.sortedPredictions.isNotEmpty) {
      return conditionAnalysis.sortedPredictions.first.confidence;
    }
    return 0.0;
  }

  /// Get all detected skin issues from recommendations
  List<String> get detectedSkinIssues {
    return recommendations.map((group) => group.skinIssue).toList();
  }
}

/// Model for condition analysis predictions
class ConditionAnalysis {
  final String prediction;
  final List<ConditionPrediction> sortedPredictions;

  const ConditionAnalysis({
    required this.prediction,
    required this.sortedPredictions,
  });

  factory ConditionAnalysis.fromJson(Map<String, dynamic> json) {
    final allPredictionsData = json['all_predictions'] as Map<String, dynamic>? ?? {};
    final predictions = <ConditionPrediction>[];
    
    // Convert map of predictions to sorted list
    allPredictionsData.forEach((key, value) {
      final confidence = (value as num?)?.toDouble() ?? 0.0;
      predictions.add(ConditionPrediction(name: key, confidence: confidence));
    });
    
    // Sort by confidence descending
    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));

    return ConditionAnalysis(
      prediction: json['prediction'] as String? ?? '',
      sortedPredictions: predictions,
    );
  }

  /// Get top N predictions
  List<ConditionPrediction> getTopPredictions(int count) {
    return sortedPredictions.take(count).toList();
  }
}

/// Model for individual condition prediction
class ConditionPrediction {
  final String name;
  final double confidence;

  const ConditionPrediction({
    required this.name,
    required this.confidence,
  });

  factory ConditionPrediction.fromJson(Map<String, dynamic> json) {
    return ConditionPrediction(
      name: json['name'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Get confidence as percentage string
  String get confidencePercentage => '${confidence.toStringAsFixed(1)}%';

  /// Get display name for the condition
  String get displayName {
    switch (name.toLowerCase()) {
      case 'wrinkles':
        return 'Wrinkles';
      case 'eyebags':
        return 'Eye Bags';
      case 'oily-skin':
        return 'Oily Skin';
      case 'acne':
        return 'Acne';
      case 'blackheads':
        return 'Blackheads';
      case 'skin-redness':
        return 'Skin Redness';
      case 'dry-skin':
        return 'Dry Skin';
      case 'whiteheads':
        return 'Whiteheads';
      case 'dark-spots':
        return 'Dark Spots';
      case 'englarged-pores':
        return 'Enlarged Pores';
      default:
        return name.replaceAll('-', ' ').split(' ')
            .map((word) => word.isNotEmpty 
                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                : word)
            .join(' ');
    }
  }
}

/// Model for skin type analysis
class SkinTypeAnalysis {
  final String prediction;
  final double confidence;
  final Map<String, double> allPredictions;
  final bool adequateLighting;
  final bool success;

  const SkinTypeAnalysis({
    required this.prediction,
    required this.confidence,
    required this.allPredictions,
    required this.adequateLighting,
    required this.success,
  });

  factory SkinTypeAnalysis.fromJson(Map<String, dynamic> json) {
    final allPredictionsData = json['all_predictions'] as Map<String, dynamic>? ?? {};
    final allPredictions = <String, double>{};
    
    allPredictionsData.forEach((key, value) {
      allPredictions[key] = (value as num?)?.toDouble() ?? 0.0;
    });

    return SkinTypeAnalysis(
      prediction: json['prediction'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      allPredictions: allPredictions,
      adequateLighting: json['adequate_lighting'] as bool? ?? true,
      success: json['success'] as bool? ?? false,
    );
  }

  /// Get skin type predictions sorted by confidence
  List<ConditionPrediction> get sortedPredictions {
    final predictions = <ConditionPrediction>[];
    allPredictions.forEach((key, value) {
      predictions.add(ConditionPrediction(name: key, confidence: value));
    });
    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return predictions;
  }
}

/// Model for area detection analysis (using existing DetectionResults)
class AreaDetectionAnalysis {
  final int totalDetections;
  final List<Detection> detections;
  final List<String> classesFound;
  final double modelThreshold;

  const AreaDetectionAnalysis({
    required this.totalDetections,
    required this.detections,
    required this.classesFound,
    required this.modelThreshold,
  });

  factory AreaDetectionAnalysis.fromJson(Map<String, dynamic> json) {
    final detectionsData = json['detections'] as List<dynamic>? ?? [];
    final detections = detectionsData
        .map((item) => Detection.fromJson(item as Map<String, dynamic>))
        .toList();

    final classesFoundData = json['classes_found'] as List<dynamic>? ?? [];
    final classesFound = classesFoundData
        .map((item) => item as String)
        .toList();

    return AreaDetectionAnalysis(
      totalDetections: json['total_detections'] as int? ?? 0,
      detections: detections,
      classesFound: classesFound,
      modelThreshold: (json['model_threshold'] as num?)?.toDouble() ?? 0.1,
    );
  }

  /// Get detections grouped by class
  Map<String, List<Detection>> get detectionsByClass {
    final Map<String, List<Detection>> grouped = {};
    for (final detection in detections) {
      grouped.putIfAbsent(detection.className, () => []).add(detection);
    }
    return grouped;
  }

  /// Get class counts
  Map<String, int> get classCounts {
    final Map<String, int> counts = {};
    for (final detection in detections) {
      counts[detection.className] = (counts[detection.className] ?? 0) + 1;
    }
    return counts;
  }
}

/// Model for recommendation groups
class RecommendationGroup {
  final String skinIssue;
  final String? conditionSlug; // NEW FIELD
  final List<ProductRecommendation> recommendations;
  final ProgressSummary? progressSummary;

  const RecommendationGroup({
    required this.skinIssue,
    this.conditionSlug,
    required this.recommendations,
    this.progressSummary,
  });

  factory RecommendationGroup.fromJson(Map<String, dynamic> json) {
    final recommendationsData = json['recommendations'] as List<dynamic>? ?? [];
    final recommendations = recommendationsData
        .map((item) => ProductRecommendation.fromJson(item as Map<String, dynamic>))
        .toList();
    

    // Support both camelCase and snake_case
    final progressSummaryJson =
        json['progressSummary'] ??
        json['progress_summary'] ??
        {};

    return RecommendationGroup(
      skinIssue: json['skin_issue'] as String? ?? '',
      conditionSlug: json['conditionSlug'] as String? ?? '', // NEW
      recommendations: recommendations,
      progressSummary: ProgressSummary.fromJson(progressSummaryJson),
    );
  }

  /// Get display name for skin issue matching Figma design
  String get displayName {
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
        return skinIssue
            .split(' ')
            .map((word) =>
                word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : word)
            .join(' ');
    }
  }
}

/// Progress summary model
class ProgressSummary {
  final String unit;
  final List<ProgressData> data;

  const ProgressSummary({
    required this.unit,
    required this.data,
  });

  factory ProgressSummary.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];

    return ProgressSummary(
      unit: json['unit'] as String? ?? '',
      data: dataList
          .map((item) => ProgressData.fromJson(item))
          .toList(),
    );
  }
}

/// Individual progress entries

class ProgressData {
  final String month;
  final double value;
  final String scanId;
  final String datetime;

  const ProgressData({
    required this.month,
    required this.value,
    required this.scanId,
    required this.datetime,
  });

  factory ProgressData.fromJson(Map<String, dynamic> json) {
    return ProgressData(
      month: json['month'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      scanId: json['scanId'] as String? ?? '',
      datetime: json['datetime'] as String? ?? '',
    );
  }

  /// <- Add this
  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'value': value,
      'scanId': scanId,
      'datetime': datetime,
    };
  }
}

/// Model for individual product recommendations
class ProductRecommendation {
  final String product;
  final String description;

  const ProductRecommendation({
    required this.product,
    required this.description,
  });

  factory ProductRecommendation.fromJson(Map<String, dynamic> json) {
    return ProductRecommendation(
      product: json['product'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  /// Get effectiveness level based on product name (mock data for UI)
  String get effectivenessLevel {
    // This is mock data for UI purposes - in real app this would come from API
    final productLower = product.toLowerCase();
    if (productLower.contains('retinol') || 
        productLower.contains('hyaluronic') ||
        productLower.contains('vitamin c')) {
      return 'Clinically Proven';
    }
    return 'Generally Effective';
  }

  /// Get effectiveness percentage (mock data for UI)
  int get effectivenessPercentage {
    // This is mock data for UI purposes - in real app this would come from API
    final productLower = product.toLowerCase();
    if (productLower.contains('hyaluronic') || productLower.contains('retinol')) {
      return 82;
    } else if (productLower.contains('glycerin') || productLower.contains('squalane')) {
      return 66;
    }
    return 70; // Default
  }

  /// Check if this is a clinically proven product
  bool get isClinicallyProven => effectivenessLevel == 'Clinically Proven';
}

