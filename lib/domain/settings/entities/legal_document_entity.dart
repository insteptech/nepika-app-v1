class LegalDocumentEntity {
  final String id;
  final String type;
  final String title;
  final String content;
  final String? version;
  final DateTime createdAt;
  final DateTime updatedAt;

  LegalDocumentEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.version,
    required this.createdAt,
    required this.updatedAt,
  });
}
