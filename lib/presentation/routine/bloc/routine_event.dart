import '../../../domain/routine/entities/routine.dart';

abstract class RoutineEvent {}

class GetTodaysRoutineEvent extends RoutineEvent {
  final String token;
  final String type;

  GetTodaysRoutineEvent({required this.token, required this.type});
}

class UpdateRoutineStepEvent extends RoutineEvent {
  final String token;
  final String stepId;
  final bool isCompleted;

  UpdateRoutineStepEvent({
    required this.token,
    required this.stepId,
    required this.isCompleted,
  });
}

class AddRoutineStepEvent extends RoutineEvent {
  final String token;
  final Routine routine;

  AddRoutineStepEvent({required this.token, required this.routine});
}

class DeleteRoutineStepEvent extends RoutineEvent {
  final String token;
  final String stepId;

  DeleteRoutineStepEvent({required this.token, required this.stepId});
}
