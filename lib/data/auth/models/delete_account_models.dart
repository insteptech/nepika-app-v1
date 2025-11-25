import '../../../domain/auth/entities/delete_account_entities.dart';

/// Model for delete account reason from API response
class DeleteReasonModel extends DeleteReasonEntity {
  const DeleteReasonModel({
    required super.id,
    required super.reasonText,
    required super.description,
    required super.isActive,
  });

  factory DeleteReasonModel.fromJson(Map<String, dynamic> json) {
    return DeleteReasonModel(
      id: json['id'] as int,
      reasonText: json['reason_text'] as String,
      description: json['description'] as String,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reason_text': reasonText,
      'description': description,
      'is_active': isActive,
    };
  }
}

/// Model for delete account request to API
class DeleteAccountRequestModel extends DeleteAccountRequestEntity {
  const DeleteAccountRequestModel({
    required super.deleteReasonId,
    super.additionalComments,
  });

  factory DeleteAccountRequestModel.fromEntity(DeleteAccountRequestEntity entity) {
    return DeleteAccountRequestModel(
      deleteReasonId: entity.deleteReasonId,
      additionalComments: entity.additionalComments,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'delete_reason_id': deleteReasonId,
    };
    
    if (additionalComments != null && additionalComments!.isNotEmpty) {
      json['additional_comments'] = additionalComments;
    }
    
    return json;
  }
}

/// Model for delete account response from API
class DeleteAccountResponseModel extends DeleteAccountResponseEntity {
  const DeleteAccountResponseModel({
    required super.reasonId,
    required super.deleteReasonId,
    super.userId,
    super.fullName,
    super.reasonText,
    super.createdAt,
    super.additionalComments,
  });

  factory DeleteAccountResponseModel.fromJson(Map<String, dynamic> json) {
    return DeleteAccountResponseModel(
      reasonId: json['reason_id'] as String,
      deleteReasonId: json['delete_reason_id'] as int,
      userId: json['user_id'] as String?,
      fullName: json['full_name'] as String?,
      reasonText: json['reason_text'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      additionalComments: json['additional_comments'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'reason_id': reasonId,
      'delete_reason_id': deleteReasonId,
    };

    if (userId != null) map['user_id'] = userId;
    if (fullName != null) map['full_name'] = fullName;
    if (reasonText != null) map['reason_text'] = reasonText;
    if (createdAt != null) map['created_at'] = createdAt!.toIso8601String();
    if (additionalComments != null) map['additional_comments'] = additionalComments;

    return map;
  }
}