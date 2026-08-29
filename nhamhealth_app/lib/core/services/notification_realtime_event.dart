class NotificationRealtimeEvent {
  const NotificationRealtimeEvent({
    required this.id,
    required this.title,
    required this.message,
    this.referenceType,
    this.referenceId,
  });

  final int? id;
  final String title;
  final String message;
  final String? referenceType;
  final int? referenceId;
}
