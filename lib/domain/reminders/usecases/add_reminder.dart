import '../entities/reminder.dart';
import '../repositories/reminder_repository.dart';

class AddReminder {
  final ReminderRepository repository;

  AddReminder(this.repository);

  Future<Reminder> call({
    required String reminderName,
    required String reminderTime,
    String? reminderDays,
    String? reminderType,
    bool reminderEnabled = true,
  }) async {
    return await repository.addReminder(
      reminderName: reminderName,
      reminderTime: reminderTime,
      reminderDays: reminderDays,
      reminderType: reminderType,
      reminderEnabled: reminderEnabled,
    );
  }
}