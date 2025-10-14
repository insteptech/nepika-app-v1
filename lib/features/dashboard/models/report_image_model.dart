/// Model for report images API response
class ReportImagesResponse {
  final bool success;
  final int totalCount;
  final List<ReportImage> reports;

  const ReportImagesResponse({
    required this.success,
    required this.totalCount,
    required this.reports,
  });

  factory ReportImagesResponse.fromJson(Map<String, dynamic> json) {
    final reportsData = json['reports'] as List<dynamic>? ?? [];
    final reports = reportsData
        .map((item) => ReportImage.fromJson(item as Map<String, dynamic>))
        .toList();

    return ReportImagesResponse(
      success: json['success'] as bool? ?? false,
      totalCount: json['total_count'] as int? ?? 0,
      reports: reports,
    );
  }
}

/// Model for individual report image
class ReportImage {
  final String id;
  final String imageUrl;
  final DateTime scanDate;

  const ReportImage({
    required this.id,
    required this.imageUrl,
    required this.scanDate,
  });

  factory ReportImage.fromJson(Map<String, dynamic> json) {
    return ReportImage(
      id: json['id'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      scanDate: DateTime.parse(json['scan_date'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'scan_date': scanDate.toIso8601String(),
    };
  }

  /// Get formatted date string
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(scanDate);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
