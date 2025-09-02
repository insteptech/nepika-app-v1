// lib/domain/routine/usecases/update_routine_step.dart
import '../../../core/utils/either.dart';
import '../../../core/utils/logger.dart';
import '../repositories/routine_repository.dart';

class UpdateRoutineStep {
  final RoutineRepository repository;

  UpdateRoutineStep(this.repository);

  Future<Result<void>> call(String token, String routineId, bool isCompleted) async {
    Logger.useCase('Updating routine step: $routineId to completed: $isCompleted');
    return await repository.updateRoutineStep(token, routineId, isCompleted);
  }
}