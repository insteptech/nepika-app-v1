import '../../../core/error/failures.dart';
import '../../../core/network/network_info.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/logger.dart';
import '../datasources/routine_remote_data_source.dart';
import '../models/routine_model.dart';
import '../../../domain/routine/entities/routine.dart';
import '../../../domain/routine/repositories/routine_repository.dart';

class RoutineRepositoryImpl implements RoutineRepository {
  final RoutineRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  RoutineRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Result<List<Routine>>> getTodaysRoutine(String token, String type) async {
    try {
      Logger.repository('Getting routines for type: $type');
      
      final isConnected = await networkInfo.isConnected;
      Logger.repository('Network connected: $isConnected');
      
      // Temporarily bypass network check to debug routine loading
      if (true) {
        final routineModels = await remoteDataSource.getTodaysRoutine(token, type);
        Logger.repository('Data source returned ${routineModels.length} routine models');
        
        final routines = routineModels.map((model) {
          final entity = model.toEntity();
          Logger.repository('Converted model to entity: ${entity.name} (${entity.id})');
          return entity;
        }).toList();
        
        Logger.repository('Successfully converted ${routines.length} routines to entities');
        return success(routines);
      } else {
        Logger.repository('No internet connection', error: 'Network unavailable');
        return failure(const NetworkFailure(message: 'No internet connection'));
      }
    } catch (e) {
      Logger.repository('Error getting routines', error: e);
      return failure(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> updateRoutineStep(
      String token, String routineId, bool isCompleted) async {
    try {
      Logger.repository('Updating routine step: $routineId to completed: $isCompleted');
      
      if (await networkInfo.isConnected) {
        await remoteDataSource.updateRoutineStep(token, routineId, isCompleted);
        Logger.repository('Successfully updated routine step');
        return success(null);
      } else {
        return failure(const NetworkFailure(message: 'No internet connection'));
      }
    } catch (e) {
      Logger.repository('Error updating routine step', error: e);
      return failure(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteRoutineStep(String token, String routineId) async {
    try {
      Logger.repository('Deleting routine step: $routineId');
      
      if (await networkInfo.isConnected) {
        await remoteDataSource.deleteRoutineStep(token, routineId);
        Logger.repository('Successfully deleted routine step');
        return success(null);
      } else {
        return failure(const NetworkFailure(message: 'No internet connection'));
      }
    } catch (e) {
      Logger.repository('Error deleting routine step', error: e);
      return failure(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> addRoutineStep(String token, String masterRoutineId) async {
    try {
      Logger.repository('Adding routine step: $masterRoutineId');
      
      if (await networkInfo.isConnected) {
        await remoteDataSource.addRoutineStep(token, masterRoutineId);
        Logger.repository('Successfully added routine step');
        return success(null);
      } else {
        return failure(const NetworkFailure(message: 'No internet connection'));
      }
    } catch (e) {
      Logger.repository('Error adding routine step', error: e);
      return failure(_mapExceptionToFailure(e));
    }
  }

  Failure _mapExceptionToFailure(dynamic exception) {
    final message = exception.toString();
    
    if (message.contains('401') || message.contains('Authentication')) {
      return AuthFailure(message: 'Authentication failed. Please login again.', code: 401);
    } else if (message.contains('404')) {
      return const RoutineNotFoundFailure(message: 'Routine not found', code: 404);
    } else if (message.contains('403')) {
      return const RoutinePermissionFailure(message: 'Permission denied', code: 403);
    } else if (message.contains('500')) {
      return const ServerFailure(message: 'Server error. Please try again later.', code: 500);
    } else if (message.contains('Network') || message.contains('timeout')) {
      return const NetworkFailure(message: 'Network error occurred');
    } else {
      return UnknownFailure(message: 'An unexpected error occurred: $message');
    }
  }
}