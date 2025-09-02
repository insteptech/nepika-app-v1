import 'package:flutter/material.dart';
import '../../../../core/config/constants/theme.dart';
import '../../../../core/config/env.dart';
import '../../../../domain/routine/entities/routine.dart';

enum RoutineTileType {
  daily,     // For daily routine page
  selection, // For add routine page
  editable,  // For edit routine page
}

class RoutineTile extends StatelessWidget {
  final Routine routine;
  final RoutineTileType type;
  final bool isLoading;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleComplete;

  const RoutineTile({
    super.key,
    required this.routine,
    required this.type,
    this.isLoading = false,
    this.onTap,
    this.onAdd,
    this.onDelete,
    this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildIcon(context),
          const SizedBox(width: 12),
          Expanded(child: _buildContent(context)),
          const SizedBox(width: 12),
          _buildAction(context),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = routine.timing == 'morning'
        ? colorScheme.onSecondary
        : colorScheme.primary;

    return SizedBox(
      width: 44,
      height: 44,
      child: routine.routineIcon.isNotEmpty
          ? Image.network(
              '${Env.baseUrl}${routine.routineIcon}',
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => _buildFallbackIcon(context, color),
            )
          : _buildFallbackIcon(context, color),
    );
  }

  Widget _buildFallbackIcon(BuildContext context, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        routine.timing == 'morning' ? Icons.wb_sunny : Icons.nightlight,
        color: routine.timing == 'morning'
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        size: 24,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final timing = routine.timing == 'morning' ? 'Morning Routine' : 'Night Routine';
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          routine.name.isNotEmpty ? routine.name : 'Routine Step',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: type == RoutineTileType.selection ? FontWeight.w400 : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          timing,
          style: Theme.of(context).textTheme.bodyLarge?.secondary(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (type == RoutineTileType.selection && routine.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            routine.description,
            style: Theme.of(context).textTheme.bodySmall?.secondary(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildAction(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    switch (type) {
      case RoutineTileType.daily:
        return _buildDailyAction(context);
      case RoutineTileType.selection:
        return _buildSelectionAction(context);
      case RoutineTileType.editable:
        return _buildEditAction(context);
    }
  }

  Widget _buildDailyAction(BuildContext context) {
    return routine.isCompleted
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check,
                color: Theme.of(context).textTheme.bodyLarge!.hint(context).color,
                size: 24,
              ),
              const SizedBox(width: 4),
              Text(
                'Completed',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          )
        : OutlinedButton(
            onPressed: onToggleComplete,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            child: Text(
              'Mark as Done',
              style: Theme.of(context).textTheme.bodyLarge!.hint(context),
            ),
          );
  }

  Widget _buildSelectionAction(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Image.asset(
          'assets/icons/add_icon.png',
          color: Theme.of(context).textTheme.bodyLarge!.hint(context).color,
        ),
      ),
    );
  }

  Widget _buildEditAction(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onDelete,
      child: Container(
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: colorScheme.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Image.asset(
          'assets/icons/delete_icon.png',
          width: 20,
          height: 20,
        ),
      ),
    );
  }
}