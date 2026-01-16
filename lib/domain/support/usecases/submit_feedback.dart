import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/feedback_repository.dart';

class SubmitFeedback {
  final FeedbackRepository repository;

  SubmitFeedback(this.repository);

  Future<Either<Failure, void>> call({
    required String text,
    int? rating,
  }) async {
    return await repository.submitFeedback(text: text, rating: rating);
  }
}
