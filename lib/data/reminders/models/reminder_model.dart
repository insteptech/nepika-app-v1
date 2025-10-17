import '../../../domain/reminders/entities/reminder.dart';

class ReminderModel extends Reminder {
  const ReminderModel({
    required super.id,
    required super.userId,
    required super.reminderName,
    required super.reminderTime,
    super.reminderDays,
    super.reminderType,
    required super.reminderEnabled,
    required super.createdAt,
    super.updatedAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'],
      userId: json['user_id'],
      reminderName: json['reminder_name'],
      reminderTime: json['reminder_time'],
      reminderDays: json['reminder_days'],
      reminderType: json['reminder_type'],
      reminderEnabled: json['reminder_enabled'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reminder_name': reminderName,
      'reminder_time': reminderTime,
      'reminder_days': reminderDays,
      'reminder_type': reminderType,
      'reminder_enabled': reminderEnabled,
    };
  }
}