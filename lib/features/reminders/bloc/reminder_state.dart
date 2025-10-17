import 'package:equatable/equatable.dart';
import '../../../domain/reminders/entities/reminder.dart';

abstract class ReminderState extends Equatable {
  const ReminderState();

  @override
  List<Object?> get props => [];
}

class ReminderInitial extends ReminderState {}

class ReminderLoading extends ReminderState {}

class ReminderAdded extends ReminderState {
  final Reminder reminder;

  const ReminderAdded(this.reminder);

  @override
  List<Object> get props => [reminder];
}

class RemindersLoaded extends ReminderState {
  final List<Reminder> reminders;

  const RemindersLoaded(this.reminders);

  @override
  List<Object> get props => [reminders];
}

class ReminderLoaded extends ReminderState {
  final Reminder reminder;

  const ReminderLoaded(this.reminder);

  @override
  List<Object> get props => [reminder];
}

class ReminderStatusToggled extends ReminderState {
  final Reminder reminder;

  const ReminderStatusToggled(this.reminder);

  @override
  List<Object> get props => [reminder];
}

class ReminderError extends ReminderState {
  final String message;

  const ReminderError(this.message);

  @override
  List<Object> get props => [message];
}