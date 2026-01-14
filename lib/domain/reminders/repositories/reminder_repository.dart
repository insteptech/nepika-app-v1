import '../entities/reminder.dart';
import '../entities/paginated_reminders.dart';

abstract class ReminderRepository {
  Future<Reminder> addReminder({
    required String reminderName,
    required String reminderTime,
    String? reminderDays,
    String? reminderType,
    bool reminderEnabled = true,
  });

  Future<PaginatedReminders> getAllReminders({int page = 1, int pageSize = 20});

  Future<Reminder> getReminderById(String reminderId);

  Future<Reminder> toggleReminderStatus(String reminderId);

  Future<Reminder> updateReminder({
    required String reminderId,
    String? reminderName,
    String? reminderTime,
    String? reminderDays,
    String? reminderType,
    bool? reminderEnabled,
  });

  Future<void> deleteReminder(String reminderId);
}