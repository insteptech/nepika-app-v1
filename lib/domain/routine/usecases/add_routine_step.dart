// lib/domain/routine/usecases/add_routine_step.dart
import '../../../core/utils/either.dart';
import '../../../core/utils/logger.dart';
import '../repositories/routine_repository.dart';

class AddRoutineStep {
  final RoutineRepository repository;

  AddRoutineStep(this.repository);

  Future<Result<void>> call(String token, String masterRoutineId) async {
    Logger.useCase('Adding routine step: $masterRoutineId');
    return await repository.addRoutineStep(token, masterRoutineId);
  }
}