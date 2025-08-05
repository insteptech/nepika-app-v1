import '../models/routine_model.dart';

abstract class RoutineRemoteDataSource {
  Future<List<RoutineModel>> getTodaysRoutine();
  Future<RoutineModel> updateRoutineStep(String routineId, bool isCompleted);
  Future<void> createRoutine(RoutineModel routine);
  Future<void> deleteRoutine(String routineId);
}

class RoutineRemoteDataSourceImpl implements RoutineRemoteDataSource {
  @override
  Future<List<RoutineModel>> getTodaysRoutine() async {
    // TODO: Implement API call to get today's routine
    // For now, return mock data
    await Future.delayed(const Duration(seconds: 1));
    
    return [
      RoutineModel(
        id: '1',
        name: 'Morning Exercise',
        timing: '7:00 AM',
        isCompleted: false,
        description: 'Start your day with light exercise',
      ),
      RoutineModel(
        id: '2',
        name: 'Breakfast',
        timing: '8:00 AM',
        isCompleted: false,
        description: 'Healthy breakfast to fuel your day',
      ),
      RoutineModel(
        id: '3',
        name: 'Work',
        timing: '9:00 AM',
        isCompleted: false,
        description: 'Focus time for important tasks',
      ),
    ];
  }

  @override
  Future<RoutineModel> updateRoutineStep(String routineId, bool isCompleted) async {
    // TODO: Implement API call to update routine step
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mock updated routine
    return RoutineModel(
      id: routineId,
      name: 'Updated Routine',
      timing: '9:00 AM',
      isCompleted: isCompleted,
    );
  }

  @override
  Future<void> createRoutine(RoutineModel routine) async {
    // TODO: Implement API call to create routine
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> deleteRoutine(String routineId) async {
    // TODO: Implement API call to delete routine
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
