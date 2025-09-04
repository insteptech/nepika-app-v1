class OnboardingOptionModel {
  final String id;
  final String text;
  final String? description;
  final String value;
  final int sortOrder;
  final bool isSelected;

  OnboardingOptionModel({
    required this.id,
    required this.text,
    this.description,
    required this.value,
    required this.sortOrder,
    this.isSelected = false,
  });

  factory OnboardingOptionModel.fromJson(Map<String, dynamic> json) {
    return OnboardingOptionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      description: json['description'] as String?,
      value: json['value'] as String,
      sortOrder: json['sort_order'] ?? 0,
      isSelected: json['is_selected'] ?? false,
    );
  }

  OnboardingOptionModel copyWith({bool? isSelected}) {
    return OnboardingOptionModel(
      id: id,
      text: text,
      description: description,
      value: value,
      sortOrder: sortOrder,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class OnboardingQuestionModel {
  final String id;
  final String slug;
  final String questionText;
  final String targetField;
  final String? prefillValue;
  final String? keyboardType;
  final String targetTable;
  final String inputType;
  final String? inputPlaceholder;
  final bool isRequired;
  final int displayOrder;
  final List<OnboardingOptionModel> options;
  final Map<String, dynamic>? visibilityConditions;
  final Map<String, dynamic>? validationRules;

  OnboardingQuestionModel({
    required this.id,
    required this.slug,
    required this.questionText,
    required this.targetField,
    required this.targetTable,
    required this.inputType,
    this.prefillValue,
    this.keyboardType,
    this.inputPlaceholder,
    required this.isRequired,
    required this.displayOrder,
    required this.options,
    this.visibilityConditions,
    this.validationRules,
  });

  factory OnboardingQuestionModel.fromJson(Map<String, dynamic> json) {
    return OnboardingQuestionModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      questionText: json['question_text'] as String,
      targetField: json['target_field'] as String,
      targetTable: json['target_table'] as String,
      inputType: json['input_type'] as String,
      prefillValue: json['prefill_value']?.toString(),
      keyboardType: json['keyboard_type']?.toString(),
      inputPlaceholder: json['input_placeholder'] as String?,
      isRequired: json['is_required'] ?? false,
      displayOrder: json['display_order'] ?? 0,
      visibilityConditions: json['visibility_conditions'] as Map<String, dynamic>?,
      validationRules: json['validation_rules'] as Map<String, dynamic>?,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => OnboardingOptionModel.fromJson(e))
          .toList(),
    );
  }
}

class OnboardingScreenDataModel {
  final String screenId;
  final String title;
  final String? description;
  final String buttonText;
  final int? totalSteps;
  final String slug;
  final List<OnboardingQuestionModel> questions;

  OnboardingScreenDataModel({
    required this.screenId,
    required this.title,
    this.description,
    this.totalSteps,
    required this.slug,
    required this.buttonText,
    required this.questions,
  });

  factory OnboardingScreenDataModel.fromJson(Map<String, dynamic> json) {
    return OnboardingScreenDataModel(
      screenId: json['screen_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      slug: json['slug'] as String,
      buttonText: json['button_text'] as String,
      totalSteps: json['total_screens'] as int?,
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((e) => OnboardingQuestionModel.fromJson(e))
          .toList(),
    );
  }
}
