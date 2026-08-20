import 'package:flutter/material.dart';

enum NotificationKind { social, recommendation, wellness }

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.kind,
    this.isUnread = false,
    this.hasMessageBadge = false,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String message;
  final String time;
  final NotificationKind kind;
  final bool isUnread;
  final bool hasMessageBadge;
  final DateTime createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] as String? ?? '').toUpperCase();
    return NotificationItem(
      id: (json['id'] as num).toInt(),
      title: (json['title'] as String? ?? 'Notification').trim(),
      message: (json['message'] as String? ?? '').trim(),
      time: _relativeTime(DateTime.tryParse(json['createdAt'] as String? ?? '')),
      kind: switch (type) {
        'COMMUNITY' => NotificationKind.social,
        'HEALTH' || 'REMINDER' => NotificationKind.wellness,
        _ => NotificationKind.recommendation,
      },
      isUnread: json['read'] != true,
      hasMessageBadge: type == 'COMMUNITY',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  NotificationItem copyWith({bool? isUnread}) => NotificationItem(
    id: id,
    title: title,
    message: message,
    time: time,
    kind: kind,
    isUnread: isUnread ?? this.isUnread,
    hasMessageBadge: hasMessageBadge,
    createdAt: createdAt,
  );

  static String _relativeTime(DateTime? value) {
    if (value == null) return '';
    final difference = DateTime.now().difference(value.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    return '${difference.inDays} days ago';
  }

  IconData get icon => switch (kind) {
    NotificationKind.social => Icons.person_rounded,
    NotificationKind.recommendation => Icons.auto_awesome_rounded,
    NotificationKind.wellness => Icons.water_drop_rounded,
  };
}
