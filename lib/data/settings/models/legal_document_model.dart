import '../../../../domain/settings/entities/legal_document_entity.dart';

class LegalDocumentModel extends LegalDocumentEntity {
  LegalDocumentModel({
    required super.id,
    required super.type,
    required super.title,
    required super.content,
    super.version,
    required super.createdAt,
    required super.updatedAt,
  });

  factory LegalDocumentModel.fromJson(Map<String, dynamic> json) {
    return LegalDocumentModel(
      id: json['id'] ?? '',
      type: json['document_type'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      version: json['version'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }
}
