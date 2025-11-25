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
      AppLogger.info('=== ReminderBloc: Adding Reminder ===', tag: 'ReminderBloc');
      AppLogger.info('Event Data:', tag: 'ReminderBloc');
      AppLogger.info('  - Name: ${event.reminderName}', tag: 'ReminderBloc');
      AppLogger.info('  - Time: ${event.reminderTime}', tag: 'ReminderBloc');
      AppLogger.info('  - Days: ${event.reminderDays}', tag: 'ReminderBloc');
      AppLogger.info('  - Type: ${event.reminderType}', tag: 'ReminderBloc');
      AppLogger.info('  - Enabled: ${event.reminderEnabled}', tag: 'ReminderBloc');

      // First save the reminder to the backend
      AppLogger.info('Calling addReminderUseCase...', tag: 'ReminderBloc');
      final reminder = await addReminderUseCase(
        reminderName: event.reminderName,
        reminderTime: event.reminderTime,
        reminderDays: event.reminderDays,
        reminderType: event.reminderType,
        reminderEnabled: event.reminderEnabled,
      );

      AppLogger.info('Reminder saved to backend:', tag: 'ReminderBloc');
      AppLogger.info('  - ID: ${reminder.id}', tag: 'ReminderBloc');
      AppLogger.info('  - Name: ${reminder.reminderName}', tag: 'ReminderBloc');
      AppLogger.info('  - Time: ${reminder.reminderTime}', tag: 'ReminderBloc');
      AppLogger.info('  - Days: ${reminder.reminderDays}', tag: 'ReminderBloc');
      AppLogger.info('  - Type: ${reminder.reminderType}', tag: 'ReminderBloc');
      AppLogger.info('  - Enabled: ${reminder.reminderEnabled}', tag: 'ReminderBloc');

      // Then schedule the local notification
      if (reminder.reminderEnabled) {
        AppLogger.info('Scheduling notification for reminder: ${reminder.reminderName}', tag: 'ReminderBloc');
        AppLogger.info('Scheduling parameters:', tag: 'ReminderBloc');
        AppLogger.info('  - reminderId: ${reminder.id}', tag: 'ReminderBloc');
        AppLogger.info('  - reminderName: ${reminder.reminderName}', tag: 'ReminderBloc');
        AppLogger.info('  - time24Hour: ${reminder.reminderTime}', tag: 'ReminderBloc');
        AppLogger.info('  - reminderDays: ${reminder.reminderDays ?? 'Daily'}', tag: 'ReminderBloc');
        AppLogger.info('  - reminderType: ${reminder.reminderType ?? 'Morning Routine'}', tag: 'ReminderBloc');
        AppLogger.info('  - isEnabled: ${reminder.reminderEnabled}', tag: 'ReminderBloc');

        final bool notificationScheduled = await localNotificationService.scheduleReminder(
          reminderId: reminder.id,
          reminderName: reminder.reminderName,
          time24Hour: reminder.reminderTime,
          reminderDays: reminder.reminderDays ?? 'Daily',
          reminderType: reminder.reminderType ?? 'Morning Routine',
          isEnabled: reminder.reminderEnabled,
        );

        if (notificationScheduled) {
          AppLogger.success('✅ Notification scheduled successfully for reminder: ${reminder.reminderName}', tag: 'ReminderBloc');
        } else {
          AppLogger.warning('⚠️ Failed to schedule notification for reminder: ${reminder.reminderName}', tag: 'ReminderBloc');
        }
      } else {
        AppLogger.info('Reminder is disabled, skipping notification scheduling', tag: 'ReminderBloc');
      }

      AppLogger.success('=== ReminderBloc: Completed Successfully ===', tag: 'ReminderBloc');
      emit(ReminderAdded(reminder));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to add reminder and schedule notification', tag: 'ReminderBloc', error: e, stackTrace: stackTrace);
      emit(ReminderError(e.toString()));
    }
  }
}