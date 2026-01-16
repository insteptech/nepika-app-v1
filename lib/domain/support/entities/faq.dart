import 'package:equatable/equatable.dart';

class Faq extends Equatable {
  final String id;
  final String question;
  final String answer;
  final int displayOrder;

  const Faq({
    required this.id,
    required this.question,
    required this.answer,
    required this.displayOrder,
  });

  @override
  List<Object?> get props => [id, question, answer, displayOrder];
}
