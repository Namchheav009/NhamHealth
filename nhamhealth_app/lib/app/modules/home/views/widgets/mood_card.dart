import 'package:flutter/material.dart';

class MoodCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const MoodCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),
        width: 66,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFF1F3)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF6375)
                : const Color(0xFFF3F3F3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.03,
              ),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style:
                  const TextStyle(fontSize: 26),
            ),

            const SizedBox(height: 3),

            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: selected
                    ? const Color(0xFFFF5265)
                    : Colors.black54,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}