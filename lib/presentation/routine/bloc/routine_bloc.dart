import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/routine/usecases/get_todays_routine.dart';
import '../../../domain/routine/usecases/update_routine_step.dart';
import 'routine_event.dart';
import 'routine_state.dart';

class RoutineBloc extends Bloc<RoutineEvent, RoutineState> {
  final GetTodaysRoutine getTodaysRoutine;
  final UpdateRoutineStep updateRoutineStep;

  RoutineBloc({
    required this.getTodaysRoutine,
    required this.updateRoutineStep,
  }) : super(RoutineInitial()) {
    on<GetTodaysRoutineEvent>(_onGetTodaysRoutine);
    on<UpdateRoutineStepEvent>(_onUpdateRoutineStep);
  }

  Future<void> _onGetTodaysRoutine(
    GetTodaysRoutineEvent event,
    Emitter<RoutineState> emit,
  ) async {
    emit(RoutineLoading());
    final result = await getTodaysRoutine(GetTodaysRoutineParams(
      token: event.token,
      type: event.type,
    ));
    result.fold(
      (failure) => emit(RoutineError(message: failure.message)),
      (routines) => emit(RoutineLoaded(routines: routines)),
    );
  }

  Future<void> _onUpdateRoutineStep(
    UpdateRoutineStepEvent event,
    Emitter<RoutineState> emit,
  ) async {
    final result = await updateRoutineStep(UpdateRoutineStepParams(
      token: event.token,
      stepId: event.stepId,
      isCompleted: event.isCompleted,
    ));
    result.fold(
      (failure) => emit(RoutineError(message: failure.message)),
      (_) => emit(RoutineStepUpdated(
        stepId: event.stepId,
        isCompleted: event.isCompleted,
      )),
    );
  }
}
