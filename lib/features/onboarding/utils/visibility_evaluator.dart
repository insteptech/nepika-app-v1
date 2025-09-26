import 'package:flutter/foundation.dart';

class VisibilityEvaluator {
  /// Evaluates visibility conditions for onboarding questions
  bool evaluateVisibility(
    Map<String, dynamic>? conditions,
    Map<String, dynamic> responses,
  ) {
    if (conditions == null) return true;
    
    debugPrint("🔍 Evaluating visibility: conditions=$conditions, responses=$responses");
    
    final operator = conditions['operator'] as String?;
    final questionSlug = conditions['question_slug'] as String?;
    final expectedValue = conditions['value'];
    
    if (operator == null || questionSlug == null || expectedValue == null) {
      return true; // Show by default if condition is malformed
    }
    
    // Get the actual response value for the referenced question
    final actualValue = responses[questionSlug];
    
    switch (operator) {
      case 'equals':
        return actualValue?.toString() == expectedValue.toString();
      case 'not_equals':
        return actualValue?.toString() != expectedValue.toString();
      case 'in':
        if (expectedValue is List && actualValue is List) {
          return actualValue.any((val) => expectedValue.contains(val));
        }
        if (expectedValue is List) {
          return expectedValue.contains(actualValue);
        }
        return false;
      case 'not_in':
        if (expectedValue is List && actualValue is List) {
          return !actualValue.any((val) => expectedValue.contains(val));
        }
        if (expectedValue is List) {
          return !expectedValue.contains(actualValue);
        }
        return true;
      default:
        return true; // Show by default for unknown operators
    }
  }

  /// Checks if any excluded question is selected for exclusivity rules
  bool isExclusiveQuestionConflicted(
    Map<String, dynamic>? validationRules,
    Map<String, dynamic> responses,
  ) {
    if (validationRules == null) return false;
    
    final rule = validationRules['rule'] as String?;
    if (rule != 'exclusive') return false;
    
    final excludes = validationRules['excludes'] as List<dynamic>?;
    if (excludes == null || excludes.isEmpty) return false;
    
    // Check if any excluded question has a value
    for (final excludedSlug in excludes) {
      if (excludedSlug is String && responses.containsKey(excludedSlug)) {
        final value = responses[excludedSlug];
        if (value != null && value.toString().isNotEmpty) {
          return true; // There's a conflict
        }
      }
    }
    
    return false;
  }
}