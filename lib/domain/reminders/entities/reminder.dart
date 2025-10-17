import 'package:equatable/equatable.dart';

class Reminder extends Equatable {
  final String id;
  final String userId;
  final String reminderName;
  final String reminderTime;
  final String? reminderDays;
  final String? reminderType;
  final bool reminderEnabled;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Reminder({
    required this.id,
    required this.userId,
    required this.reminderName,
    required this.reminderTime,
    this.reminderDays,
    this.reminderType,
    required this.reminderEnabled,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        reminderName,
        reminderTime,
        reminderDays,
        reminderType,
        reminderEnabled,
        createdAt,
        updatedAt,
      ];
}