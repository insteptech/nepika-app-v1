// lib/presentation/routine/bloc/routine_state.dart
import 'package:equatable/equatable.dart';
import '../../../core/error/failures.dart';
import '../../../domain/routine/entities/routine.dart';

abstract class RoutineState extends Equatable {
  const RoutineState();
  
  @override
  List<Object?> get props => [];
}

class RoutineInitial extends RoutineState {
  const RoutineInitial();
}

class RoutineLoading extends RoutineState {
  const RoutineLoading();
}

class RoutineLoaded extends RoutineState {
  final List<Routine> routines;
  final String? lastUpdatedRoutineId;

  const RoutineLoaded({
    required this.routines,
    this.lastUpdatedRoutineId,
  });

  @override
  List<Object?> get props => [routines, lastUpdatedRoutineId];

  RoutineLoaded copyWith({
    List<Routine>? routines,
    String? lastUpdatedRoutineId,
  }) {
    return RoutineLoaded(
      routines: routines ?? this.routines,
      lastUpdatedRoutineId: lastUpdatedRoutineId ?? this.lastUpdatedRoutineId,
    );
  }
}

class RoutineError extends RoutineState {
  final Failure failure;

  const RoutineError({required this.failure});

  @override
  List<Object?> get props => [failure];
}

// Specific states for different operations
class RoutineOperationLoading extends RoutineState {
  final List<Routine> currentRoutines;
  final String? operationId; // For tracking specific operations

  const RoutineOperationLoading({
    required this.currentRoutines,
    this.operationId,
  });

  @override
  List<Object?> get props => [currentRoutines, operationId];
}

class RoutineOperationSuccess extends RoutineState {
  final List<Routine> routines;
  final String message;
  final String? operationId;

  const RoutineOperationSuccess({
    required this.routines,
    required this.message,
    this.operationId,
  });

  @override
  List<Object?> get props => [routines, message, operationId];
}