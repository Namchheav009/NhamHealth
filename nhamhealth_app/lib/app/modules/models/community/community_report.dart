import 'dart:typed_data';

enum CommunityReportStatus {
  pending,
  underReview,
  resolved,
  noViolation,
  rejected;

  factory CommunityReportStatus.fromApi(String value) => switch (value
      .toUpperCase()) {
    'UNDER_REVIEW' => underReview,
    'RESOLVED' => resolved,
    'NO_VIOLATION' || 'DISMISSED' => noViolation,
    'REJECTED' => rejected,
    _ => pending,
  };

  String get labelKey => switch (this) {
    pending => 'community.report_status_pending',
    underReview => 'community.report_status_review',
    resolved => 'community.report_status_resolved',
    noViolation => 'community.report_status_no_violation',
    rejected => 'community.report_status_closed',
  };
}

enum CommunityPostReportReason {
  spam('SPAM', 'community.report_reason_spam'),
  harassment('HARASSMENT', 'community.report_reason_harassment'),
  inappropriateContent(
    'INAPPROPRIATE_CONTENT',
    'community.report_reason_inappropriate',
  ),
  falseInformation('FALSE_INFORMATION', 'community.report_reason_false'),
  copyright('COPYRIGHT', 'community.report_reason_copyright'),
  other('OTHER', 'community.report_reason_other');

  const CommunityPostReportReason(this.apiValue, this.labelKey);
  final String apiValue;
  final String labelKey;

  factory CommunityPostReportReason.fromApi(String value) => values.firstWhere(
    (item) => item.apiValue == value.toUpperCase(),
    orElse: () => other,
  );
}

class CommunityReportAttachmentDraft {
  const CommunityReportAttachmentDraft({
    required this.bytes,
    required this.name,
  });
  final Uint8List bytes;
  final String name;
}

class CommunityReport {
  const CommunityReport({
    required this.id,
    required this.postId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.reviewedAt,
    this.description = '',
    this.adminMessage = '',
    this.postPreview = '',
    this.attachments = const [],
  });

  final int id;
  final int postId;
  final CommunityPostReportReason reason;
  final CommunityReportStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? reviewedAt;
  final String description;
  final String adminMessage;
  final String postPreview;
  final List<String> attachments;

  factory CommunityReport.fromJson(Map<String, dynamic> json) =>
      CommunityReport(
        id: (json['id'] as num?)?.toInt() ?? 0,
        postId: (json['targetId'] as num?)?.toInt() ?? 0,
        reason: CommunityPostReportReason.fromApi('${json['reason'] ?? ''}'),
        status: CommunityReportStatus.fromApi('${json['status'] ?? ''}'),
        createdAt:
            DateTime.tryParse('${json['createdAt'] ?? ''}')?.toLocal() ??
            DateTime.now(),
        updatedAt: DateTime.tryParse('${json['updatedAt'] ?? ''}')?.toLocal(),
        reviewedAt: DateTime.tryParse('${json['reviewedAt'] ?? ''}')?.toLocal(),
        description: '${json['description'] ?? ''}'.trim(),
        adminMessage: '${json['adminMessage'] ?? ''}'.trim(),
        postPreview: '${json['postPreview'] ?? ''}'.trim(),
        attachments: (json['attachments'] as List<dynamic>? ?? const [])
            .map((value) => '$value'.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false),
      );
}
