import 'package:equatable/equatable.dart';

/// Entity representing a delete account reason
class DeleteReasonEntity extends Equatable {
  final int id;
  final String reasonText;
  final String description;
  final bool isActive;

  const DeleteReasonEntity({
    required this.id,
    required this.reasonText,
    required this.description,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, reasonText, description, isActive];
}

/// Entity representing a delete account request
class DeleteAccountRequestEntity extends Equatable {
  final int deleteReasonId;
  final String? additionalComments;

  const DeleteAccountRequestEntity({
    required this.deleteReasonId,
    this.additionalComments,
  });

  @override
  List<Object?> get props => [deleteReasonId, additionalComments];
}

/// Entity representing the response after account deletion
class DeleteAccountResponseEntity extends Equatable {
  final String reasonId;
  final int deleteReasonId;
  final String userId;
  final String fullName;
  final String reasonText;
  final DateTime createdAt;

  const DeleteAccountResponseEntity({
    required this.reasonId,
    required this.deleteReasonId,
    required this.userId,
    required this.fullName,
    required this.reasonText,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    reasonId,
    deleteReasonId,
    userId,
    fullName,
    reasonText,
    createdAt,
  ];
}