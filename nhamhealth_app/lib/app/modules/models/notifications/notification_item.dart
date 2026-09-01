import 'package:flutter/material.dart';

enum NotificationKind { social, recommendation, wellness, system }

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.kind,
    this.isUnread = false,
    this.hasMessageBadge = false,
    this.actorUserId,
    this.actorAvatarUrl = '',
    this.referenceType,
    this.referenceId,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String message;
  final String time;
  final NotificationKind kind;
  final bool isUnread;
  final bool hasMessageBadge;
  final int? actorUserId;
  final String actorAvatarUrl;
  final String? referenceType;
  final int? referenceId;
  final DateTime createdAt;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] as String? ?? '').toUpperCase();
    return NotificationItem(
      id: (json['id'] as num).toInt(),
      title: (json['title'] as String? ?? 'Notification').trim(),
      message: (json['message'] as String? ?? '').trim(),
      time: _relativeTime(
        DateTime.tryParse(json['createdAt'] as String? ?? ''),
      ),
      kind: switch (type) {
        'COMMUNITY' => NotificationKind.social,
        'HEALTH' || 'REMINDER' => NotificationKind.wellness,
        'MODERATION' => NotificationKind.system,
        _ => NotificationKind.recommendation,
      },
      isUnread: json['read'] != true,
      hasMessageBadge: type == 'COMMUNITY',
      actorUserId: (json['actorUserId'] as num?)?.toInt(),
      actorAvatarUrl: (json['actorAvatarUrl'] as String? ?? '').trim(),
      referenceType: (json['referenceType'] as String?)?.trim().toUpperCase(),
      referenceId: (json['referenceId'] as num?)?.toInt(),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
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
    actorUserId: actorUserId,
    actorAvatarUrl: actorAvatarUrl,
    referenceType: referenceType,
    referenceId: referenceId,
    createdAt: createdAt,
  );

  /// Moderation updates are sent by the Nham Health service, rather than the
  /// individual administrator who performed the audit action.
  String get displayTitle =>
      kind == NotificationKind.system ? 'Nham Health' : title;

  String get displayMessage {
    if (kind != NotificationKind.system ||
        title.trim().toLowerCase() == 'nham health') {
      return message;
    }
    return '$title — $message';
  }

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
    NotificationKind.system => Icons.verified_rounded,
  };
}
