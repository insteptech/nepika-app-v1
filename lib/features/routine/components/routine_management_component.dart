import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/routine/entities/routine.dart';
import '../bloc/routine_bloc.dart';
import '../bloc/routine_state.dart';
import '../widgets/routine_list.dart';
import '../widgets/routine_empty_states.dart';
import '../widgets/routine_tile.dart';

/// A complex component that handles different routine management scenarios
/// with proper state management and user interaction
class RoutineManagementComponent extends StatelessWidget {
  final RoutineTileType displayType;
  final bool showLoading;
  final Function(String routineId)? onRoutineAdd;
  final Function(String routineId)? onRoutineDelete;
  final Function(String routineId)? onRoutineToggle;
  final Function()? onRetry;
  final Function()? onAddNew;
  final String emptyStateTitle;
  final String emptyStateSubtitle;
  final String? emptyActionText;

  const RoutineManagementComponent({
    super.key,
    required this.displayType,
    this.showLoading = false,
    this.onRoutineAdd,
    this.onRoutineDelete,
    this.onRoutineToggle,
    this.onRetry,
    this.onAddNew,
    this.emptyStateTitle = 'No routines found',
    this.emptyStateSubtitle = 'No routines are available at this time',
    this.emptyActionText,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutineBloc, RoutineState>(
      builder: (context, state) {
        if (showLoading || state is RoutineLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is RoutineError) {
          return RoutineErrorWidget(
            message: state.failure.message,
            onRetry: onRetry,
          );
        }

        List<Routine> routines = [];
        String? loadingRoutineId;
        Set<String> successfullyAddedIds = {};

        if (state is RoutineLoaded) {
          routines = state.routines;
        } else if (state is RoutineOperationLoading) {
          routines = state.currentRoutines;
          loadingRoutineId = state.operationId;
        } else if (state is RoutineOperationSuccess) {
          routines = state.routines;
        }

        if (routines.isEmpty) {
          return _buildEmptyState(context);
        }

        return RoutineList(
          routines: routines,
          tileType: displayType,
          loadingRoutineId: loadingRoutineId,
          successfullyAddedRoutineIds: successfullyAddedIds,
          onAddRoutine: onRoutineAdd,
          onDeleteRoutine: onRoutineDelete,
          onToggleComplete: onRoutineToggle,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    switch (displayType) {
      case RoutineTileType.daily:
        return NoRoutinesFound(onAddRoutines: onAddNew);
      case RoutineTileType.selection:
        return NoRoutinesAvailable(onRefresh: onRetry);
      case RoutineTileType.editable:
        return NoRoutinesFound(onAddRoutines: onAddNew);
    }
  }
}

/// A component for displaying routine statistics and progress
class RoutineStatsComponent extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final double? progressPercentage;

  const RoutineStatsComponent({
    super.key,
    required this.completedCount,
    required this.totalCount,
    this.progressPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = progressPercentage ?? 
        (totalCount > 0 ? (completedCount / totalCount) * 100 : 0.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '$completedCount of $totalCount steps completed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// A component for routine action buttons (edit, add, etc.)
class RoutineActionsComponent extends StatelessWidget {
  final List<RoutineAction> actions;

  const RoutineActionsComponent({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: actions.map((action) => _buildActionButton(context, action)).toList(),
    );
  }

  Widget _buildActionButton(BuildContext context, RoutineAction action) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: action.isPrimary
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(8),
          color: action.isPrimary
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (action.icon != null) ...[
              Icon(
                action.icon,
                size: 18,
                color: action.isPrimary
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              action.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: action.isPrimary
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: action.isPrimary ? FontWeight.w500 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class for routine actions
class RoutineAction {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isPrimary;

  const RoutineAction({
    required this.label,
    this.onTap,
    this.icon,
    this.isPrimary = false,
  });
}