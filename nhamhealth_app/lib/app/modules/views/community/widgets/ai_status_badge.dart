import 'package:flutter/material.dart';

class AiStatusBadge extends StatelessWidget {
  const AiStatusBadge({required this.status, super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final value = status.toUpperCase();
    final (label, icon, color, background) = switch (value) {
      'APPROVED' => (
        'Added to Meals',
        Icons.check_circle_outline_rounded,
        const Color(0xFF078B40),
        const Color(0xFFE2F8E9),
      ),
      'INCOMPLETE' => (
        'Complete Recipe',
        Icons.warning_amber_rounded,
        const Color(0xFFA76100),
        const Color(0xFFFFF2D6),
      ),
      'NOT_SUITABLE' => (
        'Community only',
        Icons.info_outline_rounded,
        const Color(0xFF657069),
        const Color(0xFFEFF2F0),
      ),
      _ => (
        'AI checking...',
        Icons.auto_awesome_rounded,
        const Color(0xFF6260A8),
        const Color(0xFFF0EEFF),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
