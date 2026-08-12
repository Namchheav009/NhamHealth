import 'package:flutter/material.dart';

enum NotificationKind { social, recommendation, wellness }

class NotificationItem {
  const NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.kind,
    this.isUnread = false,
    this.hasMessageBadge = false,
  });

  final String title;
  final String message;
  final String time;
  final NotificationKind kind;
  final bool isUnread;
  final bool hasMessageBadge;

  IconData get icon => switch (kind) {
    NotificationKind.social => Icons.person_rounded,
    NotificationKind.recommendation => Icons.auto_awesome_rounded,
    NotificationKind.wellness => Icons.water_drop_rounded,
  };
}
