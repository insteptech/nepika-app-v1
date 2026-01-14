import 'reminder.dart';

class PaginatedReminders {
  final List<Reminder> reminders;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  const PaginatedReminders({
    required this.reminders,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });
}
