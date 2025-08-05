import '../../../core/utils/either.dart';
import '../entities/routine.dart';

abstract class RoutineRepository {
  Future<Result<List<Routine>>> getTodaysRoutine({required String token, required String type});
  Future<Result<void>> updateRoutineStep({required String token, required String stepId, required bool isCompleted});
  Future<Result<void>> addRoutineStep({required String token, required Routine routine});
  Future<Result<void>> deleteRoutineStep({required String token, required String stepId});
}
