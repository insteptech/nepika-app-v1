import '../../../domain/routine/entities/routine.dart';

abstract class RoutineState {}

class RoutineInitial extends RoutineState {}

class RoutineLoading extends RoutineState {}

class RoutineLoaded extends RoutineState {
  final List<Routine> routines;

  RoutineLoaded({required this.routines});
}

class RoutineError extends RoutineState {
  final String message;

  RoutineError({required this.message});
}

class RoutineStepUpdated extends RoutineState {
  final String stepId;
  final bool isCompleted;

  RoutineStepUpdated({required this.stepId, required this.isCompleted});
}

class RoutineStepAdded extends RoutineState {}

class RoutineStepDeleted extends RoutineState {
  final String stepId;

  RoutineStepDeleted({required this.stepId});
}
