import '../../../domain/support/entities/faq.dart';

class FaqModel extends Faq {
  const FaqModel({
    required super.id,
    required super.question,
    required super.answer,
    required super.displayOrder,
    super.category,
    super.targetAudience,
  });

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      displayOrder: json['display_order'] as int? ?? 0,
      category: json['category'] as String?,
      targetAudience: json['target_audience'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'display_order': displayOrder,
      'category': category,
      'target_audience': targetAudience,
    };
  }
}

