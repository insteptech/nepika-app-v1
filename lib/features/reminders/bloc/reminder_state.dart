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

class ReminderUpdated extends ReminderState {
  final Reminder reminder;

  const ReminderUpdated(this.reminder);

  @override
  List<Object> get props => [reminder];
}

class RemindersLoaded extends ReminderState {
  final List<Reminder> reminders;
  final bool hasReachedMax;
  final int currentPage;

  const RemindersLoaded({
    this.reminders = const [],
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  RemindersLoaded copyWith({
    List<Reminder>? reminders,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return RemindersLoaded(
      reminders: reminders ?? this.reminders,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object> get props => [reminders, hasReachedMax, currentPage];
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

class ReminderDeleted extends ReminderState {
  final String reminderId;

  const ReminderDeleted(this.reminderId);

  @override
  List<Object> get props => [reminderId];
}