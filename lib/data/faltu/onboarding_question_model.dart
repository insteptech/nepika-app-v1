// class OnboardingOptionModel {
//   final String id;
//   final String text;
//   final String value;
//   bool isSelected;

//   OnboardingOptionModel({
//     required this.id,
//     required this.text,
//     required this.value,
//     this.isSelected = false,
//   });

//   factory OnboardingOptionModel.fromJson(Map<String, dynamic> json) {
//     return OnboardingOptionModel(
//       id: json['id'] as String,
//       text: json['text']['en'] as String,
//       value: json['value'] as String,
//       isSelected: json['is_selected'] ?? false,
//     );
//   }

//   OnboardingOptionModel copyWith({bool? isSelected}) {
//     return OnboardingOptionModel(
//       id: id,
//       text: text,
//       value: value,
//       isSelected: isSelected ?? this.isSelected,
//     );
//   }
// }

// class OnboardingQuestionModel {
//   final String id;
//   final String slug;
//   final String questionText;
//   final String inputType;
//   final bool isRequired;
//   final int displayOrder;
//   final List<OnboardingOptionModel> options;

//   OnboardingQuestionModel({
//     required this.id,
//     required this.slug,
//     required this.questionText,
//     required this.inputType,
//     required this.isRequired,
//     required this.displayOrder,
//     required this.options,
//   });

//   factory OnboardingQuestionModel.fromJson(Map<String, dynamic> json) {
//     return OnboardingQuestionModel(
//       id: json['id'] as String,
//       slug: json['slug'] as String,
//       questionText: json['question_text']['en'] as String,
//       inputType: json['input_type'] as String,
//       isRequired: json['is_required'] ?? false,
//       displayOrder: json['display_order'] ?? 0,
//       options: (json['options'] as List?)?.map((e) => OnboardingOptionModel.fromJson(e)).toList() ?? [],
//     );
//   }
// }

// class OnboardingScreenDataModel {
//   final Map<String, dynamic> user;
//   final List<OnboardingQuestionModel> questions;

//   OnboardingScreenDataModel({
//     required this.user,
//     required this.questions,
//   });

//   factory OnboardingScreenDataModel.fromJson(Map<String, dynamic> json) {
//     return OnboardingScreenDataModel(
//       user: json['user'] as Map<String, dynamic>,
//       questions: (json['questions'] as List?)?.map((e) => OnboardingQuestionModel.fromJson(e)).toList() ?? [],
//     );
//   }
// }



// data
