import 'package:flutter/material.dart';

/// Models for scan history API response
class ScanHistoryResponse {
  final bool success;
  final int totalCount;
  final int limit;
  final int offset;
  final List<ScanHistoryItem> scans;

  const ScanHistoryResponse({
    required this.success,
    required this.totalCount,
    required this.limit,
    required this.offset,
    required this.scans,
  });

  factory ScanHistoryResponse.fromJson(Map<String, dynamic> json) {
    final scansData = json['scans'] as List<dynamic>? ?? [];
    final scans = scansData
        .map((item) => ScanHistoryItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return ScanHistoryResponse(
      success: json['success'] as bool? ?? false,
      totalCount: json['total_count'] as int? ?? 0,
      limit: json['limit'] as int? ?? 50,
      offset: json['offset'] as int? ?? 0,
      scans: scans,
    );
  }
}

/// Individual scan history item
class ScanHistoryItem {
  final String id;
  final DateTime scanDate;
  final int skinScore;
  final SkinTypeData skinType;
  final PrimaryConditionData primaryCondition;
  final List<String> detectedIssues;
  final Map<String, double> issuePercentages;
  final Map<String, double> allConditions;
  final String imageUrl;
  final int recommendationsCount;
  final AreaDetectionSummary areaDetectionSummary;
  final bool lightingOk;
  final bool processed;

  const ScanHistoryItem({
    required this.id,
    required this.scanDate,
    required this.skinScore,
    required this.skinType,
    required this.primaryCondition,
    required this.detectedIssues,
    required this.issuePercentages,
    required this.allConditions,
    required this.imageUrl,
    required this.recommendationsCount,
    required this.areaDetectionSummary,
    required this.lightingOk,
    required this.processed,
  });

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      id: json['id'] as String? ?? '',
      scanDate: DateTime.parse(json['scan_date'] as String? ?? DateTime.now().toIso8601String()),
      skinScore: json['skin_score'] as int? ?? 0,
      skinType: SkinTypeData.fromJson(json['skin_type'] as Map<String, dynamic>? ?? {}),
      primaryCondition: PrimaryConditionData.fromJson(json['primary_condition'] as Map<String, dynamic>? ?? {}),
      detectedIssues: List<String>.from(json['detected_issues'] as List<dynamic>? ?? []),
      issuePercentages: Map<String, double>.from(
        (json['issue_percentages'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0.0),
        ),
      ),
      allConditions: Map<String, double>.from(
        (json['all_conditions'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0.0),
        ),
      ),
      imageUrl: json['image_url'] as String? ?? '',
      recommendationsCount: json['recommendations_count'] as int? ?? 0,
      areaDetectionSummary: AreaDetectionSummary.fromJson(
        json['area_detection_summary'] as Map<String, dynamic>? ?? {},
      ),
      lightingOk: json['lighting_ok'] as bool? ?? false,
      processed: json['processed'] as bool? ?? false,
    );
  }

  /// Get formatted date string for display
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scanDay = DateTime(scanDate.year, scanDate.month, scanDate.day);
    final difference = today.difference(scanDay).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      // Format as DD Mon YYYY
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final day = scanDate.day.toString().padLeft(2, '0');
      final month = months[scanDate.month];
      final year = scanDate.year.toString();
      return '$day $month $year';
    }
  }

  /// Get skin score color based on value
  Color get skinScoreColor {
    if (skinScore >= 80) return const Color(0xFF4CAF50); // Green
    if (skinScore >= 60) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  /// Get top 3 detected issues for display
  List<String> get topIssues {
    final sortedConditions = allConditions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedConditions
        .take(3)
        .map((entry) => entry.key)
        .toList();
  }
}

/// Skin type data model
class SkinTypeData {
  final String prediction;
  final double confidence;

  const SkinTypeData({
    required this.prediction,
    required this.confidence,
  });

  factory SkinTypeData.fromJson(Map<String, dynamic> json) {
    return SkinTypeData(
      prediction: json['prediction'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Primary condition data model
class PrimaryConditionData {
  final String prediction;
  final double confidence;

  const PrimaryConditionData({
    required this.prediction,
    required this.confidence,
  });

  factory PrimaryConditionData.fromJson(Map<String, dynamic> json) {
    return PrimaryConditionData(
      prediction: json['prediction'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Area detection summary model
class AreaDetectionSummary {
  final int totalDetections;
  final List<String> classesFound;
  final Map<String, int> classCounts;

  const AreaDetectionSummary({
    required this.totalDetections,
    required this.classesFound,
    required this.classCounts,
  });

  factory AreaDetectionSummary.fromJson(Map<String, dynamic> json) {
    return AreaDetectionSummary(
      totalDetections: json['total_detections'] as int? ?? 0,
      classesFound: List<String>.from(json['classes_found'] as List<dynamic>? ?? []),
      classCounts: Map<String, int>.from(
        (json['class_counts'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
        ),
      ),
    );
  }
}