import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nepika/core/config/constants/routes.dart';
import 'package:nepika/core/config/constants/theme.dart';
import 'package:nepika/core/di/injection_container.dart';
import 'package:nepika/core/widgets/back_button.dart';
import 'package:nepika/domain/reminders/entities/reminder.dart';
import 'package:nepika/features/reminders/bloc/reminder_bloc.dart';
import 'package:nepika/features/reminders/bloc/reminder_event.dart';
import 'package:nepika/features/reminders/bloc/reminder_state.dart';
import 'package:nepika/features/routine/widgets/sticky_header_delegate.dart';

class ScheduledRemindersScreen extends StatefulWidget {
  const ScheduledRemindersScreen({super.key});

  @override
  State<ScheduledRemindersScreen> createState() =>
      _ScheduledRemindersScreenState();
}

class _ScheduledRemindersScreenState extends State<ScheduledRemindersScreen> {
  late ReminderBloc _reminderBloc;
  List<Reminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _reminderBloc = sl<ReminderBloc>();
    _reminderBloc.add(GetAllRemindersEvent());
  }

  @override
  void dispose() {
    _reminderBloc.close();
    super.dispose();
  }

  String _formatTime(String time24Hour) {
    try {
      final parts = time24Hour.split(':');
      if (parts.length < 2) return time24Hour;

      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';

      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;

      return '$hour:$minute $period';
    } catch (e) {
      return time24Hour;
    }
  }

  IconData _getRoutineIcon(String? routineType) {
    if (routineType == null) return Icons.notifications_outlined;
    if (routineType.toLowerCase().contains('morning')) {
      return Icons.wb_sunny_outlined;
    } else if (routineType.toLowerCase().contains('night')) {
      return Icons.nightlight_outlined;
    }
    return Icons.notifications_outlined;
  }

  Color _getRoutineColor(String? routineType, BuildContext context) {
    if (routineType == null) return Theme.of(context).colorScheme.primary;
    if (routineType.toLowerCase().contains('morning')) {
      return const Color(0xFFFF9800); // Orange for morning
    } else if (routineType.toLowerCase().contains('night')) {
      return const Color(0xFF5C6BC0); // Indigo for night
    }
    return Theme.of(context).colorScheme.primary;
  }

  /// Convert time string to minutes since midnight for sorting (AM -> PM)
  int _timeToMinutes(String time24Hour) {
    try {
      final parts = time24Hour.split(':');
      if (parts.length < 2) return 0;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour * 60 + minute;
    } catch (e) {
      return 0;
    }
  }

  /// Sort reminders by time (AM -> PM)
  List<Reminder> _sortRemindersByTime(List<Reminder> reminders) {
    final sorted = List<Reminder>.from(reminders);
    sorted.sort((a, b) => _timeToMinutes(a.reminderTime).compareTo(_timeToMinutes(b.reminderTime)));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _reminderBloc,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: BlocConsumer<ReminderBloc, ReminderState>(
            listener: (context, state) {
              if (state is RemindersLoaded) {
                setState(() {
                  _reminders = _sortRemindersByTime(state.reminders);
                });
              } else if (state is ReminderStatusToggled) {
                // Update the reminder in the list without re-fetching to maintain order
                setState(() {
                  final index = _reminders.indexWhere((r) => r.id == state.reminder.id);
                  if (index != -1) {
                    _reminders[index] = state.reminder;
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.reminder.reminderEnabled
                          ? 'Reminder enabled'
                          : 'Reminder disabled',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else if (state is ReminderError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${state.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is ReminderLoading && _reminders.isEmpty;

              return CustomScrollView(
                slivers: [
                  // Static top content (back button + Add button)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20, right: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const CustomBackButton(),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.dashboardReminderSettings,
                                  );
                                },
                                icon: Icon(
                                  Icons.add,
                                  color: theme.colorScheme.primary,
                                ),
                                label: Text(
                                  'Add',
                                  style: TextStyle(
                                    fontSize:
                                        theme.textTheme.headlineMedium?.fontSize,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),

                  // Sticky header with animated back button
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: StickyHeaderDelegate(
                      minHeight: 40,
                      maxHeight: 40,
                      isFirstHeader: true,
                      title: "Scheduled Reminders",
                      child: Container(
                        color: theme.scaffoldBackgroundColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Scheduled Reminders",
                          style: theme.textTheme.displaySmall,
                        ),
                      ),
                    ),
                  ),

                  // Subtitle
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Manage your skincare routine reminders',
                            style: theme.textTheme.headlineMedium!.secondary(
                              context,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  if (isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_reminders.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(context),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final reminder = _reminders[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index < _reminders.length - 1 ? 12 : 20,
                              ),
                              child: _ReminderCard(
                                reminder: reminder,
                                formattedTime:
                                    _formatTime(reminder.reminderTime),
                                icon: _getRoutineIcon(reminder.reminderType),
                                iconColor: _getRoutineColor(
                                    reminder.reminderType, context),
                                onToggle: (value) {
                                  _reminderBloc.add(
                                    ToggleReminderStatusEvent(reminder.id),
                                  );
                                },
                              ),
                            );
                          },
                          childCount: _reminders.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Reminders Yet',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Set up reminders to stay consistent with your skincare routine',
              style: theme.textTheme.bodyMedium?.secondary(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.dashboardReminderSettings,
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Reminder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final String formattedTime;
  final IconData icon;
  final Color iconColor;
  final ValueChanged<bool> onToggle;

  const _ReminderCard({
    required this.reminder,
    required this.formattedTime,
    required this.icon,
    required this.iconColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Reminder details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.reminderName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedTime,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      reminder.reminderDays ?? 'Daily',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                if (reminder.reminderType != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      reminder.reminderType!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: iconColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Toggle switch
          Switch.adaptive(
            value: reminder.reminderEnabled,
            onChanged: onToggle,
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
