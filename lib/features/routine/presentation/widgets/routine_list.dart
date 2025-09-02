import 'package:flutter/material.dart';
import '../../../../domain/routine/entities/routine.dart';
import 'routine_tile.dart';

class RoutineList extends StatelessWidget {
  final List<Routine> routines;
  final RoutineTileType tileType;
  final String? loadingRoutineId;
  final Function(String routineId)? onRoutineTap;
  final Function(String routineId)? onAddRoutine;
  final Function(String routineId)? onDeleteRoutine;
  final Function(String routineId)? onToggleComplete;
  final Widget? emptyWidget;

  const RoutineList({
    super.key,
    required this.routines,
    required this.tileType,
    this.loadingRoutineId,
    this.onRoutineTap,
    this.onAddRoutine,
    this.onDeleteRoutine,
    this.onToggleComplete,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (routines.isEmpty && emptyWidget != null) {
      return emptyWidget!;
    }

    return ListView.builder(
      itemCount: routines.length,
      itemBuilder: (context, index) {
        final routine = routines[index];
        final isLoading = loadingRoutineId == routine.id;

        return RoutineTile(
          routine: routine,
          type: tileType,
          isLoading: isLoading,
          onTap: onRoutineTap != null ? () => onRoutineTap!(routine.id) : null,
          onAdd: onAddRoutine != null ? () => onAddRoutine!(routine.id) : null,
          onDelete: onDeleteRoutine != null ? () => onDeleteRoutine!(routine.id) : null,
          onToggleComplete: onToggleComplete != null ? () => onToggleComplete!(routine.id) : null,
        );
      },
    );
  }
}

class RoutineListBuilder extends StatelessWidget {
  final List<Routine> routines;
  final RoutineTileType tileType;
  final String? loadingRoutineId;
  final Function(String routineId)? onRoutineTap;
  final Function(String routineId)? onAddRoutine;
  final Function(String routineId)? onDeleteRoutine;
  final Function(String routineId)? onToggleComplete;
  final Widget Function() emptyBuilder;
  final Widget Function() loadingBuilder;
  final Widget Function(String error) errorBuilder;

  const RoutineListBuilder({
    super.key,
    required this.routines,
    required this.tileType,
    required this.emptyBuilder,
    required this.loadingBuilder,
    required this.errorBuilder,
    this.loadingRoutineId,
    this.onRoutineTap,
    this.onAddRoutine,
    this.onDeleteRoutine,
    this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    return RoutineList(
      routines: routines,
      tileType: tileType,
      loadingRoutineId: loadingRoutineId,
      onRoutineTap: onRoutineTap,
      onAddRoutine: onAddRoutine,
      onDeleteRoutine: onDeleteRoutine,
      onToggleComplete: onToggleComplete,
      emptyWidget: emptyBuilder(),
    );
  }
}