import 'package:equatable/equatable.dart';

abstract class ReminderEvent extends Equatable {
  const ReminderEvent();

  @override
  List<Object?> get props => [];
}

class AddReminderEvent extends ReminderEvent {
  final String reminderName;
  final String reminderTime;
  final String? reminderDays;
  final String? reminderType;
  final bool reminderEnabled;

  const AddReminderEvent({
    required this.reminderName,
    required this.reminderTime,
    this.reminderDays,
    this.reminderType,
    this.reminderEnabled = true,
  });

  @override
  List<Object?> get props => [
        reminderName,
        reminderTime,
        reminderDays,
        reminderType,
        reminderEnabled,
      ];
}

class GetAllRemindersEvent extends ReminderEvent {}

class GetReminderByIdEvent extends ReminderEvent {
  final String reminderId;

  const GetReminderByIdEvent(this.reminderId);

  @override
  List<Object> get props => [reminderId];
}

class ToggleReminderStatusEvent extends ReminderEvent {
  final String reminderId;

  const ToggleReminderStatusEvent(this.reminderId);

  @override
  List<Object> get props => [reminderId];
}