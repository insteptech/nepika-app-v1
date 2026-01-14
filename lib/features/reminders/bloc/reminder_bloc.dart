import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/reminders/usecases/add_reminder.dart';
import '../../../domain/reminders/repositories/reminder_repository.dart';
import '../../../domain/reminders/entities/reminder.dart';
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
    on<UpdateReminderEvent>(_onUpdateReminder);
  }

  Future<void> _onGetAllReminders(
    GetAllRemindersEvent event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      // If forcing refresh, reset to initial state for loading
      bool isRefreshing = event.forceRefresh;
      
      if (!isRefreshing && state is RemindersLoaded && (state as RemindersLoaded).hasReachedMax) return;

      final currentState = state;
      var currentReminders = <Reminder>[];
      var nextPage = 1;

      if (!isRefreshing && currentState is RemindersLoaded) {
        currentReminders = currentState.reminders;
        nextPage = currentState.currentPage + 1;
      } else {
        emit(ReminderLoading());
      }

      AppLogger.info('=== ReminderBloc: Fetching Reminders (Page $nextPage, Refresh: $isRefreshing) ===', tag: 'ReminderBloc');
      final paginatedReminders = await reminderRepository.getAllReminders(page: nextPage);
      
      final newReminders = paginatedReminders.reminders;
      final hasMore = paginatedReminders.hasMore;

      AppLogger.info('Fetched ${newReminders.length} reminders', tag: 'ReminderBloc');
      
      if (!isRefreshing && currentState is RemindersLoaded) {
        final currentIds = currentState.reminders.map((e) => e.id).toSet();
        final uniqueNewReminders = newReminders.where((r) => !currentIds.contains(r.id)).toList();

        emit(currentState.copyWith(
          reminders: List.of(currentState.reminders)..addAll(uniqueNewReminders),
          hasReachedMax: !hasMore,
          currentPage: nextPage,
        ));
        
        final allReminders = List<Reminder>.from(currentState.reminders)..addAll(uniqueNewReminders);

        if (!hasMore) {
          // Full sync: Clear all local schedule and rebuild from complete list
          await localNotificationService.cancelAllReminders();
          for (final reminder in allReminders) {
            if (reminder.reminderEnabled) {
              await localNotificationService.scheduleReminder(
                reminderId: reminder.id,
                reminderName: reminder.reminderName,
                time24Hour: reminder.reminderTime,
                reminderDays: reminder.reminderDays ?? 'Daily',
                reminderType: reminder.reminderType ?? 'Morning Routine',
                isEnabled: true,
              );
            }
          }
        } else {
           // Partial sync: Just add/update newly fetched ones
           for (final reminder in uniqueNewReminders) {
            if (reminder.reminderEnabled) {
              await localNotificationService.scheduleReminder(
                reminderId: reminder.id,
                reminderName: reminder.reminderName,
                time24Hour: reminder.reminderTime,
                reminderDays: reminder.reminderDays ?? 'Daily',
                reminderType: reminder.reminderType ?? 'Morning Routine',
                isEnabled: true,
              );
            } else {
              await localNotificationService.cancelReminder(reminder.id);
            }
          }
        }
      } else {
        emit(RemindersLoaded(
          reminders: newReminders,
          hasReachedMax: !hasMore,
          currentPage: nextPage,
        ));
        
        if (!hasMore) {
          // Full sync: Clear all local schedule and rebuild from complete list
          await localNotificationService.cancelAllReminders();
          for (final reminder in newReminders) {
            if (reminder.reminderEnabled) {
              await localNotificationService.scheduleReminder(
                reminderId: reminder.id,
                reminderName: reminder.reminderName,
                time24Hour: reminder.reminderTime,
                reminderDays: reminder.reminderDays ?? 'Daily',
                reminderType: reminder.reminderType ?? 'Morning Routine',
                isEnabled: true,
              );
            }
          }
        } else {
           // Partial sync (Page 1 but has more pages? Rare but possible)
           for (final reminder in newReminders) {
            if (reminder.reminderEnabled) {
              await localNotificationService.scheduleReminder(
                reminderId: reminder.id,
                reminderName: reminder.reminderName,
                time24Hour: reminder.reminderTime,
                reminderDays: reminder.reminderDays ?? 'Daily',
                reminderType: reminder.reminderType ?? 'Morning Routine',
                isEnabled: true,
              );
            } else {
              await localNotificationService.cancelReminder(reminder.id);
            }
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch reminders', tag: 'ReminderBloc', error: e, stackTrace: stackTrace);
      emit(ReminderError(e.toString()));
    }
  }

  Future<void> _onToggleReminderStatus(
    ToggleReminderStatusEvent event,
    Emitter<ReminderState> emit,
  ) async {
    // Keep current reminders to optimistically update or restore on error
    final currentState = state;
    List<Reminder> currentReminders = [];
    if (currentState is RemindersLoaded) {
      currentReminders = currentState.reminders;
    }
    
    // Don't emit loading for toggle to avoid flickering, update list locally first if possible or just wait
    // Actually, original code emitted loading. Let's try to keep it smooth.
    // Ideally we would update the specific item in the list and emit Loaded immediately, then revert if failed.
    // For now, sticking to pattern but preserving list if loaded.

    // emit(ReminderLoading()); // Removing full screen loading for toggle
    
    try {
      AppLogger.info('=== ReminderBloc: Toggling Reminder Status ===', tag: 'ReminderBloc');
      
      final updatedReminder = await reminderRepository.toggleReminderStatus(event.reminderId);

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
      } else {
        await localNotificationService.cancelReminder(updatedReminder.id);
      }

      emit(ReminderStatusToggled(updatedReminder));
      
      // Also update the list state if applicable
      if (currentState is RemindersLoaded) {
         final updatedList = currentState.reminders.map((r) => r.id == updatedReminder.id ? updatedReminder : r).toList();
         emit(currentState.copyWith(reminders: updatedList));
      }
      
    } catch (e, stackTrace) {
      AppLogger.error('Failed to toggle reminder status', tag: 'ReminderBloc', error: e, stackTrace: stackTrace);
      emit(ReminderError(e.toString()));
      // Restore previous state if it was loaded
      if (currentState is RemindersLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onDeleteReminder(
    DeleteReminderEvent event,
    Emitter<ReminderState> emit,
  ) async {
    final currentState = state;
    emit(ReminderLoading());
    try {
      AppLogger.info('=== ReminderBloc: Deleting Reminder ===', tag: 'ReminderBloc');
      
      // 1. Delete from backend
      await reminderRepository.deleteReminder(event.reminderId);
      
      // 2. Cancel local notification
      await localNotificationService.cancelReminder(event.reminderId);
      
      AppLogger.success('Reminder deleted: ${event.reminderId}', tag: 'ReminderBloc');

      emit(ReminderDeleted(event.reminderId));
      
      // Update list state
      if (currentState is RemindersLoaded) {
        final updatedList = currentState.reminders.where((r) => r.id != event.reminderId).toList();
        emit(currentState.copyWith(reminders: updatedList));
      } else {
        // Refresh list if we don't have it (e.g. was deleted from detail view?)
        add(GetAllRemindersEvent()); 
      }
      
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete reminder', tag: 'ReminderBloc', error: e, stackTrace: stackTrace);
      emit(ReminderError(e.toString()));
       if (currentState is RemindersLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onAddReminder(
    AddReminderEvent event,
    Emitter<ReminderState> emit,
  ) async {
     final currentState = state;
     emit(ReminderLoading());
    try {
      AppLogger.info('=== ReminderBloc: Adding Reminder ===', tag: 'ReminderBloc');
     
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
        await localNotificationService.scheduleReminder(
          reminderId: reminder.id,
          reminderName: reminder.reminderName,
          time24Hour: reminder.reminderTime,
          reminderDays: reminder.reminderDays ?? 'Daily',
          reminderType: reminder.reminderType ?? 'Morning Routine',
          isEnabled: reminder.reminderEnabled,
        );
      }

      emit(ReminderAdded(reminder));
      
      // Refresh list
      add(GetAllRemindersEvent());
      
    } catch (e, stackTrace) {
      AppLogger.error('Failed to add reminder', tag: 'ReminderBloc', error: e, stackTrace: stackTrace);
      emit(ReminderError(e.toString()));
       if (currentState is RemindersLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onUpdateReminder(
    UpdateReminderEvent event,
    Emitter<ReminderState> emit,
  ) async {
    final currentState = state;
    emit(ReminderLoading());
    try {
      AppLogger.info('=== ReminderBloc: Updating Reminder ===', tag: 'ReminderBloc');
      
      // 1. Update backend
      final reminder = await reminderRepository.updateReminder(
         reminderId: event.oldReminderId,
         reminderName: event.reminderName,
         reminderTime: event.reminderTime,
         reminderDays: event.reminderDays,
         reminderType: event.reminderType,
         reminderEnabled: event.reminderEnabled,
      );

      // 2. Reschedule notification
      await localNotificationService.cancelReminder(reminder.id);
      if (reminder.reminderEnabled) {
        await localNotificationService.scheduleReminder(
          reminderId: reminder.id,
          reminderName: reminder.reminderName,
          time24Hour: reminder.reminderTime,
          reminderDays: reminder.reminderDays ?? 'Daily',
          reminderType: reminder.reminderType ?? 'Morning Routine',
          isEnabled: reminder.reminderEnabled,
        );
      }

      AppLogger.success('=== ReminderBloc: Update Complete ===', tag: 'ReminderBloc');
      emit(ReminderUpdated(reminder));
      
      // Update list directly if loaded
       if (currentState is RemindersLoaded) {
         final updatedList = currentState.reminders.map((r) => r.id == reminder.id ? reminder : r).toList();
         emit(currentState.copyWith(reminders: updatedList));
      } else {
        add(GetAllRemindersEvent());
      }
      
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update reminder', tag: 'ReminderBloc', error: e, stackTrace: stackTrace);
      emit(ReminderError(e.toString()));
      if (currentState is RemindersLoaded) {
        emit(currentState);
      }
    }
  }
}