import 'package:equatable/equatable.dart';

class Faq extends Equatable {
  final String id;
  final String question;
  final String answer;
  final int displayOrder;

  final String? category;

  const Faq({
    required this.id,
    required this.question,
    required this.answer,
    required this.displayOrder,
    this.category,
  });

  @override
  List<Object?> get props => [id, question, answer, displayOrder, category];
}
