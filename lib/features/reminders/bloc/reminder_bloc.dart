import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/reminders/usecases/add_reminder.dart';
import 'reminder_event.dart';
import 'reminder_state.dart';

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final AddReminder addReminderUseCase;

  ReminderBloc({
    required this.addReminderUseCase,
  }) : super(ReminderInitial()) {
    on<AddReminderEvent>(_onAddReminder);
  }

  Future<void> _onAddReminder(
    AddReminderEvent event,
    Emitter<ReminderState> emit,
  ) async {
    emit(ReminderLoading());
    try {
      final reminder = await addReminderUseCase(
        reminderName: event.reminderName,
        reminderTime: event.reminderTime,
        reminderDays: event.reminderDays,
        reminderType: event.reminderType,
        reminderEnabled: event.reminderEnabled,
      );
      emit(ReminderAdded(reminder));
    } catch (e) {
      emit(ReminderError(e.toString()));
    }
  }
}