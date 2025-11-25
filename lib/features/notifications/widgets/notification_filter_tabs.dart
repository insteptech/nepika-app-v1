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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

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
                  child:IntrinsicHeight(
                    child: Container(
                    // padding: EdgeInsets.symmetric(
                    //   horizontal: isSmallScreen ? 12 : 16,
                    //   vertical: isSmallScreen ? 6 : 8,
                    // ),
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
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 6 : 8,
                      ),
                      child: Text(
                        filter.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onTertiary
                              : theme.textTheme.bodyMedium?.color,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
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