class ApiHealth {
  const ApiHealth({
    required this.status,
    required this.service,
    required this.timestamp,
  });

  final String status;
  final String service;
  final DateTime timestamp;

  factory ApiHealth.fromJson(Map<String, dynamic> json) {
    return ApiHealth(
      status: json['status'] as String,
      service: json['service'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
