import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class FeedbackRepository {
  Future<Either<Failure, void>> submitFeedback({
    required String text,
    int? rating,
  });
}
