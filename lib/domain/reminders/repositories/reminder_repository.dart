import '../entities/reminder.dart';

abstract class ReminderRepository {
  Future<Reminder> addReminder({
    required String reminderName,
    required String reminderTime,
    String? reminderDays,
    String? reminderType,
    bool reminderEnabled = true,
  });

  Future<List<Reminder>> getAllReminders();

  Future<Reminder> getReminderById(String reminderId);

  Future<Reminder> toggleReminderStatus(String reminderId);
}