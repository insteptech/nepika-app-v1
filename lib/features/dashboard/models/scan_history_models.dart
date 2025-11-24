import 'package:flutter/material.dart';

/// ---------------- SAFETY HELPERS ----------------

num _parseNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

String _parseString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

bool _parseBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is String) return (value.toLowerCase() == "true");
  if (value is num) return value == 1;
  return false;
}

DateTime _parseDate(dynamic value) {
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {}
  }
  return DateTime.now();
}

/// ---------------- MAIN RESPONSE ----------------

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
    final scansData = json['scans'];
    final List<ScanHistoryItem> scans = [];

    if (scansData is List) {
      for (final item in scansData) {
        if (item is Map<String, dynamic>) {
          scans.add(ScanHistoryItem.fromJson(item));
        }
      }
    }

    return ScanHistoryResponse(
      success: _parseBool(json['success']),
      totalCount: _parseNum(json['total_count']).toInt(),
      limit: _parseNum(json['limit']).toInt(),
      offset: _parseNum(json['offset']).toInt(),
      scans: scans,
    );
  }
}

/// ---------------- SCAN ITEM ----------------

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
    // defensive parsing for lists
    final issuesRaw = json['detected_issues'];
    final detectedIssues = (issuesRaw is List)
        ? issuesRaw.map((e) => _parseString(e)).toList()
        : <String>[];

    // defensive maps
    final issuePercentagesRaw = json['issue_percentages'];
    final allConditionsRaw = json['all_conditions'];

    final issuePercentages = <String, double>{};
    if (issuePercentagesRaw is Map) {
      issuePercentagesRaw.forEach((k, v) {
        issuePercentages[_parseString(k)] = _parseNum(v).toDouble();
      });
    }

    final allConditions = <String, double>{};
    if (allConditionsRaw is Map) {
      allConditionsRaw.forEach((k, v) {
        allConditions[_parseString(k)] = _parseNum(v).toDouble();
      });
    }

    return ScanHistoryItem(
      id: _parseString(json['id']),
      scanDate: _parseDate(json['scan_date']),
      skinScore: _parseNum(json['skin_score']).toInt(),
      skinType: SkinTypeData.fromJson(json['skin_type'] is Map ? json['skin_type'] : {}),
      primaryCondition: PrimaryConditionData.fromJson(
          json['primary_condition'] is Map ? json['primary_condition'] : {}),
      detectedIssues: detectedIssues,
      issuePercentages: issuePercentages,
      allConditions: allConditions,
      imageUrl: _parseString(json['image_url']),
      recommendationsCount: _parseNum(json['recommendations_count']).toInt(),
      areaDetectionSummary: AreaDetectionSummary.fromJson(
          json['area_detection_summary'] is Map ? json['area_detection_summary'] : {}),
      lightingOk: _parseBool(json['lighting_ok']),
      processed: _parseBool(json['processed']),
    );
  }

  /// ---------- Extra helpers ----------

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scanDay = DateTime(scanDate.year, scanDate.month, scanDate.day);
    final difference = today.difference(scanDay).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';

    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final day = scanDate.day.toString().padLeft(2, '0');
    final month = months[scanDate.month];
    final year = scanDate.year.toString();
    return '$day $month $year';
  }

  Color get skinScoreColor {
    if (skinScore >= 80) return const Color(0xFF4CAF50); // Green
    if (skinScore >= 60) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  List<String> get topIssues {
    final sorted = allConditions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => e.key).toList();
  }
}

/// ---------------- SKIN TYPE ----------------

class SkinTypeData {
  final String prediction;
  final double confidence;

  const SkinTypeData({
    required this.prediction,
    required this.confidence,
  });

  factory SkinTypeData.fromJson(Map<String, dynamic> json) {
    return SkinTypeData(
      prediction: _parseString(json['prediction']),
      confidence: _parseNum(json['confidence']).toDouble(),
    );
  }
}

/// ---------------- PRIMARY CONDITION ----------------

class PrimaryConditionData {
  final String prediction;
  final double confidence;

  const PrimaryConditionData({
    required this.prediction,
    required this.confidence,
  });

  factory PrimaryConditionData.fromJson(Map<String, dynamic> json) {
    return PrimaryConditionData(
      prediction: _parseString(json['prediction']),
      confidence: _parseNum(json['confidence']).toDouble(),
    );
  }
}

/// ---------------- AREA DETECTION ----------------

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
    final classesRaw = json['classes_found'];
    final classesFound = (classesRaw is List)
        ? classesRaw.map((e) => _parseString(e)).toList()
        : <String>[];

    final classCounts = <String, int>{};
    if (json['class_counts'] is Map) {
      (json['class_counts'] as Map).forEach((k, v) {
        classCounts[_parseString(k)] = _parseNum(v).toInt();
      });
    }

    return AreaDetectionSummary(
      totalDetections: _parseNum(json['total_detections']).toInt(),
      classesFound: classesFound,
      classCounts: classCounts,
    );
  }
}
