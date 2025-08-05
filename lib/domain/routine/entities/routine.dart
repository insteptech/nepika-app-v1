class Routine {
  final String id;
  final String name;
  final String timing; // 'morning' or 'night'
  final bool isCompleted;
  final String? description;
  final DateTime? reminderTime;

  const Routine({
    required this.id,
    required this.name,
    required this.timing,
    required this.isCompleted,
    this.description,
    this.reminderTime,
  });
}
