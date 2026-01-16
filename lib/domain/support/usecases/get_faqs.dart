import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/faq.dart';
import '../repositories/faq_repository.dart';

class GetFaqs {
  final FaqRepository repository;

  GetFaqs(this.repository);

  Future<Either<Failure, List<Faq>>> call() async {
    return await repository.getFaqs();
  }
}
