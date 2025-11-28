import '../../../domain/reminders/entities/reminder.dart';
import '../../../domain/reminders/repositories/reminder_repository.dart';
import '../datasources/reminder_remote_data_source.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final ReminderRemoteDataSource remoteDataSource;

  ReminderRepositoryImpl(this.remoteDataSource);

  @override
  Future<Reminder> addReminder({
    required String reminderName,
    required String reminderTime,
    String? reminderDays,
    String? reminderType,
    bool reminderEnabled = true,
  }) async {
    return await remoteDataSource.addReminder(
      reminderName: reminderName,
      reminderTime: reminderTime,
      reminderDays: reminderDays,
      reminderType: reminderType,
      reminderEnabled: reminderEnabled,
    );
  }

  @override
  Future<List<Reminder>> getAllReminders() async {
    return await remoteDataSource.getAllReminders();
  }

  @override
  Future<Reminder> getReminderById(String reminderId) async {
    return await remoteDataSource.getReminderById(reminderId);
  }

  @override
  Future<Reminder> toggleReminderStatus(String reminderId) async {
    return await remoteDataSource.toggleReminderStatus(reminderId);
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    return await remoteDataSource.deleteReminder(reminderId);
  }
}