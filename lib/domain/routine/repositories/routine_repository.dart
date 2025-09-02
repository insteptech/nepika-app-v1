// lib/domain/routine/repositories/routine_repository.dart
import '../../../core/utils/either.dart';
import '../../../core/error/failures.dart';
import '../entities/routine.dart';

abstract class RoutineRepository {
  Future<Result<List<Routine>>> getTodaysRoutine(String token, String type);
  Future<Result<void>> updateRoutineStep(String token, String routineId, bool isCompleted);
  Future<Result<void>> deleteRoutineStep(String token, String routineId);
  Future<Result<void>> addRoutineStep(String token, String masterRoutineId);
}