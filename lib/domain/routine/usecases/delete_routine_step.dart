// lib/domain/routine/usecases/delete_routine_step.dart
import '../../../core/utils/either.dart';
import '../../../core/utils/logger.dart';
import '../repositories/routine_repository.dart';

class DeleteRoutineStep {
  final RoutineRepository repository;

  DeleteRoutineStep(this.repository);

  Future<Result<void>> call(String token, String routineId) async {
    Logger.useCase('Deleting routine step: $routineId');
    return await repository.deleteRoutineStep(token, routineId);
  }
}