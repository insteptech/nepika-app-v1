class RoutineModel {
  final String id;
  final String name;
  final String timing;
  final bool isCompleted;
  final String? description;
  final DateTime? reminderTime;

  RoutineModel({
    required this.id,
    required this.name,
    required this.timing,
    required this.isCompleted,
    this.description,
    this.reminderTime,
  });

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    return RoutineModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      timing: json['timing'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      description: json['description'],
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
      'description': description,
      'reminderTime': reminderTime?.toIso8601String(),
    };
  }
}
