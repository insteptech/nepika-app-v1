class OnboardingOptionEntity {
  final String id;
  final String text;
  final String? description;
  final String value;
  final int? sortOrder;
  final bool isSelected;

  OnboardingOptionEntity({
    required this.id,
    required this.text,
    this.description = '',
    required this.value,
    this.sortOrder,
    this.isSelected = false,
  });

  OnboardingOptionEntity copyWith({bool? isSelected}) {
    return OnboardingOptionEntity(
      id: id,
      text: text,
      description: description,
      value: value,
      sortOrder: sortOrder,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class OnboardingQuestionEntity {
  final String id;
  final String slug;
  final String questionText;
  final String targetField;
  final String targetTable;
  final String? keyboardType;
  final String? prefillValue;
  final String inputType;
  final String inputPlaceholder;
  final bool isRequired;
  final int displayOrder;
  final List<OnboardingOptionEntity> options;

  OnboardingQuestionEntity({
    required this.id,
    required this.slug,
    required this.questionText,
    required this.targetField,
    required this.targetTable,
    required this.inputType,
    this.keyboardType,
    this.prefillValue,
    this.inputPlaceholder = '',
    required this.isRequired,
    required this.displayOrder,
    required this.options,

  });
}

class OnboardingScreenDataEntity {
  final String screenId;
  final String title;
  final String? description;
  final String slug;
  final String? buttonText;
  final int? totalSteps;
  final Map<String, dynamic>? user;
  final List<OnboardingQuestionEntity> questions;

  OnboardingScreenDataEntity({
    required this.screenId,
    required this.title,
    this.description,
    required this.slug,
    this.totalSteps,
    this.buttonText,
    this.user,
    required this.questions,
  });
}


class OnboardingStepEntity {
  final String screenId; // numeric string (server id)
  final String slug;
  final String title;
  final String? subtitle;
  final int? totalSteps;
  final String? buttonText;

  OnboardingStepEntity({
    required this.screenId,
    required this.slug,
    required this.title,
    this.totalSteps,
    this.subtitle,
    this.buttonText,
  });
}