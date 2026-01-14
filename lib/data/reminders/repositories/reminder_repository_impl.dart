import '../../../domain/reminders/entities/reminder.dart';
import '../../../domain/reminders/entities/paginated_reminders.dart';
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
  Future<PaginatedReminders> getAllReminders({int page = 1, int pageSize = 20}) async {
    return await remoteDataSource.getAllReminders(page: page, pageSize: pageSize);
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
  Future<Reminder> updateReminder({
    required String reminderId,
    String? reminderName,
    String? reminderTime,
    String? reminderDays,
    String? reminderType,
    bool? reminderEnabled,
  }) async {
    return await remoteDataSource.updateReminder(
      reminderId: reminderId,
      reminderName: reminderName,
      reminderTime: reminderTime,
      reminderDays: reminderDays,
      reminderType: reminderType,
      reminderEnabled: reminderEnabled,
    );
  }

  @override
  Future<void> deleteReminder(String reminderId) async {
    return await remoteDataSource.deleteReminder(reminderId);
  }
}