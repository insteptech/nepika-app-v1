import 'package:equatable/equatable.dart';

abstract class RoutineEvent extends Equatable {
  const RoutineEvent();
  
  @override
  List<Object?> get props => [];
}

// Load routines events
class LoadTodaysRoutineEvent extends RoutineEvent {
  final String token;
  final String type;

  const LoadTodaysRoutineEvent({
    required this.token, 
    required this.type,
  });

  @override
  List<Object?> get props => [token, type];
}

class LoadAllRoutinesEvent extends RoutineEvent {
  final String token;

  const LoadAllRoutinesEvent({required this.token});

  @override
  List<Object?> get props => [token];
}

class RefreshRoutinesEvent extends RoutineEvent {
  final String token;
  final String type;

  const RefreshRoutinesEvent({
    required this.token,
    required this.type,
  });

  @override
  List<Object?> get props => [token, type];
}

// CRUD operations
class UpdateRoutineStepEvent extends RoutineEvent {
  final String token;
  final String routineId;
  final bool isCompleted;

  const UpdateRoutineStepEvent({
    required this.token,
    required this.routineId,
    required this.isCompleted,
  });

  @override
  List<Object?> get props => [token, routineId, isCompleted];
}

class DeleteRoutineStepEvent extends RoutineEvent {
  final String token;
  final String routineId;

  const DeleteRoutineStepEvent({
    required this.token,
    required this.routineId,
  });

  @override
  List<Object?> get props => [token, routineId];
}

class AddRoutineStepEvent extends RoutineEvent {
  final String token;
  final String masterRoutineId;

  const AddRoutineStepEvent({
    required this.token,
    required this.masterRoutineId,
  });

  @override
  List<Object?> get props => [token, masterRoutineId];
}

// State management events
class ResetRoutineErrorEvent extends RoutineEvent {
  const ResetRoutineErrorEvent();
}

class ClearRoutineStateEvent extends RoutineEvent {
  const ClearRoutineStateEvent();
}