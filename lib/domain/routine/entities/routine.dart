// lib/domain/routine/entities/routine.dart
class Routine {
  final String id;
  final String name;
  final String timing;
  final bool isCompleted;
  final String routineIcon;
  final String description;

  Routine({
    required this.id,
    required this.name,
    required this.timing,
    required this.isCompleted,
    required this.routineIcon,
    required this.description,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'] ?? '',
      name: json['title'] ?? '',
      timing: json['timing'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      routineIcon: json['routine_icon'],
      description: json['description'] ?? '',
    );
  }
}