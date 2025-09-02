// lib/domain/routine/usecases/get_todays_routine.dart
import '../../../core/utils/either.dart';
import '../../../core/utils/logger.dart';
import '../entities/routine.dart';
import '../repositories/routine_repository.dart';

class GetTodaysRoutine {
  final RoutineRepository repository;

  GetTodaysRoutine(this.repository);

  Future<Result<List<Routine>>> call(String token, String type) async {
    Logger.useCase('Getting today\'s routine for type: $type');
    return await repository.getTodaysRoutine(token, type);
  }
}