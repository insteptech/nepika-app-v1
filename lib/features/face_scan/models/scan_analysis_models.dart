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
  final RecommendationsData recommendations;
  final bool imageUploaded;
  final String? reportId;
  final String? apiVersion;

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
    this.apiVersion,
  });

  factory ScanAnalysisResponse.fromJson(Map<String, dynamic> json) {
    try {
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
        recommendations: RecommendationsData.fromJson(
          json['recommendations'] as Map<String, dynamic>? ?? {},
        ),
        imageUploaded: json['image_uploaded'] as bool? ?? false,
        reportId: reportId,
        apiVersion: json['api_version'] as String?,
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

  /// Get all detected skin issues from condition analysis
  List<String> get detectedSkinIssues {
    return conditionAnalysis.sortedPredictions
        .where((p) => p.confidence > 5.0) // Only include conditions with > 5% confidence
        .map((p) => p.name)
        .toList();
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

/// Model for the recommendations data from API v2
class RecommendationsData {
  final PersonalizedFor personalizedFor;
  final RecommendationGroups groups;
  final List<RecommendationItem> flatItems;

  const RecommendationsData({
    required this.personalizedFor,
    required this.groups,
    required this.flatItems,
  });

  factory RecommendationsData.fromJson(Map<String, dynamic> json) {
    return RecommendationsData(
      personalizedFor: PersonalizedFor.fromJson(
        json['personalized_for'] as Map<String, dynamic>? ?? {},
      ),
      groups: RecommendationGroups.fromJson(
        json['groups'] as Map<String, dynamic>? ?? {},
      ),
      flatItems: (json['flat_items'] as List<dynamic>? ?? [])
          .map((item) => RecommendationItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Get all products from groups
  List<RecommendationItem> get allProducts => groups.products;

  /// Get all causes from groups
  List<RecommendationItem> get allCauses => groups.causes;

  /// Get all dos recommendations
  List<RecommendationItem> get allDos => groups.dos;

  /// Get all donts recommendations
  List<RecommendationItem> get allDonts => groups.donts;

  /// Get all lifestyle suggestions
  List<RecommendationItem> get allLifestyleSuggestions => groups.lifestyleSuggestions;
}

/// Personalized for data
class PersonalizedFor {
  final String skinType;
  final Map<String, String> severityMap;

  const PersonalizedFor({
    required this.skinType,
    required this.severityMap,
  });

  factory PersonalizedFor.fromJson(Map<String, dynamic> json) {
    final severityMapData = json['severity_map'] as Map<String, dynamic>? ?? {};
    final severityMap = <String, String>{};
    severityMapData.forEach((key, value) {
      severityMap[key] = value as String? ?? 'mild';
    });

    return PersonalizedFor(
      skinType: json['skin_type'] as String? ?? '',
      severityMap: severityMap,
    );
  }

  /// Get severity for a specific condition
  String getSeverity(String condition) {
    return severityMap[condition.toLowerCase()] ?? 'mild';
  }
}

/// Grouped recommendations
class RecommendationGroups {
  final List<RecommendationItem> causes;
  final List<RecommendationItem> products;
  final List<RecommendationItem> alternateSolutions;
  final List<RecommendationItem> lifestyleSuggestions;
  final List<RecommendationItem> importantConsiderations;
  final List<RecommendationItem> dos;
  final List<RecommendationItem> donts;

  const RecommendationGroups({
    required this.causes,
    required this.products,
    required this.alternateSolutions,
    required this.lifestyleSuggestions,
    required this.importantConsiderations,
    required this.dos,
    required this.donts,
  });

  factory RecommendationGroups.fromJson(Map<String, dynamic> json) {
    return RecommendationGroups(
      causes: _parseItemList(json['causes']),
      products: _parseItemList(json['products']),
      alternateSolutions: _parseItemList(json['alternate_solutions']),
      lifestyleSuggestions: _parseItemList(json['lifestyle_suggestions']),
      importantConsiderations: _parseItemList(json['important_considerations']),
      dos: _parseItemList(json['dos']),
      donts: _parseItemList(json['donts']),
    );
  }

  static List<RecommendationItem> _parseItemList(dynamic data) {
    if (data == null) return [];
    return (data as List<dynamic>)
        .map((item) => RecommendationItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

/// Individual recommendation item (used for causes, products, dos, donts, etc.)
class RecommendationItem {
  final String id;
  final String type; // cause, product, alternate, lifestyle, consideration, do, dont
  final String title;
  final String? subtitle;
  final String description;
  final Map<String, dynamic> meta;
  final int priority;
  final String condition;
  final int matchScore;

  const RecommendationItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    required this.description,
    required this.meta,
    required this.priority,
    required this.condition,
    required this.matchScore,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String? ?? '',
      meta: json['meta'] as Map<String, dynamic>? ?? {},
      priority: json['priority'] as int? ?? 0,
      condition: json['condition'] as String? ?? '',
      matchScore: json['match_score'] as int? ?? 0,
    );
  }

  // Meta field getters for products
  String? get usage => meta['usage'] as String?;
  String? get category => meta['category'] as String?;
  String? get priceRange => meta['price_range'] as String?;
  String? get availability => meta['availability'] as String?;
  String? get recommendationType => meta['recommendation_type'] as String?;

  // Meta field getters for lifestyle
  String? get difficulty => meta['difficulty'] as String?;
  String? get impactLevel => meta['impact_level'] as String?;
  String? get timeToResults => meta['time_to_results'] as String?;

  // Meta field getters for considerations
  String? get urgency => meta['urgency'] as String?;
  String? get actionRequired => meta['action_required'] as String?;

  // Meta field getters for dos/donts
  String? get frequency => meta['frequency'] as String?;
  String? get importance => meta['importance'] as String?;
  String? get riskLevel => meta['risk_level'] as String?;
  String? get consequence => meta['consequence'] as String?;

  // Meta field getters for causes
  String? get icon => meta['icon'] as String?;

  /// Get display name for condition
  String get conditionDisplayName {
    return condition
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : word)
        .join(' ');
  }

  /// Check if this is a high priority item
  bool get isHighPriority => priority >= 90;

  /// Check if this is a critical item
  bool get isCritical => importance == 'critical' || riskLevel == 'critical';
}

/// Model for recommendation groups (legacy support)
class RecommendationGroup {
  final String skinIssue;
  final String? conditionSlug;
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

    final progressSummaryJson =
        json['progressSummary'] ?? json['progress_summary'] ?? {};

    return RecommendationGroup(
      skinIssue: json['skin_issue'] as String? ?? '',
      conditionSlug: json['conditionSlug'] as String? ?? '',
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

