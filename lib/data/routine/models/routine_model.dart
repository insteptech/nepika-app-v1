import '../../../domain/routine/entities/routine.dart';

class RoutineModel {
  final String id;
  final String name;
  final String timing;
  final bool isCompleted;
  final String routineIcon;
  final String? description;
  final DateTime? reminderTime;

  RoutineModel({
    required this.id,
    required this.name,
    required this.timing,
    required this.isCompleted,
    required this.routineIcon,
    this.description,
    this.reminderTime,
  });

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    // Ensure we have required fields
    final id = json['id']?.toString() ?? '';
    final name = json['title'] ?? json['name'] ?? 'Untitled Routine';
    final timing = json['timing'] ?? 'morning';
    
    return RoutineModel(
      id: id,
      name: name,
      timing: timing,
      isCompleted: json['is_completed'] ?? false,
      routineIcon: json['routine_icon'] ?? '',
      description: json['description'] ?? '',
      reminderTime: json['reminderTime'] != null 
          ? DateTime.tryParse(json['reminderTime']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'timing': timing,
      'isCompleted': isCompleted,
      'routineIcon': routineIcon,
      'description': description,
      'reminderTime': reminderTime?.toIso8601String(),
    };
  }

  /// Converts RoutineModel to domain entity
  Routine toEntity() {
    return Routine(
      id: id,
      name: name,
      timing: timing,
      isCompleted: isCompleted,
      routineIcon: routineIcon,
      description: description ?? '',
    );
  }

  /// Creates RoutineModel from domain entity
  factory RoutineModel.fromEntity(Routine routine) {
    return RoutineModel(
      id: routine.id,
      name: routine.name,
      timing: routine.timing,
      isCompleted: routine.isCompleted,
      routineIcon: routine.routineIcon,
      description: routine.description,
    );
  }
}
