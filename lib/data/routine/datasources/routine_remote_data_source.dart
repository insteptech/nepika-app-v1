// lib/data/routine/datasources/routine_remote_data_source.dart

import '../models/routine_model.dart';

abstract class RoutineRemoteDataSource {
  Future<List<RoutineModel>> getTodaysRoutine(String token, String type);
  Future<void> updateRoutineStep(String token, String routineId, bool isCompleted);
  Future<void> deleteRoutineStep(String token, String routineId);
  Future<void> addRoutineStep(String token, String masterRoutineId);
}