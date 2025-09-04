class SkinConditionProgressData {
  final String month;
  final double value;

  SkinConditionProgressData({
    required this.month,
    required this.value,
  });

  factory SkinConditionProgressData.fromJson(Map<String, dynamic> json) {
    return SkinConditionProgressData(
      month: json['month'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'value': value,
    };
  }
}

class SkinConditionProgressSummary {
  final String unit;
  final List<SkinConditionProgressData> data;

  SkinConditionProgressSummary({
    required this.unit,
    required this.data,
  });

  factory SkinConditionProgressSummary.fromJson(Map<String, dynamic> json) {
    return SkinConditionProgressSummary(
      unit: json['unit'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => SkinConditionProgressData.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unit': unit,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}

class SkinConditionDetailsData {
  final String conditionSlug;
  final double currentPercentage;
  final String lastUpdated;
  final SkinConditionProgressSummary progressSummary;

  SkinConditionDetailsData({
    required this.conditionSlug,
    required this.currentPercentage,
    required this.lastUpdated,
    required this.progressSummary,
  });

  factory SkinConditionDetailsData.fromJson(Map<String, dynamic> json) {
    return SkinConditionDetailsData(
      conditionSlug: json['conditionSlug'] ?? '',
      currentPercentage: (json['currentPercentage'] ?? 0).toDouble(),
      lastUpdated: json['lastUpdated'] ?? '',
      progressSummary: SkinConditionProgressSummary.fromJson(
        json['progressSummary'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conditionSlug': conditionSlug,
      'currentPercentage': currentPercentage,
      'lastUpdated': lastUpdated,
      'progressSummary': progressSummary.toJson(),
    };
  }

  String get formattedConditionName {
    switch (conditionSlug.toLowerCase()) {
      case 'acne':
        return 'Acne';
      case 'dry':
        return 'Dry Skin';
      case 'normal':
        return 'Normal Skin';
      case 'wrinkle':
        return 'Wrinkles';
      case 'dark_circles':
        return 'Dark Circles';
      case 'pigmentation':
        return 'Pigmentation';
      default:
        return conditionSlug
            .split('_')
            .map((word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1)}'
                : word)
            .join(' ');
    }
  }
}

class SkinConditionResponse {
  final bool success;
  final String message;
  final int statusCode;
  final SkinConditionDetailsData data;
  final List<dynamic> errors;
  final String timestamp;

  SkinConditionResponse({
    required this.success,
    required this.message,
    required this.statusCode,
    required this.data,
    required this.errors,
    required this.timestamp,
  });

  factory SkinConditionResponse.fromJson(Map<String, dynamic> json) {
    return SkinConditionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      statusCode: json['status_code'] ?? 0,
      data: SkinConditionDetailsData.fromJson(json['data'] ?? {}),
      errors: json['errors'] ?? [],
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'status_code': statusCode,
      'data': data.toJson(),
      'errors': errors,
      'timestamp': timestamp,
    };
  }
}