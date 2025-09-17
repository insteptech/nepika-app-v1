// lib/presentation/routine/bloc/routine_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/routine/entities/routine.dart';
import '../../../domain/routine/usecases/get_todays_routine.dart';
import '../../../domain/routine/usecases/update_routine_step.dart';
import '../../../domain/routine/usecases/delete_routine_step.dart';
import '../../../domain/routine/usecases/add_routine_step.dart';
import 'routine_event.dart';
import 'routine_state.dart';

class RoutineBloc extends Bloc<RoutineEvent, RoutineState> {
  final GetTodaysRoutine getTodaysRoutine;
  final UpdateRoutineStep updateRoutineStep;
  final DeleteRoutineStep deleteRoutineStep;
  final AddRoutineStep addRoutineStep;

  // Keep track of current routine type for refreshing
  String? _currentRoutineType;

  RoutineBloc({
    required this.getTodaysRoutine,
    required this.updateRoutineStep,
    required this.deleteRoutineStep,
    required this.addRoutineStep,
  }) : super(const RoutineInitial()) {
    
    on<LoadTodaysRoutineEvent>(_onLoadTodaysRoutine);
    on<LoadAllRoutinesEvent>(_onLoadAllRoutines);
    on<RefreshRoutinesEvent>(_onRefreshRoutines);
    on<UpdateRoutineStepEvent>(_onUpdateRoutineStep);
    on<DeleteRoutineStepEvent>(_onDeleteRoutineStep);
    on<AddRoutineStepEvent>(_onAddRoutineStep);
    on<ResetRoutineErrorEvent>(_onResetError);
    on<ClearRoutineStateEvent>(_onClearState);
  }

  Future<void> _onLoadTodaysRoutine(
    LoadTodaysRoutineEvent event,
    Emitter<RoutineState> emit,
  ) async {
    Logger.bloc('Loading today\'s routines for type: ${event.type}');
    emit(const RoutineLoading());
    _currentRoutineType = event.type;
    
    final result = await getTodaysRoutine(event.token, event.type);
    
    result.fold(
      (failure) {
        Logger.bloc('Failed to load routines', error: failure);
        emit(RoutineError(failure: failure));
      },
      (routines) {
        Logger.bloc('Successfully loaded ${routines.length} routines');
        emit(RoutineLoaded(routines: routines));
      },
    );
  }

  Future<void> _onLoadAllRoutines(
    LoadAllRoutinesEvent event,
    Emitter<RoutineState> emit,
  ) async {
    Logger.bloc('Loading all available routines');
    emit(const RoutineLoading());
    _currentRoutineType = 'all';
    
    final result = await getTodaysRoutine(event.token, 'all');
    
    result.fold(
      (failure) {
        Logger.bloc('Failed to load all routines', error: failure);
        emit(RoutineError(failure: failure));
      },
      (routines) {
        Logger.bloc('Use case returned ${routines.length} routines');
        for (final routine in routines) {
          Logger.bloc('Routine: ${routine.name} (${routine.id}) - ${routine.timing}');
        }
        Logger.bloc('Emitting RoutineLoaded state with ${routines.length} routines');
        emit(RoutineLoaded(routines: routines));
      },
    );
  }

  Future<void> _onRefreshRoutines(
    RefreshRoutinesEvent event,
    Emitter<RoutineState> emit,
  ) async {
    Logger.bloc('Refreshing routines for type: ${event.type}');
    _currentRoutineType = event.type;
    
    final result = await getTodaysRoutine(event.token, event.type);
    
    result.fold(
      (failure) {
        Logger.bloc('Failed to refresh routines', error: failure);
        emit(RoutineError(failure: failure));
      },
      (routines) {
        Logger.bloc('Successfully refreshed ${routines.length} routines');
        emit(RoutineLoaded(routines: routines));
      },
    );
  }

