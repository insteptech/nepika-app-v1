import 'package:nepika/core/api_base.dart';
import '../../../core/utils/either.dart';
import '../../../core/error/failures.dart';
import '../../../domain/routine/entities/routine.dart';
import '../../../domain/routine/repositories/routine_repository.dart';
import '../datasources/routine_remote_data_source.dart';
import '../models/routine_model.dart';

class RoutineRepositoryImpl implements RoutineRepository {
  final RoutineRemoteDataSource remoteDataSource;
  final ApiBase apiBase;

  RoutineRepositoryImpl({
    required this.remoteDataSource,
    required this.apiBase,
  });

  @override
  Future<Result<List<Routine>>> getTodaysRoutine({
    required String token,
    required String type,
  }) async {
    try {
      final routineModels = await remoteDataSource.getTodaysRoutine();
      final routines = routineModels.map(_mapToEntity).toList();
      return success(routines);
    } catch (e) {
      return failure(
        ServerFailure(message: 'Failed to get today\'s routine: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> updateRoutineStep({
    required String token,
    required String stepId,
    required bool isCompleted,
  }) async {
    try {
      await remoteDataSource.updateRoutineStep(stepId, isCompleted);
      return success(null);
    } catch (e) {
      return failure(
        ServerFailure(message: 'Failed to update routine step: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> addRoutineStep({
    required String token,
    required Routine routine,
  }) async {
    try {
      final routineModel = _mapToModel(routine);
      await remoteDataSource.createRoutine(routineModel);
      return success(null);
    } catch (e) {
      return failure(
        ServerFailure(message: 'Failed to add routine step: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> deleteRoutineStep({
    required String token,
    required String stepId,
  }) async {
    try {
      await remoteDataSource.deleteRoutine(stepId);
      return success(null);
    } catch (e) {
      return failure(
        ServerFailure(message: 'Failed to delete routine step: ${e.toString()}'),
      );
    }
  }

  Routine _mapToEntity(RoutineModel model) {
    return Routine(
      id: model.id,
      name: model.name,
      timing: model.timing,
      isCompleted: model.isCompleted,
      description: model.description,
      reminderTime: model.reminderTime,
    );
  }

  RoutineModel _mapToModel(Routine entity) {
    return RoutineModel(
      id: entity.id,
      name: entity.name,
      timing: entity.timing,
      isCompleted: entity.isCompleted,
      description: entity.description,
      reminderTime: entity.reminderTime,
    );
  }
}
