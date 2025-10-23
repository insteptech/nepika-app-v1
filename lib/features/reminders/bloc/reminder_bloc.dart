import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/reminders/usecases/add_reminder.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/utils/app_logger.dart';
import 'reminder_event.dart';
import 'reminder_state.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final AddReminder addReminderUseCase;
  final LocalNotificationService localNotificationService;

  ReminderBloc({
    required this.addReminderUseCase,
    required this.localNotificationService,
  }) : super(ReminderInitial()) {
    on<AddReminderEvent>(_onAddReminder);
  }

  Future<void> _onAddReminder(
    AddReminderEvent event,
    Emitter<ReminderState> emit,
  ) async {
    emit(ReminderLoading());
    try {
      // First save the reminder to the backend
      final reminder = await addReminderUseCase(
        reminderName: event.reminderName,
        reminderTime: event.reminderTime,
        reminderDays: event.reminderDays,
        reminderType: event.reminderType,
        reminderEnabled: event.reminderEnabled,
      );

      // Then schedule the local notification
      if (reminder.reminderEnabled) {
        AppLogger.info('Scheduling notification for reminder: ${reminder.reminderName}', tag: 'ReminderBloc');
        
        final bool notificationScheduled = await localNotificationService.scheduleReminder(
          reminderId: reminder.id,
          reminderName: reminder.reminderName,
          time24Hour: reminder.reminderTime,
          reminderDays: reminder.reminderDays ?? 'Daily',
          reminderType: reminder.reminderType ?? 'Morning Routine',
          isEnabled: reminder.reminderEnabled,
        );

        if (notificationScheduled) {
          AppLogger.success('Notification scheduled successfully for reminder: ${reminder.reminderName}', tag: 'ReminderBloc');
        } else {
          AppLogger.warning('Failed to schedule notification for reminder: ${reminder.reminderName}', tag: 'ReminderBloc');
        }
      } else {
        AppLogger.info('Reminder is disabled, skipping notification scheduling', tag: 'ReminderBloc');
      }

      emit(ReminderAdded(reminder));
    } catch (e) {
      AppLogger.error('Failed to add reminder and schedule notification', tag: 'ReminderBloc', error: e);
      emit(ReminderError(e.toString()));
    }
  }
}