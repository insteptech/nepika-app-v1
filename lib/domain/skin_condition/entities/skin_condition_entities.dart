class SkinConditionEntity {
  final String conditionSlug;
  final String formattedConditionName;
  final double currentPercentage;
  final Map<String, dynamic> skinScore;
  final String lastUpdated;
  final Map<String, dynamic> progressSummary;

  SkinConditionEntity({
    required this.conditionSlug,
    required this.formattedConditionName,
    required this.currentPercentage,
    required this.skinScore,
    required this.lastUpdated,
    required this.progressSummary,
  });
} 