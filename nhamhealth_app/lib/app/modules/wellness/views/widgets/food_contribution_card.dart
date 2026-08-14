import 'package:flutter/material.dart';

class FoodContributionCard extends StatelessWidget {
  const FoodContributionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Contribution today',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 5),
              Icon(
                Icons.auto_awesome,
                color: Color(0xFF00A651),
                size: 15,
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.track_changes_rounded,
                color: Color(0xFFFF641E),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This drink added a lot of sugar with little fiber or protein.\n'
                  '• Main source of sugar today\n'
                  '• Pairs better with water or fruit',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}