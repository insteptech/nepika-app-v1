import 'package:flutter_test/flutter_test.dart';
import 'package:nepika/domain/routine/entities/routine.dart';
import 'package:nepika/domain/routine/usecases/get_todays_routine.dart';
import 'package:nepika/domain/routine/usecases/update_routine_step.dart';
import 'package:nepika/domain/routine/usecases/delete_routine_step.dart';
import 'package:nepika/domain/routine/repositories/routine_repository.dart';

class MockRoutineRepository implements RoutineRepository {
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
    // Mock implementation
    return;
  }
}

void main() {
  group('Routine Module Tests', () {
    late MockRoutineRepository mockRepository;
    late GetTodaysRoutine getTodaysRoutine;
    late UpdateRoutineStep updateRoutineStep;
    late DeleteRoutineStep deleteRoutineStep;

    setUp(() {
      mockRepository = MockRoutineRepository();
      getTodaysRoutine = GetTodaysRoutine(mockRepository);
      updateRoutineStep = UpdateRoutineStep(mockRepository);
      deleteRoutineStep = DeleteRoutineStep(mockRepository);
    });

    test('should get today\'s routines', () async {
      // arrange
      const token = 'test_token';
      const type = 'get-user-routines';

      // act
      final result = await getTodaysRoutine(token, type);

      // assert
      expect(result, isA<List<Routine>>());
      expect(result.length, equals(2));
      expect(result.first.name, equals('Morning Face Wash'));
      expect(result.first.timing, equals('morning'));
    });

    test('should update routine step', () async {
      // arrange
      const token = 'test_token';
      const routineId = '1';
      const isCompleted = true;

      // act & assert - should not throw any exception
      await expectLater(
        updateRoutineStep(token, routineId, isCompleted),
        completes,
      );
    });

    test('should delete routine step', () async {
      // arrange
      const token = 'test_token';
      const routineId = '1';

      // act & assert - should not throw any exception
      await expectLater(
        deleteRoutineStep(token, routineId),
        completes,
      );
    });

    test('Routine entity should create from JSON correctly', () {
      // arrange
      final json = {
        'id': '1',
        'name': 'Test Routine',
        'timing': 'morning',
        'isCompleted': true,
        'description': 'Test Description',
      };

      // act
      final routine = Routine.fromJson(json);

      // assert
      expect(routine.id, equals('1'));
      expect(routine.name, equals('Test Routine'));
      expect(routine.timing, equals('morning'));
      expect(routine.isCompleted, equals(true));
      expect(routine.description, equals('Test Description'));
    });

    test('Routine entity should handle missing JSON fields', () {
      // arrange
      final json = <String, dynamic>{};

      // act
      final routine = Routine.fromJson(json);

      // assert
      expect(routine.id, equals(''));
      expect(routine.name, equals(''));
      expect(routine.timing, equals(''));
      expect(routine.isCompleted, equals(false));
      expect(routine.description, equals(''));
    });
  });
}