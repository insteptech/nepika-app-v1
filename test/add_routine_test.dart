import 'package:flutter_test/flutter_test.dart';
import 'package:nepika/domain/routine/usecases/add_routine_step.dart';
import 'package:nepika/domain/routine/repositories/routine_repository.dart';
import 'package:nepika/features/routine/main.dart';
import 'package:nepika/domain/routine/usecases/get_todays_routine.dart';
import 'package:nepika/domain/routine/usecases/update_routine_step.dart';
import 'package:nepika/domain/routine/usecases/delete_routine_step.dart';
import 'package:nepika/core/error/failures.dart';
import 'package:nepika/core/utils/either.dart';

class MockRoutineRepository implements RoutineRepository {
  final List<String> addedRoutineIds = [];
  
  @override
  Future<Result<List<Routine>>> getTodaysRoutine(String token, String type) async {
    return success([
      Routine(
        id: '1',
        name: 'Morning Face Wash',
        timing: 'morning',
        isCompleted: false,
        routineIcon: 'icon_wash',
        description: 'Cleanse your face with gentle cleanser',
      ),
      Routine(
        id: '2',
        name: 'Apply Moisturizer',
        timing: 'morning',
        isCompleted: false,
        routineIcon: 'icon_moisturizer',
        description: 'Apply moisturizer to keep skin hydrated',
      ),
      Routine(
        id: '3',
        name: 'Night Serum',
        timing: 'night',
        isCompleted: false,
        routineIcon: 'icon_serum',
        description: 'Apply anti-aging serum',
      ),
    ]);
  }

  @override
  Future<Result<void>> updateRoutineStep(String token, String routineId, bool isCompleted) async {
    return success(null);
  }

  @override
  Future<Result<void>> deleteRoutineStep(String token, String routineId) async {
    return success(null);
  }

  @override
  Future<Result<void>> addRoutineStep(String token, String masterRoutineId) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Track added routine IDs
    addedRoutineIds.add(masterRoutineId);
    
    // Simulate API success
    return success(null);
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
      final result = await addUseCase(token, masterRoutineId);

      // assert
      expect(result.isRight, true);
      expect(mockRepository.addedRoutineIds, contains(masterRoutineId));
    });

    test('should emit correct states when adding routine step', () async {
      // arrange
      const token = 'test_token';
      const masterRoutineId = '1';

      // Load initial routines first
      routineBloc.add(const LoadAllRoutinesEvent(token: token));
      
      // Wait for initial load to complete
      await Future.delayed(const Duration(milliseconds: 50));

      // Expect states
      final expectedStates = [
        isA<RoutineLoading>(),
        isA<RoutineLoaded>(),
        isA<RoutineOperationLoading>(),
        isA<RoutineOperationSuccess>(),
      ];

      // act
      expectLater(
        routineBloc.stream,
        emitsInOrder(expectedStates),
      );

      // Add routine step
      routineBloc.add(const AddRoutineStepEvent(
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
      errorBloc.add(const LoadAllRoutinesEvent(token: token));
      await Future.delayed(const Duration(milliseconds: 50));

      // Expect error state
      expectLater(
        errorBloc.stream,
        emitsInOrder([
          isA<RoutineLoading>(),
          isA<RoutineLoaded>(),
          isA<RoutineOperationLoading>(),
          isA<RoutineError>(),
        ]),
      );

      // act
      errorBloc.add(const AddRoutineStepEvent(
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
      const event = AddRoutineStepEvent(
        token: token,
        masterRoutineId: masterRoutineId,
      );

      // assert
      expect(event.token, equals(token));
      expect(event.masterRoutineId, equals(masterRoutineId));
    });

    test('RoutineOperationLoading state should contain correct properties', () {
      // arrange
      final routines = [
        Routine(
          id: '1',
          name: 'Test Routine',
          timing: 'morning',
          isCompleted: false,
          routineIcon: 'test_icon',
          description: 'Test',
        ),
      ];
      const operationId = '1';

      // act
      final state = RoutineOperationLoading(
        currentRoutines: routines,
        operationId: operationId,
      );

      // assert
      expect(state.currentRoutines, equals(routines));
      expect(state.operationId, equals(operationId));
    });

    test('RoutineOperationSuccess state should contain correct properties', () {
      // arrange
      final routines = [
        Routine(
          id: '1',
          name: 'Test Routine',
          timing: 'morning',
          isCompleted: false,
          routineIcon: 'test_icon',
          description: 'Test',
        ),
      ];
      const message = 'Operation successful';
      const operationId = '1';

      // act
      final state = RoutineOperationSuccess(
        routines: routines,
        message: message,
        operationId: operationId,
      );

      // assert
      expect(state.routines, equals(routines));
      expect(state.message, equals(message));
      expect(state.operationId, equals(operationId));
    });
  });
}

class MockErrorRoutineRepository implements RoutineRepository {
  @override
  Future<Result<List<Routine>>> getTodaysRoutine(String token, String type) async {
    return success([
      Routine(
        id: '1',
        name: 'Test Routine',
        timing: 'morning',
        isCompleted: false,
        routineIcon: 'test_icon',
        description: 'Test',
      ),
    ]);
  }

  @override
  Future<Result<void>> updateRoutineStep(String token, String routineId, bool isCompleted) async {
    return failure(ServerFailure(message: 'Update failed'));
  }

  @override
  Future<Result<void>> deleteRoutineStep(String token, String routineId) async {
    return failure(ServerFailure(message: 'Delete failed'));
  }

  @override
  Future<Result<void>> addRoutineStep(String token, String masterRoutineId) async {
    return failure(ServerFailure(message: 'Add routine failed - server error'));
  }
}