import 'package:flutter/material.dart';
import '../../../../core/config/constants/theme.dart';

class RoutineEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onActionTap;

  const RoutineEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium!.secondary(context),
            textAlign: TextAlign.center,
          ),
          if (actionText != null && onActionTap != null) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionText!,
                maxLines: 1,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.hint(context)
                    .copyWith(
                      decoration: TextDecoration.combine([
                        TextDecoration.underline,
                      ]),
                      decorationColor: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class NoRoutinesFound extends StatelessWidget {
  final VoidCallback? onAddRoutines;

  const NoRoutinesFound({
    super.key,
    this.onAddRoutines,
  });

  @override
  Widget build(BuildContext context) {
    return RoutineEmptyState(
      title: 'No routines found',
      subtitle: 'Please add routines to your daily schedule',
      icon: Icons.event_note,
      actionText: onAddRoutines != null ? 'Add routines →' : null,
      onActionTap: onAddRoutines,
    );
  }
}

class NoRoutinesAvailable extends StatelessWidget {
  final VoidCallback? onRefresh;

  const NoRoutinesAvailable({
    super.key,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RoutineEmptyState(
      title: 'No routine steps found',
      subtitle: 'There are no available routine steps at this time',
      icon: Icons.pending_actions,
      actionText: onRefresh != null ? 'Refresh' : null,
      onActionTap: onRefresh,
    );
  }
}

class RoutineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const RoutineErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}