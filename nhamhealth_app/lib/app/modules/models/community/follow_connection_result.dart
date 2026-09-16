class FollowConnectionResult {
  const FollowConnectionResult({
    required this.id,
    required this.status,
    required this.relationshipStatus,
  });

  final int id;
  final String status;
  final String relationshipStatus;

  factory FollowConnectionResult.fromJson(Map<String, dynamic> json) =>
      FollowConnectionResult(
        id: (json['id'] as num?)?.toInt() ?? 0,
        status: '${json['status'] ?? ''}'.trim().toUpperCase(),
        relationshipStatus:
            '${json['relationshipStatus'] ?? 'NONE'}'.trim().toUpperCase(),
      );
}
