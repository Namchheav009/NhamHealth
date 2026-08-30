class CommunityReportReason {
  const CommunityReportReason({required this.id, required this.name});

  final int id;
  final String name;

  factory CommunityReportReason.fromJson(Map<String, dynamic> json) =>
      CommunityReportReason(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: '${json['name'] ?? ''}'.trim(),
      );
}
