import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/reminders/usecases/add_reminder.dart';
import '../../../domain/reminders/repositories/reminder_repository.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/utils/app_logger.dart';
import 'reminder_event.dart';
import 'reminder_state.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final AddReminder addReminderUseCase;
  final ReminderRepository reminderRepository;
  final LocalNotificationService localNotificationService;

  ReminderBloc({
    required this.addReminderUseCase,
    required this.reminderRepository,
    required this.localNotificationService,
  }) : super(ReminderInitial()) {
    on<AddReminderEvent>(_onAddReminder);
    on<GetAllRemindersEvent>(_onGetAllReminders);
    on<ToggleReminderStatusEvent>(_onToggleReminderStatus);
    on<DeleteReminderEvent>(_onDeleteReminder);
  }

  Future<void> _onGetAllReminders(
    GetAllRemindersEvent event,
    Emitter<ReminderState> emit,
  ) async {
    emit(ReminderLoading());
    try {
      AppLogger.info('=== ReminderBloc: Fetching All Reminders ===', tag: 'ReminderBloc');
      final reminders = await reminderRepository.getAllReminders();
      AppLogger.info('Fetched ${reminders.length} reminders', tag: 'ReminderBloc');
      emit(RemindersLoaded(reminders));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch reminders', tag: 'ReminderBloc', error: e, stackTrace: stackTrace);
      emit(ReminderError(e.toString()));
    }
  }

  Future<void> _onToggleReminderStatus(
    ToggleReminderStatusEvent event,
    Emitter<ReminderState> emit,
  ) async {
    emit(ReminderLoading());
    try {
      AppLogger.info('=== ReminderBloc: Toggling Reminder Status ===', tag: 'ReminderBloc');
      AppLogger.info('Reminder ID: ${event.reminderId}', tag: 'ReminderBloc');

      final updatedReminder = await reminderRepository.toggleReminderStatus(event.reminderId);

      AppLogger.info('Reminder status toggled:', tag: 'ReminderBloc');
      AppLogger.info('  - ID: ${updatedReminder.id}', tag: 'ReminderBloc');
      AppLogger.info('  - Enabled: ${updatedReminder.reminderEnabled}', tag: 'ReminderBloc');

      // Update local notification based on new status
      if (updatedReminder.reminderEnabled) {
        await localNotificationService.scheduleReminder(
          reminderId: updatedReminder.id,
          reminderName: updatedReminder.reminderName,
          time24Hour: updatedReminder.reminderTime,
          reminderDays: updatedReminder.reminderDays ?? 'Daily',
          reminderType: updatedReminder.reminderType ?? 'Morning Routine',
          isEnabled: true,
        );
        AppLogger.success('Notification scheduled for reminder: ${updatedReminder.reminderName}', tag: 'ReminderBloc');
      } else {
        await localNotificationService.cancelReminder(updatedReminder.id);
        AppLogger.info('Notification cancelled for reminder: ${updatedReminder.reminderName}', tag: 'ReminderBloc');
      }

      emit(ReminderStatusToggled(updatedReminder));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to toggle reminder status', tag: 'ReminderBloc', error: e, stackTrace: stackTrace);
      emit(ReminderError(e.toString()));
    }
  }

  Future<void> _onDeleteReminder(
    DeleteReminderEvent event,
    Emitter<ReminderState> emit,
  ) async {
    emit(ReminderLoading());
    try {
      AppLogger.info('=== ReminderBloc: Deleting Local Reminder Notification ===', tag: 'ReminderBloc');
      AppLogger.info('Reminder ID: ${event.reminderId}', tag: 'ReminderBloc');

      // Only cancel local notification (no backend delete endpoint available)
      await localNotificationService.cancelReminder(event.reminderId);
      AppLogger.success('Local notification cancelled for reminder: ${event.reminderId}', tag: 'ReminderBloc');

      emit(ReminderDeleted(event.reminderId));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cancel local reminder notification', tag: 'ReminderBloc', error: e, stackTrace: stackTrace);
      emit(ReminderError(e.toString()));
    }
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