  Future<void> _onUpdateRoutineStep(
    UpdateRoutineStepEvent event,
    Emitter<RoutineState> emit,
  ) async {
    Logger.bloc('Updating routine step: ${event.routineId} to ${event.isCompleted}');
    
    // Get current routines to show optimistic update
    final currentRoutines = _getCurrentRoutines();
    emit(RoutineOperationLoading(
      currentRoutines: currentRoutines,
      operationId: event.routineId,
    ));
    
    final result = await updateRoutineStep(event.token, event.routineId, event.isCompleted);
    
    await result.fold(
      (failure) async {
        Logger.bloc('Failed to update routine step', error: failure);
        emit(RoutineError(failure: failure));
      },
      (success) async {
        Logger.bloc('Successfully updated routine step');
        // Update the local routine data instead of refreshing from server
        final updatedRoutines = _updateLocalRoutineCompletion(event.routineId, event.isCompleted);
        emit(RoutineOperationSuccess(
          routines: updatedRoutines,
          message: 'Routine step updated successfully',
          operationId: event.routineId,
        ));
      },
    );
  }

  Future<void> _onDeleteRoutineStep(
    DeleteRoutineStepEvent event,
    Emitter<RoutineState> emit,
  ) async {
    Logger.bloc('Deleting routine step: ${event.routineId}');
    
    final currentRoutines = _getCurrentRoutines();
    emit(RoutineOperationLoading(
      currentRoutines: currentRoutines,
      operationId: event.routineId,
    ));
    
    final result = await deleteRoutineStep(event.token, event.routineId);
    
    await result.fold(
      (failure) async {
        Logger.bloc('Failed to delete routine step', error: failure);
        emit(RoutineError(failure: failure));
      },
      (success) async {
        Logger.bloc('Successfully deleted routine step');
        // Update local data by removing the deleted routine
        final updatedRoutines = _removeLocalRoutine(event.routineId);
        emit(RoutineOperationSuccess(
          routines: updatedRoutines,
          message: 'Routine step deleted successfully',
          operationId: event.routineId,
        ));
      },
    );
  }

  Future<void> _onAddRoutineStep(
    AddRoutineStepEvent event,
    Emitter<RoutineState> emit,
  ) async {
    Logger.bloc('Adding routine step: ${event.masterRoutineId}');
    
    final currentRoutines = _getCurrentRoutines();
    emit(RoutineOperationLoading(
      currentRoutines: currentRoutines,
      operationId: event.masterRoutineId,
    ));
    
    final result = await addRoutineStep(event.token, event.masterRoutineId);
    
    await result.fold(
      (failure) async {
        Logger.bloc('Failed to add routine step', error: failure);
        emit(RoutineError(failure: failure));
      },
      (success) async {
        Logger.bloc('Successfully added routine step');
        emit(RoutineOperationSuccess(
          routines: currentRoutines,
          message: 'Routine step added successfully',
          operationId: event.masterRoutineId,
        ));
      },
    );
  }

  Future<void> _onResetError(
    ResetRoutineErrorEvent event,
    Emitter<RoutineState> emit,
  ) async {
    Logger.bloc('Resetting routine error state');
    
    if (state is RoutineError) {
      emit(const RoutineInitial());
    }
  }

  Future<void> _onClearState(
    ClearRoutineStateEvent event,
    Emitter<RoutineState> emit,
  ) async {
    Logger.bloc('Clearing routine state');
    _currentRoutineType = null;
    emit(const RoutineInitial());
  }

  // Helper methods
  List<Routine> _getCurrentRoutines() {
    if (state is RoutineLoaded) {
      return (state as RoutineLoaded).routines;
    } else if (state is RoutineOperationLoading) {
      return (state as RoutineOperationLoading).currentRoutines;
    } else if (state is RoutineOperationSuccess) {
      return (state as RoutineOperationSuccess).routines;
    }
    return [];
  }


  // Update local routine completion status without API call
  List<Routine> _updateLocalRoutineCompletion(String routineId, bool isCompleted) {
    final currentRoutines = _getCurrentRoutines();
    return currentRoutines.map((routine) {
      if (routine.id == routineId) {
        return Routine(
          id: routine.id,
          isCompleted: isCompleted,
          name: routine.name,
          timing: routine.timing,
          routineIcon: routine.routineIcon,
          description: routine.description,
        );
      }
      return routine;
    }).toList();
  }

  // Remove routine from local data without API call
  List<Routine> _removeLocalRoutine(String routineId) {
    final currentRoutines = _getCurrentRoutines();
    return currentRoutines.where((routine) => routine.id != routineId).toList();
  }
}