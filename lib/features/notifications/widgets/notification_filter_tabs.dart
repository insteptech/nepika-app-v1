import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_state.dart';
import '../bloc/notification_event.dart';
import '../../../domain/notifications/entities/notification_entities.dart';

class NotificationFilterTabs extends StatelessWidget {
  const NotificationFilterTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        NotificationFilter currentFilter = NotificationFilter.all;
        
        if (state is NotificationLoaded) {
          currentFilter = state.currentFilter;
        } else if (state is NotificationError) {
          currentFilter = state.currentFilter;
        } else if (state is NotificationConnecting) {
          currentFilter = state.currentFilter;
        } else if (state is NotificationDisconnected) {
          currentFilter = state.currentFilter;
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: NotificationFilter.values.map((filter) {
              final isSelected = filter == currentFilter;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    context.read<NotificationBloc>().add(
                      ChangeNotificationFilter(filter),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.dividerColor.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      filter.displayName,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : theme.textTheme.bodyLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}