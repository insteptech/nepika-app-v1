import '../../../domain/reminders/entities/paginated_reminders.dart';
import 'reminder_model.dart';

class PaginatedRemindersModel extends PaginatedReminders {
  const PaginatedRemindersModel({
    required super.reminders,
    required super.total,
    required super.page,
    required super.pageSize,
    required super.hasMore,
  });

  factory PaginatedRemindersModel.fromJson(Map<String, dynamic> json) {
    return PaginatedRemindersModel(
      reminders: (json['reminders'] as List)
          .map((e) => ReminderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}
