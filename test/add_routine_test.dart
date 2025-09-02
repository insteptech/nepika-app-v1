import 'package:flutter_test/flutter_test.dart';
import 'package:nepika/domain/routine/entities/routine.dart';
import 'package:nepika/domain/routine/usecases/add_routine_step.dart';
import 'package:nepika/domain/routine/repositories/routine_repository.dart';
import 'package:nepika/presentation/routine/bloc/routine_bloc.dart';
import 'package:nepika/presentation/routine/bloc/routine_event.dart';
import 'package:nepika/presentation/routine/bloc/routine_state.dart';
import 'package:nepika/domain/routine/usecases/get_todays_routine.dart';
import 'package:nepika/domain/routine/usecases/update_routine_step.dart';
import 'package:nepika/domain/routine/usecases/delete_routine_step.dart';

class MockRoutineRepository implements RoutineRepository {
  final List<String> addedRoutineIds = [];
  
  @override
  Future<List<Routine>> getTodaysRoutine(String token, String type) async {
    return [
      Routine(
        id: '1',
        name: 'Morning Face Wash',
        timing: 'morning',
        isCompleted: false,
        description: 'Cleanse your face with gentle cleanser',
      ),
      Routine(
        id: '2',
        name: 'Apply Moisturizer',
        timing: 'morning',
        isCompleted: false,
        description: 'Apply moisturizer to keep skin hydrated',
      ),
      Routine(
        id: '3',
        name: 'Night Serum',
        timing: 'night',
        isCompleted: false,
        description: 'Apply anti-aging serum',
      ),
    ];
  }

  @override
  Future<void> updateRoutineStep(String token, String routineId, bool isCompleted) async {
    // Mock implementation
    return;
  }

  @override
  Future<void> deleteRoutineStep(String token, String routineId) async {
    // Mock implementation
    return;
  }

  @override
  Future<void> addRoutineStep(String token, String masterRoutineId) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Track added routine IDs
    addedRoutineIds.add(masterRoutineId);
    
    // Simulate API success
    return;
  }
}

void main() {
  group('Add Routine Functionality Tests', () {
    late MockRoutineRepository mockRepository;
    late RoutineBloc routineBloc;

    setUp(() {
      mockRepository = MockRoutineRepository();
      routineBloc = RoutineBloc(
        getTodaysRoutine: GetTodaysRoutine(mockRepository),
        updateRoutineStep: UpdateRoutineStep(mockRepository),
        deleteRoutineStep: DeleteRoutineStep(mockRepository),
        addRoutineStep: AddRoutineStep(mockRepository),
      );
    });

    tearDown(() {
      routineBloc.close();
    });

    test('should add routine step successfully', () async {
      // arrange
      const token = 'test_token';
      const masterRoutineId = '1';

      // act
      final addUseCase = AddRoutineStep(mockRepository);
      await addUseCase(token, masterRoutineId);

      // assert
      expect(mockRepository.addedRoutineIds, contains(masterRoutineId));
    });

    test('should emit correct states when adding routine step', () async {
      // arrange
      const token = 'test_token';
      const masterRoutineId = '1';

      // Load initial routines first
      routineBloc.add(GetAllRoutinesEvent(token: token));
      
      // Wait for initial load to complete
      await Future.delayed(const Duration(milliseconds: 50));

      // Expect states
      final expectedStates = [
        isA<RoutineLoading>(),
        isA<RoutineLoaded>(),
        isA<RoutineAddLoading>(),
        isA<RoutineAddSuccess>(),
      ];

      // act
      expectLater(
        routineBloc.stream,
        emitsInOrder(expectedStates),
      );

      // Add routine step
      routineBloc.add(AddRoutineStepEvent(
        token: token,
        masterRoutineId: masterRoutineId,
      ));

      // Allow time for async operations
      await Future.delayed(const Duration(milliseconds: 200));
    });

    test('should handle add routine step error correctly', () async {
      // arrange - Create a repository that throws an error
      final errorRepository = MockErrorRoutineRepository();
      final errorBloc = RoutineBloc(
        getTodaysRoutine: GetTodaysRoutine(errorRepository),
        updateRoutineStep: UpdateRoutineStep(errorRepository),
        deleteRoutineStep: DeleteRoutineStep(errorRepository),
        addRoutineStep: AddRoutineStep(errorRepository),
      );

      const token = 'test_token';
      const masterRoutineId = '1';

      // Load initial routines first
      errorBloc.add(GetAllRoutinesEvent(token: token));
      await Future.delayed(const Duration(milliseconds: 50));

      // Expect error state
      expectLater(
        errorBloc.stream,
        emitsInOrder([
          isA<RoutineLoading>(),
          isA<RoutineLoaded>(),
          isA<RoutineAddLoading>(),
          isA<RoutineError>(),
        ]),
      );

      // act
      errorBloc.add(AddRoutineStepEvent(
        token: token,
        masterRoutineId: masterRoutineId,
      ));

      // Allow time for async operations
      await Future.delayed(const Duration(milliseconds: 200));

      errorBloc.close();
    });

    test('AddRoutineStepEvent should contain correct properties', () {
      // arrange
      const token = 'test_token';
      const masterRoutineId = '123';

      // act
      final event = AddRoutineStepEvent(
        token: token,
        masterRoutineId: masterRoutineId,
      );

      // assert
      expect(event.token, equals(token));
      expect(event.masterRoutineId, equals(masterRoutineId));
    });

    test('RoutineAddLoading state should contain correct properties', () {
      // arrange
      final routines = [
        Routine(
          id: '1',
          name: 'Test Routine',
          timing: 'morning',
          isCompleted: false,
          description: 'Test',
        ),
      ];
      const loadingRoutineId = '1';

      // act
      final state = RoutineAddLoading(routines, loadingRoutineId);

      // assert
      expect(state.routines, equals(routines));
      expect(state.loadingRoutineId, equals(loadingRoutineId));
    });

    test('RoutineAddSuccess state should contain correct properties', () {
      // arrange
      final routines = [
        Routine(
          id: '1',
          name: 'Test Routine',
          timing: 'morning',
          isCompleted: false,
          description: 'Test',
        ),
      ];
      const addedRoutineId = '1';

      // act
      final state = RoutineAddSuccess(routines, addedRoutineId);

      // assert
      expect(state.routines, equals(routines));
      expect(state.addedRoutineId, equals(addedRoutineId));
    });
  });
}

class MockErrorRoutineRepository implements RoutineRepository {
  @override
  Future<List<Routine>> getTodaysRoutine(String token, String type) async {
    return [
      Routine(
        id: '1',
        name: 'Test Routine',
        timing: 'morning',
        isCompleted: false,
        description: 'Test',
      ),
    ];
  }

  @override
  Future<void> updateRoutineStep(String token, String routineId, bool isCompleted) async {
    throw Exception('Update failed');
  }

  @override
  Future<void> deleteRoutineStep(String token, String routineId) async {
    throw Exception('Delete failed');
  }

  @override
  Future<void> addRoutineStep(String token, String masterRoutineId) async {
    throw Exception('Add routine failed - server error');
  }
}