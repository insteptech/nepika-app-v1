import 'package:flutter/foundation.dart';
import '../../../domain/onboarding/entities/onboarding_entites.dart';
import 'visibility_evaluator.dart';

class OnboardingValidator {
  /// Validates answers for all visible and required questions
  bool validateAnswers(
    List<OnboardingQuestionEntity> questions,
    Map<String, dynamic> answers,
    List<Map<String, dynamic>> responses,
    VisibilityEvaluator visibilityEvaluator,
  ) {
    // Only validate visible questions
    final visibleQuestions = questions.where((q) => 
      visibilityEvaluator.evaluateVisibility(q.visibilityConditions, answers)
    ).toList();
    
    debugPrint("🔍 Validating form with ${responses.length} responses for ${visibleQuestions.length} visible questions (${questions.length} total)");
    
    // Group questions by validation rules
    final exclusiveQuestions = <OnboardingQuestionEntity>[];
    final normalQuestions = <OnboardingQuestionEntity>[];
    
    for (var q in visibleQuestions) {
      if (q.validationRules?['rule'] == 'exclusive') {
        exclusiveQuestions.add(q);
      } else {
        normalQuestions.add(q);
      }
    }
    
    debugPrint("🔍 Exclusive questions: ${exclusiveQuestions.map((q) => q.slug).toList()}");
    debugPrint("🔍 Normal questions: ${normalQuestions.map((q) => q.slug).toList()}");
    
    // Check if any exclusive question is answered
    bool hasExclusiveAnswer = false;
    for (var exclusiveQ in exclusiveQuestions) {
      final questionResponses = responses.where((r) => r["question_id"] == exclusiveQ.id).toList();
      if (questionResponses.isNotEmpty && _hasValidResponse(exclusiveQ, questionResponses)) {
        hasExclusiveAnswer = true;
        debugPrint("✅ Exclusive question ${exclusiveQ.slug} has valid answer");
        break;
      }
    }
    
    if (hasExclusiveAnswer) {
      // If exclusive answer exists, only validate the exclusive question that's answered
      debugPrint("✅ Form valid - exclusive question answered, others cleared");
      return true;
    }
    
    // Otherwise, validate all required non-exclusive questions
    for (var q in visibleQuestions) {
      if (q.isRequired && q.validationRules?['rule'] != 'exclusive') {
        final questionResponses = responses.where((r) => r["question_id"] == q.id).toList();
        debugPrint("Question ${q.slug} (required: ${q.isRequired}, visible: true): ${questionResponses.length} responses");

        if (questionResponses.isEmpty) {
          debugPrint("❌ Missing response for required question: ${q.slug}");
          return false;
        }
        if (!_hasValidResponse(q, questionResponses)) {
          debugPrint("❌ Invalid response for required question: ${q.slug}");
          return false;
        }
      }
    }
    
    debugPrint("✅ Form validation passed");
    return true;
  }

  /// Helper method to check if a question has a valid response
  bool _hasValidResponse(OnboardingQuestionEntity question, List<Map<String, dynamic>> responses) {
    if (question.inputType == 'checkbox' || question.inputType == 'multi_choice') {
      return responses.isNotEmpty && 
             responses.any((r) => r['value'] != null && r['value'].toString().isNotEmpty);
    } else {
      final response = responses.first;
      final value = response["value"];
      return value != null && (value is! String || value.trim().isNotEmpty);
    }
  }

  /// Validates a specific answer for a question
  bool validateQuestionAnswer(
    OnboardingQuestionEntity question,
    dynamic value,
  ) {
    if (!question.isRequired) return true;

    switch (question.inputType) {
      case 'text':
        return value != null && value.toString().trim().isNotEmpty;
      case 'date':
        return value != null && value.toString().isNotEmpty;
      case 'single_choice':
      case 'dropdown':
        return value != null && value.toString().isNotEmpty;
      case 'multi_choice':
      case 'checkbox':
        return value is List && value.isNotEmpty;
      case 'range':
        return value is List && value.length == 2;
      default:
        return value != null;
    }
  }

  /// Checks if form is ready for submission
  bool isFormReadyForSubmission(
    List<OnboardingQuestionEntity> questions,
    Map<String, dynamic> answers,
    List<Map<String, dynamic>> responses,
    VisibilityEvaluator visibilityEvaluator,
  ) {
    if (responses.isEmpty) return false;
    
    return validateAnswers(questions, answers, responses, visibilityEvaluator);
  }
}